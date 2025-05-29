#include "installedservices.hpp"
#include "unsafeparamcheck.hpp"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QThread>
#include <QDebug>
#include <QMutex>

QMutex installedServicesMutex;

extern QString DK_VCU_USERNAME;
extern QString DK_ARCH;
extern QString DK_DOCKER_HUB_NAMESPACE;
extern QString DK_CONTAINER_ROOT;
extern QString DK_VIP;

QString DK_VIP_PWD;
QString DK_VIP_USER;
QString DK_VIP_IP;
QString DK_XIP_IP;

QString DK_INSTALLED_SERVICE_FOLDER = "";

CheckAppRunningThread::CheckAppRunningThread(ServicesAsync *parent)
{
    QString mpDataPath = DK_INSTALLED_SERVICE_FOLDER + "installedservices.json";

    m_serviceAsync = parent;
}

void CheckAppRunningThread::run()
{
    while(1) {
        if (isVipReachable()) {
            m_serviceAsync->m_is_vip_connected = true;
        }
        else {
            m_serviceAsync->m_is_vip_connected = false;
        }
        checkRunningAppSts();
    }
}

bool CheckAppRunningThread::isVipReachable() {
    if (DK_VIP == "true") {
        // Construct ping command - send 1 packet with timeout 1 second
        QString cmd = "ping -c 2 -W 1 " + DK_VIP_IP + " > /dev/null 2>&1";

        // system() returns 0 if the command succeeded (host reachable)
        int ret = system(cmd.toUtf8());;

        return (ret == 0);
    }
    else {
        return false;
    }
}

void CheckAppRunningThread::checkRunningAppSts()
{    
    QString appStsLog =  "/tmp/vservice_checkRunningServicesSts.log";
    QString cmd = "> " + appStsLog + "; docker ps > " + appStsLog;
    if (m_serviceAsync->m_is_vip_connected && m_serviceAsync->m_is_vip_service_installed) {
        cmd = "(> " + appStsLog + "; docker ps ; ";  
        cmd += "sshpass -p '" + DK_VIP_PWD + "' ssh -o StrictHostKeyChecking=no " + DK_VIP_USER + "@" + DK_VIP_IP + " 'docker ps' ) > ";
        cmd += appStsLog;
        // cmd += " & ";
    }
    system(cmd.toUtf8());

    // qDebug() << "checkRunningAppSts cmd: " << cmd;
    
    QThread::msleep(500);
    QFile logFile(appStsLog);
    if (!logFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qCritical() << "Failed to open log file: checkRunningServicesSts.log";
        return;
    }

    QTextStream in(&logFile);
    QString content = in.readAll();

    if (content.isEmpty()) {
        qCritical() << "Log file is empty or could not be read.";
        return;
    }

    int len = m_serviceAsync->installedServicesList.size();
    // qDebug() << __func__ << "@" << __LINE__ <<  " : installedServicesList len: " << len;
    for (int i = 0; i < len; i++) {
        if (!m_serviceAsync->installedServicesList[i].id.isEmpty()) {
            if (content.contains(m_serviceAsync->installedServicesList[i].id)) {
                // qDebug() << "App ID" << installedServicesList[i].appId << "is running.";
                m_serviceAsync->updateServicesRunningSts(m_serviceAsync->installedServicesList[i].id, true, i);
            } else {
                // qDebug() << "App ID" << installedServicesList[i].appId << "is not running.";
                m_serviceAsync->updateServicesRunningSts(m_serviceAsync->installedServicesList[i].id, false, i);
            }
        }        
    }
}

InstalledServicesCheckThread::InstalledServicesCheckThread(ServicesAsync *parent)
{
    QString mpDataPath = DK_INSTALLED_SERVICE_FOLDER + "installedservices.json";
    // qDebug() << __func__ << "@" << __LINE__ <<  " : mpDataPath: " << mpDataPath;

    m_serviceAsync = parent;
    m_filewatcher = new QFileSystemWatcher(this);

    if (m_filewatcher) {
        QString path = mpDataPath;
        qDebug() << __func__ << __LINE__ << " m_filewatcher : " << path;

        if (QFile::exists(path)) {
            m_filewatcher->addPath(path);
            connect(m_filewatcher, SIGNAL(fileChanged(QString)), m_serviceAsync, SLOT(fileChanged(QString)));
        }
    }
}

void InstalledServicesCheckThread::triggerCheckAppStart(QString id, QString name)
{
    m_appId = id;
    m_appName = name;
    m_istriggeredAppStart = true;
}

void InstalledServicesCheckThread::run()
{
    QString dockerps = DK_INSTALLED_SERVICE_FOLDER + "listservicescmd.log";
    QString cmd = "";     

    while(1) {
        if (m_istriggeredAppStart && !m_appId.isEmpty() && !m_appName.isEmpty()) {
            QThread::msleep(5000); // workaround: wait 2s for the app to start. TODO: consider to check if the start time is more than 2s
            cmd = "docker ps > " + dockerps;
            if (m_serviceAsync->m_is_vip_connected && m_serviceAsync->m_is_vip_service_installed) {
                cmd = "(docker ps ; ";
                cmd += "sshpass -p '" + DK_VIP_PWD + "' ssh -o StrictHostKeyChecking=no " + DK_VIP_USER + "@" + DK_VIP_IP + " 'docker ps' ) > ";
                cmd += dockerps;
            }
            system(cmd.toUtf8()); 
            QThread::msleep(10);
            QFile MyFile(dockerps);
            MyFile.open(QIODevice::ReadWrite);
            QTextStream in (&MyFile);
            QString raw = in.readAll();
            qDebug() << "reprint docker ps: \n" << raw;
            if (raw.contains(m_appId, Qt::CaseSensitivity::CaseSensitive)) {
                Q_EMIT resultReady(m_appId, true, "<b>"+m_appName+"</b>" + " is started successfully.");
            }
            else {
                Q_EMIT resultReady(m_appId, false, "<b>"+m_appName+"</b>" + " is NOT started successfully.<br><br>Please contact the car OEM for more information !!!");
            }
            cmd = "> " + dockerps;
            system(cmd.toUtf8()); 

            m_istriggeredAppStart = false;
            m_appId.clear();
            m_appName.clear();
        }

        QThread::msleep(100);
    }
}

ServicesAsync::ServicesAsync()
{
    if(DK_CONTAINER_ROOT.isEmpty()) {
        DK_CONTAINER_ROOT = qgetenv("DK_CONTAINER_ROOT");
    }

    DK_VIP = qgetenv("DK_VIP");
    
    DK_INSTALLED_SERVICE_FOLDER = DK_CONTAINER_ROOT + "dk_installedservices/";
    qDebug() << __func__ << "@" << __LINE__ <<  " : DK_INSTALLED_SERVICE_FOLDER: " << DK_INSTALLED_SERVICE_FOLDER;

    parseSystemCfg();

    m_workerThread = new InstalledServicesCheckThread(this);
    connect(m_workerThread, &InstalledServicesCheckThread::resultReady, this, &ServicesAsync::handleResults);
    connect(m_workerThread, &InstalledServicesCheckThread::finished, m_workerThread, &QObject::deleteLater);
    m_workerThread->start();

    m_checkAppRunningThread = new CheckAppRunningThread(this);
    m_checkAppRunningThread->start();
}

void ServicesAsync::parseSystemCfg()
{
    QString path = DK_CONTAINER_ROOT + "dk_manager/dk_system_cfg.json";
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Cannot open file:" << path;
        return;
    }

    QByteArray jsonData = file.readAll();
    file.close();

    // Parse JSON
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(jsonData, &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "JSON parse error:" << parseError.errorString();
        return;
    }

    if (!doc.isObject()) {
        qWarning() << "JSON is not an object";
        return;
    }

    QJsonObject rootObj = doc.object();

    // Parse "xip" object
    if (rootObj.contains("xip") && rootObj["xip"].isObject()) {
        QJsonObject xipObj = rootObj["xip"].toObject();
        DK_XIP_IP = xipObj.value("ip").toString();
    }
    qDebug() << "DK_XIP_IP: " << DK_XIP_IP;

    // Parse "vip" object
    if (rootObj.contains("vip") && rootObj["vip"].isObject()) {
        QJsonObject vipObj = rootObj["vip"].toObject();
        DK_VIP_IP = vipObj.value("ip").toString();
        DK_VIP_USER = vipObj.value("user").toString();
        DK_VIP_PWD = vipObj.value("pwd").toString();
    }
    qDebug() << "DK_VIP_IP: " << DK_VIP_IP;
    qDebug() << "DK_VIP_USER: " << DK_VIP_USER;
    qDebug() << "DK_VIP_PWD: " << DK_VIP_PWD;
}

Q_INVOKABLE void ServicesAsync::openAppEditor(int idx)
{
    qDebug() << __func__ << __LINE__ << " index = " << idx;

    if (idx >= installedServicesList.size()) {
        qDebug() << "index out of range";
        return;
    }

    QString thisServiceFolder = DK_INSTALLED_SERVICE_FOLDER + installedServicesList[idx].id;
    QString vsCodeUserDataFolder = DK_INSTALLED_SERVICE_FOLDER + "/vscode_user_data";
    QString cmd;
    cmd = "mkdir -p " + vsCodeUserDataFolder + ";";
    cmd += "code " + thisServiceFolder + " --no-sandbox --user-data-dir=" + vsCodeUserDataFolder + ";";
    qDebug() << cmd;
    system(cmd.toUtf8());
}

Q_INVOKABLE void ServicesAsync::initInstalledServicesFromDB()
{
    installedServicesMutex.lock();
    m_is_vip_service_installed = false;

    clearServicesListView();
    installedServicesList.clear();

    QString mpDataPath = DK_INSTALLED_SERVICE_FOLDER + "installedservices.json";
    qDebug() << __func__ << "@" << __LINE__ <<  " : mpDataPath: " << mpDataPath;

    // Read the JSON file
    QFile file(mpDataPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "Failed to open file.";
        return;
    }

    QByteArray jsonData = file.readAll();
    file.close();

    // Parse the JSON data
    QJsonDocument document = QJsonDocument::fromJson(jsonData);
    if (document.isNull() || !document.isArray()) {
        qDebug() << __func__ << "@" << __LINE__ << ": Invalid JSON format.\n" << jsonData;
        return;
    }

    QJsonArray jsonArray = document.array();

    // Loop through each item in the array
    for (const QJsonValue &value : jsonArray) {
        if (!value.isObject()) {
            continue;
        }

        QJsonObject jsonObject = value.toObject();
        ServicesListStruct appInfo;

        // Extract relevant fields for ServicesListStruct
        appInfo.id = jsonObject["_id"].toString();
        appInfo.category = jsonObject["category"].toString();        

        // Extract relevant fields for ServicesListStruct
        appInfo.name = jsonObject["name"].toString();

        // Extract author from 'createdBy' object
        // QJsonObject createdBy = jsonObject["createdBy"].toObject();
        // if (createdBy.contains("descriptor")) {
        //     QJsonDocument descriptorDoc = QJsonDocument::fromJson(createdBy["descriptor"].toString().toUtf8());
        //     QJsonObject descriptorObj = descriptorDoc.object();
        //     appInfo.author = descriptorObj["name"].toString();
        // } else if (createdBy.contains("fullName")) {
        //     appInfo.author = createdBy["fullName"].toString();
        // } else {
        //     appInfo.author = "Unknown";
        // }
        
        QJsonObject storeId = jsonObject["storeId"].toObject();
        if (storeId.contains("name")) {
            appInfo.author = storeId["name"].toString();
        } 
        else {
            appInfo.author = "Unknown";
        }

        // Extract rating (if it exists)
        appInfo.rating = jsonObject["rating"].isNull() ? "**" : QString::number(jsonObject["rating"].toDouble());

        // Extract number of downloads
        appInfo.noofdownload = QString::number(jsonObject["downloads"].toInt());

        // Extract thumbnail for iconPath
        appInfo.iconPath = jsonObject["thumbnail"].toString();

        // Use the name as the folder name
        appInfo.foldername = appInfo.id;

        // Extract dashboardConfig or default to empty
        // appInfo.packagelink = jsonObject["dashboardConfig"].toString().isEmpty() ? "N/A" : jsonObject["dashboardConfig"].toString();
        // Extract and parse dashboardConfig
        QString dashboardConfigStr = jsonObject["dashboardConfig"].toString();
        if (!dashboardConfigStr.isEmpty()) {
            QJsonDocument dashboardDoc = QJsonDocument::fromJson(dashboardConfigStr.toUtf8());
            QJsonObject dashboardObj = dashboardDoc.object();
    
            if (dashboardObj.contains("DockerImageURL")) {
                appInfo.packagelink = dashboardObj["DockerImageURL"].toString();
            } else {
                appInfo.packagelink = "N/A";
            }

            if (dashboardObj.contains("Target")) {
                appInfo.deploytarget = dashboardObj["Target"].toString();
            } else {
                appInfo.deploytarget = "xip";
            }
            if (appInfo.deploytarget == "vip") {
                m_is_vip_service_installed = true;
            }

        } else {
            appInfo.packagelink = "N/A";
        }

        // For this example, assume all apps are not installed
        appInfo.isInstalled = false;
        appInfo.isSubscribed = false;

        installedServicesList.append(appInfo);
    }
    qDebug() << "Services list loaded, total apps found:" << installedServicesList.size();

    if (installedServicesList.size()) {
        for(int i = 0; i < installedServicesList.size(); i++) {
            appendServicesInfoToServicesList(installedServicesList[i].name, installedServicesList[i].author,
                                   installedServicesList[i].rating, installedServicesList[i].noofdownload,
                                   installedServicesList[i].iconPath,
                                   installedServicesList[i].isInstalled,
                                   installedServicesList[i].id,
                                   installedServicesList[i].isSubscribed);
        }
    }

    installedServicesMutex.unlock();
}

Q_INVOKABLE void ServicesAsync::executeServices(int appIdx, const QString name, const QString appId, bool isSubscribed)
{
    QString dockerps = DK_INSTALLED_SERVICE_FOLDER + "listservicescmd.log";
    QString cmd = "";

    if (isSubscribed) {
        cmd = "";

        QString dbc_default_path_mount = " -v /home/" + DK_VCU_USERNAME + "/.dk/dk_manager/vssmapping/dbc_default_values.json:/app/vss/dbc_default_values.json:ro ";
        QString dbc_vss_mount = " -v /home/" + DK_VCU_USERNAME + "/.dk/dk_vssgeneration/vss.json:/app/vss/vss.json:ro ";
        
        QString runtimecfgfile = DK_INSTALLED_SERVICE_FOLDER + appId + "/runtimecfg.json";
        QString safeParams = getSafeDockerParam(runtimecfgfile);
        QString audioParams = getAudioParam(runtimecfgfile);

        if (installedServicesList[appIdx].deploytarget == "vip") {
            if (m_is_vip_connected) {
                // "sshpass -p {DK_VIP_PWD} ssh -o StrictHostKeyChecking=no {DK_VIP_USER}@{DK_VIP_IP} 'docker pull {DK_XIP_IP}:5000/{DockerImageURL}'"
                // docker kill dk_vrte ; docker rm dk_vrte ; docker run  --name dk_vrte --network host --privileged -it phongbosch/dk_vrte:latest
                // start service
                cmd += "sshpass -p '" + DK_VIP_PWD + "' ssh -o StrictHostKeyChecking=no " + DK_VIP_USER + "@" + DK_VIP_IP + " 'docker kill " + appId +  ";docker rm " + appId + ";docker run -d -it --name " + appId + " --log-opt max-size=10m --log-opt max-file=3 --network host  --privileged -v /home/.dk/dk_fota:/home/.dk/dk_fota:ro -v /home/.dk/dk_vss:/home/.dk/dk_vss:ro -v /home/.dk/dk_installedservices/" +     appId + ":/app/runtime " + DK_XIP_IP + ":5000/" + installedServicesList[appIdx].packagelink + " '";
                qDebug() << cmd;
                system(cmd.toUtf8());
            }
            else {
                qDebug() << "VIP is not connected. Cannot start the service.";
            }
        }
        else {
            // start service
            cmd += "docker kill " + appId + ";docker rm " + appId + ";docker run -d -it --name " + appId + " --log-opt max-size=10m --log-opt max-file=3    -v /home/" + DK_VCU_USERNAME + "/.dk/dk_installedservices/" + appId + ":/app/runtime --network host " + dbc_default_path_mount + dbc_vss_mount     + safeParams + audioParams + installedServicesList[appIdx].packagelink;
            qDebug() << cmd;
            system(cmd.toUtf8());
        }

        if (m_workerThread) {
            m_workerThread->triggerCheckAppStart(appId, name);
        }
    }
    else {
        cmd = "docker kill " + appId + " &";
        if (installedServicesList[appIdx].deploytarget == "vip") {
            cmd = "sshpass -p '" + DK_VIP_PWD + "' ssh -o StrictHostKeyChecking=no " + DK_VIP_USER + "@" + DK_VIP_IP + " 'docker kill " + appId + " '";
        }
        qDebug() << cmd;
        system(cmd.toUtf8());
    }
}

void readServicesList(const QString searchName, QList<ServicesListStruct> &ServicesListInfo) {
    QString mpDataPath = DK_INSTALLED_SERVICE_FOLDER + "installedservices.json";

    // Read the JSON file
    QFile file(mpDataPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "Failed to open file.";
        return;
    }

    QByteArray jsonData = file.readAll();
    file.close();

    // Parse the JSON data
    QJsonDocument document = QJsonDocument::fromJson(jsonData);
    if (document.isNull() || !document.isArray()) {
        qDebug() << __func__ << "@" << __LINE__ << ": Invalid JSON format.";
        return;
    }

    QJsonArray jsonArray = document.array();

    // Loop through each item in the array
    for (const QJsonValue &value : jsonArray) {
        if (!value.isObject()) {
            continue;
        }

        QJsonObject jsonObject = value.toObject();
        ServicesListStruct appInfo;

        // Extract relevant fields for ServicesListStruct
        appInfo.id = jsonObject["_id"].toString();
        appInfo.category = jsonObject["category"].toString();        

        // Extract relevant fields for ServicesListStruct
        appInfo.name = jsonObject["name"].toString();

        // Extract author from 'createdBy' object
        QJsonObject createdBy = jsonObject["createdBy"].toObject();
        if (createdBy.contains("descriptor")) {
            QJsonDocument descriptorDoc = QJsonDocument::fromJson(createdBy["descriptor"].toString().toUtf8());
            QJsonObject descriptorObj = descriptorDoc.object();
            appInfo.author = descriptorObj["name"].toString();
        } else if (createdBy.contains("fullName")) {
            appInfo.author = createdBy["fullName"].toString();
        } else {
            appInfo.author = "Unknown";
        }

        // Extract rating (if it exists)
        appInfo.rating = jsonObject["rating"].isNull() ? "**" : QString::number(jsonObject["rating"].toDouble());

        // Extract number of downloads
        appInfo.noofdownload = QString::number(jsonObject["downloads"].toInt());

        // Extract thumbnail for iconPath
        appInfo.iconPath = jsonObject["thumbnail"].toString();

        // Use the name as the folder name
        appInfo.foldername = appInfo.id;

        // Extract dashboardConfig or default to empty
        appInfo.packagelink = jsonObject["dashboardConfig"].toString().isEmpty() ? "N/A" : jsonObject["dashboardConfig"].toString();

        // For this example, assume all apps are not installed
        appInfo.isInstalled = false;

        // Only add to the list if the name contains the searchName
        if (appInfo.category.contains(searchName, Qt::CaseInsensitive)) {
            ServicesListInfo.append(appInfo);
        }
    }

    qDebug() << "Services list loaded, total apps found:" << ServicesListInfo.size();
}

void ServicesAsync::removeObjectById(const QString &filePath, const QString &idToRemove) {
    // Open the JSON file
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open file for reading:" << filePath;
        return;
    }

    // Read the file content and close the file
    QByteArray jsonData = file.readAll();
    file.close();

    // Parse the JSON document
    QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonData);
    if (jsonDoc.isNull() || !jsonDoc.isArray()) {
        qWarning() << "Invalid JSON format.";
        return;
    }

    // Convert the JSON document to an array
    QJsonArray jsonArray = jsonDoc.array();

    // Iterate through the array and find the object with the given _id
    for (int i = 0; i < jsonArray.size(); ++i) {
        QJsonObject obj = jsonArray[i].toObject();
        if (obj.contains("_id") && obj["_id"].toString() == idToRemove) {
            // Remove the object from the array
            jsonArray.removeAt(i);
            qDebug() << "Object with _id:" << idToRemove << "removed.";
            break;
        }
    }

    // Create a new JSON document with the modified array
    QJsonDocument updatedJsonDoc(jsonArray);

    // Open the file again for writing
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        qWarning() << "Failed to open file for writing:" << filePath;
        return;
    }

    // Write the updated JSON data to the file
    file.write(updatedJsonDoc.toJson(QJsonDocument::Indented));
    file.close();
    qDebug() << "Updated JSON file saved.";
}

Q_INVOKABLE void ServicesAsync::removeServices(const int index)
{
    qDebug() << __func__ << "@" << __LINE__ <<  " : index: " << index;
    // refresh install app view
    //initInstalledServicesFromDB();
    QString mpDataPath = DK_INSTALLED_SERVICE_FOLDER + "installedservices.json";
    removeObjectById(mpDataPath, installedServicesList[index].id);

    QString cmd;
    QString appId = installedServicesList[index].id;
    // delete service
    if (installedServicesList[index].deploytarget == "vip") {
        cmd = "sshpass -p '" + DK_VIP_PWD + "' ssh -o StrictHostKeyChecking=no " + DK_VIP_USER + "@" + DK_VIP_IP + " 'docker kill " + appId + ";docker rm " + appId + "'";
        qDebug() << cmd;
        system(cmd.toUtf8());
    }
    else {
        cmd = "docker kill " + appId + ";docker rm " + appId;
        qDebug() << cmd;
        system(cmd.toUtf8());
    }
}

void ServicesAsync::handleResults(QString appId, bool isStarted, QString msg)
{
    updateStartAppMsg(appId, isStarted, msg);
    if (isStarted) {
        int len = installedServicesList.size();
        for (int i = 0; i < len; i++) {
            if (installedServicesList[i].id == appId) {
                installedServicesList[i].isSubscribed = true;
                return;
            }
        }
    }
}

void ServicesAsync::fileChanged(const QString &path)
{
    qDebug() << __func__ << "@" << __LINE__ <<  " : path: " << path;
    QThread::msleep(1000);
    initInstalledServicesFromDB();
}
