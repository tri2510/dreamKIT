#include "installedservices.hpp"
#include "unsafeparamcheck.hpp"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QThread>
#include <QDebug>
#include <QMutex>
#include <QDateTime>
#include <QTimer>
#include <QProcess>
#include <QDir>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(servicesLog, "dk.ivi.services")

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
    // Check if running in embedded/mock mode
    QString embeddedMode = qgetenv("DK_EMBEDDED_MODE");
    QString mockMode = qgetenv("DK_MOCK_MODE");
    
    if (embeddedMode == "1" || mockMode == "1") {
        // In embedded mode, just set mock values and exit
        m_serviceAsync->m_is_vip_connected = false;
        // Don't run the continuous checking loop in embedded mode
        qDebug() << "CheckAppRunningThread: Running in embedded mode, skipping continuous checks";
        return;
    }
    
    while(1) {
        if (isVipReachable()) {
            m_serviceAsync->m_is_vip_connected = true;
        }
        else {
            m_serviceAsync->m_is_vip_connected = false;
        }
        checkRunningAppSts();
        
        // Add longer sleep to reduce CPU usage
        QThread::msleep(5000); // Sleep 5 seconds between checks
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
    // Check if running in embedded/mock mode
    QString embeddedMode = qgetenv("DK_EMBEDDED_MODE");
    QString mockMode = qgetenv("DK_MOCK_MODE");
    
    if (embeddedMode == "1" || mockMode == "1") {
        // In embedded mode, set mock running status for all services
        int len = m_serviceAsync->installedServicesList.size();
        for (int i = 0; i < len; i++) {
            if (!m_serviceAsync->installedServicesList[i].id.isEmpty()) {
                // Mock: Set first service as running, others as stopped
                bool isRunning = (i == 0);
                m_serviceAsync->updateServicesRunningSts(m_serviceAsync->installedServicesList[i].id, isRunning, i);
            }
        }
        return;
    }
    
    QString appStsLog =  "/tmp/vservice_checkRunningServicesSts.log";
    QString cmd = "> " + appStsLog + "; docker ps > " + appStsLog;
    if (m_serviceAsync->m_is_vip_connected && m_serviceAsync->m_is_vip_service_installed) {
        cmd = "(> " + appStsLog + "; docker ps ; ";  
        cmd += "sshpass -p '" + DK_VIP_PWD + "' ssh -o StrictHostKeyChecking=no " + DK_VIP_USER + "@" + DK_VIP_IP + " 'docker ps' ) > ";
        cmd += appStsLog;
        // cmd += " & ";
    }
    int result = system(cmd.toUtf8());
    (void)result; // Suppress unused variable warning

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
            int result = system(cmd.toUtf8());
    (void)result; // Suppress unused variable warning 
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
            result = system(cmd.toUtf8());
    (void)result; // Suppress unused variable warning 

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
    int result = system(cmd.toUtf8());
    (void)result; // Suppress unused variable warning
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
        // Look up Docker image info from marketplace data
        QString marketplaceFile = DK_CONTAINER_ROOT + "dk_marketplace/" + appInfo.id + "_installcfg.json";
        qDebug() << "Looking for marketplace config:" << marketplaceFile;
        
        QFile marketFile(marketplaceFile);
        if (marketFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QByteArray marketData = marketFile.readAll();
            marketFile.close();
            
            QJsonDocument marketDoc = QJsonDocument::fromJson(marketData);
            if (!marketDoc.isNull() && marketDoc.isObject()) {
                QJsonObject marketObj = marketDoc.object();
                QString dashboardConfigStr = marketObj["dashboardConfig"].toString();
                
                if (!dashboardConfigStr.isEmpty()) {
                    QJsonDocument dashboardDoc = QJsonDocument::fromJson(dashboardConfigStr.toUtf8());
                    QJsonObject dashboardObj = dashboardDoc.object();
            
                    if (dashboardObj.contains("DockerImageURL")) {
                        appInfo.packagelink = dashboardObj["DockerImageURL"].toString();
                        qDebug() << "Found Docker image for" << appInfo.name << ":" << appInfo.packagelink;
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
                    
                    // Extract and write RuntimeCfg to service directory
                    if (dashboardObj.contains("RuntimeCfg")) {
                        QJsonObject runtimeCfg = dashboardObj["RuntimeCfg"].toObject();
                        QString serviceDir = DK_INSTALLED_SERVICE_FOLDER + appInfo.id;
                        QString runtimeCfgPath = serviceDir + "/runtimecfg.json";
                        
                        // Ensure service directory exists
                        QDir().mkpath(serviceDir);
                        
                        // Write runtime config to file
                        QFile runtimeFile(runtimeCfgPath);
                        if (runtimeFile.open(QIODevice::WriteOnly)) {
                            QJsonDocument runtimeDoc(runtimeCfg);
                            runtimeFile.write(runtimeDoc.toJson(QJsonDocument::Compact));
                            runtimeFile.close();
                            qDebug() << "Updated runtime config for" << appInfo.name << ":" << runtimeDoc.toJson(QJsonDocument::Compact);
                        } else {
                            qWarning() << "Failed to write runtime config for" << appInfo.name;
                        }
                    }
                } else {
                    appInfo.packagelink = "N/A";
                }
            } else {
                qWarning() << "Failed to parse marketplace JSON for" << appInfo.id;
                appInfo.packagelink = "N/A";
            }
        } else {
            qWarning() << "No marketplace config found for" << appInfo.id;
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

void ServicesAsync::handleEmbeddedServiceToggle(int appIdx, const QString name, const QString appId, bool isSubscribed)
{
    qCInfo(servicesLog) << "=== SERVICE TOGGLE START ===";
    qCInfo(servicesLog) << "Service:" << name;
    qCInfo(servicesLog) << "App ID:" << appId;
    qCInfo(servicesLog) << "App Index:" << appIdx;
    qCInfo(servicesLog) << "Action:" << (isSubscribed ? "START" : "STOP");
    qCInfo(servicesLog) << "Total services in list:" << installedServicesList.size();
    
    if (isSubscribed) {
        // Starting service in embedded mode
        qCInfo(servicesLog) << "🚀 STARTING SERVICE:" << name;
        
        // Create a service status file to track running state
        QString serviceFolder = DK_INSTALLED_SERVICE_FOLDER + appId;
        QString statusFile = serviceFolder + "/service_status.json";
        
        qCInfo(servicesLog) << "Service folder:" << serviceFolder;
        qCInfo(servicesLog) << "Status file:" << statusFile;
        
        QJsonObject statusInfo;
        statusInfo["service_id"] = appId;
        statusInfo["service_name"] = name;
        statusInfo["status"] = "running";
        statusInfo["started_timestamp"] = QDateTime::currentSecsSinceEpoch();
        statusInfo["mode"] = "embedded";
        
        // Create directory if it doesn't exist
        qCInfo(servicesLog) << "Creating service directory...";
        QDir().mkpath(serviceFolder);
        
        // Write status file
        QFile file(statusFile);
        if (file.open(QIODevice::WriteOnly)) {
            QJsonDocument doc(statusInfo);
            file.write(doc.toJson());
            file.close();
            qCInfo(servicesLog) << "✅ Created service status file successfully";
        } else {
            qCCritical(servicesLog) << "❌ Failed to create service status file:" << file.errorString();
        }
        
        // Start the embedded service simulation
        QString embeddedServiceScript = "/home/" + DK_VCU_USERNAME + "/01_SDV/10_dreamkit_v2/dreamKIT/dreamos-core/dk-ivi-lite/scripts/run_embedded_service.sh";
        QString cmd = embeddedServiceScript + " start " + appId + " \"" + name + "\"";
        qCInfo(servicesLog) << "Executing service start command:" << cmd;
        
        // Use QProcess for better control and non-blocking execution
        QProcess *process = new QProcess(this);
        
        // Connect to process signals for detailed logging
        connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                this, [this, appId, name](int exitCode, QProcess::ExitStatus exitStatus) {
            qCInfo(servicesLog) << "Service start process finished for" << name;
            qCInfo(servicesLog) << "Exit code:" << exitCode;
            qCInfo(servicesLog) << "Exit status:" << (exitStatus == QProcess::NormalExit ? "Normal" : "Crashed");
        });
        
        connect(process, &QProcess::started, this, [this, appId, name]() {
            qCInfo(servicesLog) << "✅ Service start process launched successfully for" << name;
        });
        
        connect(process, &QProcess::errorOccurred, this, [this, appId, name](QProcess::ProcessError error) {
            qCCritical(servicesLog) << "❌ Service start process error for" << name << ":" << error;
        });
        
        process->setProgram("/bin/bash");
        process->setArguments({"-c", cmd});
        process->start();
        
        // Update service status immediately
        if (appIdx < installedServicesList.size()) {
            qCInfo(servicesLog) << "Updating service list status - index" << appIdx << "to SUBSCRIBED";
            installedServicesList[appIdx].isSubscribed = true;
            qCInfo(servicesLog) << "Calling updateServicesRunningSts for UI update";
            updateServicesRunningSts(appId, true, appIdx);
        } else {
            qCCritical(servicesLog) << "❌ App index" << appIdx << "out of range! Cannot update service status.";
        }
        
        // Simulate service start success after a short delay
        qCInfo(servicesLog) << "Setting up success timer for 2 seconds...";
        QTimer::singleShot(2000, this, [this, appId, name]() {
            qCInfo(servicesLog) << "🎉 Service start timer triggered - calling handleResults";
            handleResults(appId, true, "<b>" + name + "</b> started successfully in embedded mode.");
        });
        
    } else {
        // Stopping service in embedded mode
        qCInfo(servicesLog) << "🛑 STOPPING SERVICE:" << name;
        
        // Remove service status file
        QString serviceFolder = DK_INSTALLED_SERVICE_FOLDER + appId;
        QString statusFile = serviceFolder + "/service_status.json";
        
        qCInfo(servicesLog) << "Service folder:" << serviceFolder;
        qCInfo(servicesLog) << "Status file:" << statusFile;
        
        if (QFile::exists(statusFile)) {
            if (QFile::remove(statusFile)) {
                qCInfo(servicesLog) << "✅ Removed service status file successfully";
            } else {
                qCWarning(servicesLog) << "⚠️ Failed to remove service status file";
            }
        } else {
            qCInfo(servicesLog) << "Status file doesn't exist (service may not have been running)";
        }
        
        // Stop the embedded service
        QString embeddedServiceScript = "/home/" + DK_VCU_USERNAME + "/01_SDV/10_dreamkit_v2/dreamKIT/dreamos-core/dk-ivi-lite/scripts/run_embedded_service.sh";
        QString cmd = embeddedServiceScript + " stop " + appId + " \"" + name + "\"";
        qCInfo(servicesLog) << "Executing service stop command:" << cmd;
        
        // Use QProcess for better control
        QProcess *process = new QProcess(this);
        
        // Connect to process signals for detailed logging
        connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                this, [this, appId, name](int exitCode, QProcess::ExitStatus exitStatus) {
            qCInfo(servicesLog) << "Service stop process finished for" << name;
            qCInfo(servicesLog) << "Exit code:" << exitCode;
            qCInfo(servicesLog) << "Exit status:" << (exitStatus == QProcess::NormalExit ? "Normal" : "Crashed");
        });
        
        connect(process, &QProcess::started, this, [this, appId, name]() {
            qCInfo(servicesLog) << "✅ Service stop process launched successfully for" << name;
        });
        
        connect(process, &QProcess::errorOccurred, this, [this, appId, name](QProcess::ProcessError error) {
            qCCritical(servicesLog) << "❌ Service stop process error for" << name << ":" << error;
        });
        
        process->setProgram("/bin/bash");
        process->setArguments({"-c", cmd});
        process->start();
        
        // Update service status immediately
        if (appIdx < installedServicesList.size()) {
            qCInfo(servicesLog) << "Updating service list status - index" << appIdx << "to UNSUBSCRIBED";
            installedServicesList[appIdx].isSubscribed = false;
            qCInfo(servicesLog) << "Calling updateServicesRunningSts for UI update";
            updateServicesRunningSts(appId, false, appIdx);
        } else {
            qCCritical(servicesLog) << "❌ App index" << appIdx << "out of range! Cannot update service status.";
        }
        
        // Simulate service stop success
        qCInfo(servicesLog) << "Setting up success timer for 1 second...";
        QTimer::singleShot(1000, this, [this, appId, name]() {
            qCInfo(servicesLog) << "🎉 Service stop timer triggered - calling handleResults";
            handleResults(appId, false, "<b>" + name + "</b> stopped successfully in embedded mode.");
        });
    }
    
    qCInfo(servicesLog) << "=== SERVICE TOGGLE PROCESSING COMPLETE ===";
}

Q_INVOKABLE void ServicesAsync::executeServices(int appIdx, const QString name, const QString appId, bool isSubscribed)
{
    qCInfo(servicesLog) << "==== EXECUTE SERVICES CALLED ====";
    qCInfo(servicesLog) << "Parameters:";
    qCInfo(servicesLog) << "  App Index:" << appIdx;
    qCInfo(servicesLog) << "  Service Name:" << name;
    qCInfo(servicesLog) << "  App ID:" << appId;
    qCInfo(servicesLog) << "  Is Subscribed (turning ON):" << isSubscribed;
    
    // Check if running in embedded/mock mode
    QString embeddedMode = qgetenv("DK_EMBEDDED_MODE");
    QString mockMode = qgetenv("DK_MOCK_MODE");
    
    qCInfo(servicesLog) << "Environment check:";
    qCInfo(servicesLog) << "  DK_EMBEDDED_MODE:" << embeddedMode;
    qCInfo(servicesLog) << "  DK_MOCK_MODE:" << mockMode;
    
    qCInfo(servicesLog) << "🐳 USING DOCKER MODE - Starting user-defined Docker containers";
    qCInfo(servicesLog) << "Checking service configuration for Docker image...";
    qCInfo(servicesLog) << "Service package link:" << installedServicesList[appIdx].packagelink;
    qCInfo(servicesLog) << "Deploy target:" << installedServicesList[appIdx].deploytarget;
    
    QString dockerps = DK_INSTALLED_SERVICE_FOLDER + "listservicescmd.log";
    QString cmd = "";

    if (isSubscribed) {
        cmd = "";

        QString dbc_default_path_mount = " -v /home/" + DK_VCU_USERNAME + "/.dk/dk_manager/vssmapping/dbc_default_values.json:/app/vss/dbc_default_values.json:ro ";
        QString dbc_vss_mount = " -v /home/" + DK_VCU_USERNAME + "/.dk/dk_vssgeneration/vss.json:/app/vss/vss.json:ro ";
        
        QString runtimecfgfile = DK_INSTALLED_SERVICE_FOLDER + appId + "/runtimecfg.json";
        qCInfo(servicesLog) << "📋 Runtime config file:" << runtimecfgfile;
        
        // Check if runtime config exists and is valid
        QFile runtimeFile(runtimecfgfile);
        if (runtimeFile.open(QIODevice::ReadOnly)) {
            QByteArray runtimeData = runtimeFile.readAll();
            runtimeFile.close();
            qCInfo(servicesLog) << "📋 Runtime config content:" << runtimeData;
            
            if (runtimeData.trimmed() == "{}") {
                qCWarning(servicesLog) << "⚠️  Runtime config is empty! Service may fail to start properly.";
                qCWarning(servicesLog) << "⚠️  Expected configuration like: {\"can_channel\": \"can1\"}";
            }
        }
        
        QString safeParams = getSafeDockerParam(runtimecfgfile);
        QString audioParams = getAudioParam(runtimecfgfile);
        int result;

        if (installedServicesList[appIdx].deploytarget == "vip") {
            if (m_is_vip_connected) {
                // "sshpass -p {DK_VIP_PWD} ssh -o StrictHostKeyChecking=no {DK_VIP_USER}@{DK_VIP_IP} 'docker pull {DK_XIP_IP}:5000/{DockerImageURL}'"
                // docker kill dk_vrte ; docker rm dk_vrte ; docker run  --name dk_vrte --network host --privileged -it phongbosch/dk_vrte:latest
                // start service
                cmd += "sshpass -p '" + DK_VIP_PWD + "' ssh -o StrictHostKeyChecking=no " + DK_VIP_USER + "@" + DK_VIP_IP + " 'docker kill " + appId +  ";docker rm " + appId + ";docker run -d -it --name " + appId + " --log-opt max-size=10m --log-opt max-file=3 --network host  --privileged -v /home/.dk/dk_fota:/home/.dk/dk_fota:ro -v /home/.dk/dk_vss:/home/.dk/dk_vss:ro -v /home/.dk/dk_installedservices/" +     appId + ":/app/runtime " + DK_XIP_IP + ":5000/" + installedServicesList[appIdx].packagelink + " '";
                qDebug() << cmd;
                result = system(cmd.toUtf8());
                if (result != 0) {
                    qDebug() << "Command execution failed with code:" << result;
                }
            }
            else {
                qDebug() << "VIP is not connected. Cannot start the service.";
            }
        }
        else {
            // start service
            cmd += "docker kill " + appId + ";docker rm " + appId + ";docker run -d -it --name " + appId + " --log-opt max-size=10m --log-opt max-file=3    -v /home/" + DK_VCU_USERNAME + "/.dk/dk_installedservices/" + appId + ":/app/runtime --network host " + dbc_default_path_mount + dbc_vss_mount     + safeParams + audioParams + installedServicesList[appIdx].packagelink;
            qCInfo(servicesLog) << "🐳 DOCKER COMMAND TO EXECUTE:";
            qCInfo(servicesLog) << cmd;
            
            if (installedServicesList[appIdx].packagelink.isEmpty() || installedServicesList[appIdx].packagelink == "N/A") {
                qCCritical(servicesLog) << "❌ ERROR: No Docker image specified for service!";
                qCCritical(servicesLog) << "❌ Service was likely installed in embedded mode but trying to run in Docker mode";
                qCCritical(servicesLog) << "❌ Package link is empty or N/A:" << installedServicesList[appIdx].packagelink;
                return;
            }
            
            result = system(cmd.toUtf8());
            if (result != 0) {
                qDebug() << "Command execution failed with code:" << result;
            }
        }

        if (m_workerThread) {
            m_workerThread->triggerCheckAppStart(appId, name);
        } else {
            qCWarning(servicesLog) << "⚠️  Worker thread not available - cannot check service start status";
            // If we can't verify the service started, assume it failed and revert switch
            QTimer::singleShot(3000, this, [this, appId, name, appIdx]() {
                qCWarning(servicesLog) << "🔄 Auto-reverting switch for" << name << "due to verification failure";
                updateServicesRunningSts(appId, false, appIdx);
                handleResults(appId, false, "<b>" + name + "</b> failed to start - switch reverted to OFF");
            });
        }
    }
    else {
        cmd = "docker kill " + appId + " &";
        if (installedServicesList[appIdx].deploytarget == "vip") {
            cmd = "sshpass -p '" + DK_VIP_PWD + "' ssh -o StrictHostKeyChecking=no " + DK_VIP_USER + "@" + DK_VIP_IP + " 'docker kill " + appId + " '";
        }
        qDebug() << cmd;
        int result = system(cmd.toUtf8());
        (void)result; // Suppress unused variable warning
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
    int result;
    // delete service
    if (installedServicesList[index].deploytarget == "vip") {
        cmd = "sshpass -p '" + DK_VIP_PWD + "' ssh -o StrictHostKeyChecking=no " + DK_VIP_USER + "@" + DK_VIP_IP + " 'docker kill " + appId + ";docker rm " + appId + "'";
        qDebug() << cmd;
        result = system(cmd.toUtf8());
        (void)result; // Suppress unused variable warning
    }
    else {
        cmd = "docker kill " + appId + ";docker rm " + appId;
        qDebug() << cmd;
        result = system(cmd.toUtf8());
        (void)result; // Suppress unused variable warning
    }
}

void ServicesAsync::handleResults(QString appId, bool isStarted, QString msg)
{
    qCInfo(servicesLog) << "=== HANDLE RESULTS CALLED ===";
    qCInfo(servicesLog) << "App ID:" << appId;
    qCInfo(servicesLog) << "Is Started:" << isStarted;
    qCInfo(servicesLog) << "Message:" << msg;
    
    qCInfo(servicesLog) << "Calling updateStartAppMsg signal...";
    updateStartAppMsg(appId, isStarted, msg);
    
    if (isStarted) {
        qCInfo(servicesLog) << "Service started - updating internal service list";
        int len = installedServicesList.size();
        qCInfo(servicesLog) << "Searching through" << len << "services for ID:" << appId;
        
        for (int i = 0; i < len; i++) {
            qCInfo(servicesLog) << "  Checking service" << i << ":" << installedServicesList[i].name << "(" << installedServicesList[i].id << ")";
            if (installedServicesList[i].id == appId) {
                qCInfo(servicesLog) << "✅ Found matching service - updating isSubscribed to true";
                installedServicesList[i].isSubscribed = true;
                return;
            }
        }
        qCWarning(servicesLog) << "⚠️ Service ID not found in installedServicesList";
    } else {
        qCInfo(servicesLog) << "❌ Service failed to start - reverting switch to OFF";
        
        // Find the service and revert its state
        int len = installedServicesList.size();
        for (int i = 0; i < len; i++) {
            if (installedServicesList[i].id == appId) {
                qCInfo(servicesLog) << "🔄 Reverting switch for service" << i << ":" << installedServicesList[i].name;
                installedServicesList[i].isSubscribed = false;
                updateServicesRunningSts(appId, false, i);
                break;
            }
        }
    }
    
    qCInfo(servicesLog) << "=== HANDLE RESULTS COMPLETE ===";
}

void ServicesAsync::fileChanged(const QString &path)
{
    qDebug() << __func__ << "@" << __LINE__ <<  " : path: " << path;
    QThread::msleep(1000);
    initInstalledServicesFromDB();
}
