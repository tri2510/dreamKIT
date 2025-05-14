#include "marketplace.hpp"
#include "fetching.hpp"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QDir>

extern QString DK_VCU_USERNAME;
extern QString DK_ARCH;
extern QString DK_DOCKER_HUB_NAMESPACE;
extern QString DK_CONTAINER_ROOT;

// Function to check if the file exists and create it with default content if not
void ensureMarketplaceSelectionExists(const QString &marketplaceFilePath) {
    QFile file(marketplaceFilePath);

    // Check if the file already exists
    if (!file.exists()) {
        qDebug() << "File not found, creating" << marketplaceFilePath;

        // Define default JSON content
        QJsonArray defaultArray;
        QJsonObject defaultMarketplace;
        defaultMarketplace["name"] = "BGSV Marketplace";
        defaultMarketplace["marketplace_url"] = "https://marketplace.digital.auto/";
        defaultMarketplace["login_url"] = "";
        defaultMarketplace["username"] = "";
        defaultMarketplace["pwd"] = "";

        defaultArray.append(defaultMarketplace);
        QJsonDocument defaultDoc(defaultArray);
        QByteArray jsonData = defaultDoc.toJson();

        // Attempt to open the file for writing
        if (file.open(QIODevice::WriteOnly)) {
            file.write(jsonData);
            file.close();
            qDebug() << "Default marketplace selection file created at" << marketplaceFilePath;
        } else {
            qDebug() << "Error: Could not create the file" << marketplaceFilePath;
        }
    } else {
        qDebug() << "Marketplace selection file already exists at" << marketplaceFilePath;
    }
}

AppAsync::AppAsync()
{
    QString dkRootFolder = qgetenv("DK_CONTAINER_ROOT");
    QString marketplaceFolder = dkRootFolder + "dk_marketplace/";
    QString marketPlaceSelection = marketplaceFolder + "marketplaceselection.json";
    // Ensure marketplace selection file exists
    ensureMarketplaceSelectionExists(marketPlaceSelection);

    m_marketplaceList.clear();
    m_marketplaceList = parseMarketplaceFile(marketPlaceSelection);
}

Q_INVOKABLE void AppAsync::initMarketplaceListFromDB()
{
    clearMarketplaceNameList();
    for (const auto &marketplace : m_marketplaceList) {
        qDebug() << "appendMarketplaceUrlList: " << marketplace.name;
        appendMarketplaceUrlList(marketplace.name);
    }
}

Q_INVOKABLE void AppAsync::initInstalledAppFromDB()
{
    qDebug() << __func__ << "@" << __LINE__;
    installedAppList.clear();

    QFile file("./installedapps/installedapps.csv");
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << file.errorString();
        qDebug() << __func__ << "@" << __LINE__;
        return;
    }
    QList<QStringList> appList;
    qDebug() << "appList";
    while (!file.atEnd()) {
        QByteArray lineData = file.readLine();
        QString line = QString(lineData);
        line.replace("\r\n", "");
        line.replace("\n", "");
        qDebug() << line;
        appList.append(QString(line).split(','));
    }

    initInstalledAppList(appList.size() - 1);

    for(int i = 1; i < appList.size(); i++) {
        InstalledAppListStruct appInfo;
        appInfo.foldername  = appList[i][0];
        appInfo.displayname = appList[i][1];
//        appInfo.executable  = "./installedapps/" + appInfo.foldername + "/" + appList[i][2];
        appInfo.executable  = appList[i][2];
        appInfo.iconPath    = "file:./installedapps/" + appInfo.foldername + "/" + appList[i][3];

       qDebug() << appInfo.executable << " - " << appInfo.iconPath;
        appendAppInfoToInstalledAppList(appInfo.displayname, appInfo.iconPath);

        installedAppList.append(appInfo);
    }

    appendLastRowToInstalledAppList();

    file.close();
}

Q_INVOKABLE void AppAsync::setCurrentMarketPlaceIdx(int idx)
{
    qDebug() << __func__ << __LINE__ << " : current idx = " << idx;
    m_current_idx = idx;
    clearAppInfoToAppList();
    searchAppFromStore(m_current_searchname);
}

Q_INVOKABLE void AppAsync::executeApp(const int index)
{
    system("ps -A > ps.log");

    QFile MyFile("ps.log");
    MyFile.open(QIODevice::ReadWrite);
    QTextStream in (&MyFile);
    if (in.readAll().contains(installedAppList[index].executable, Qt::CaseSensitivity::CaseSensitive)) {
        qDebug() << installedAppList[index].executable << " is already open";
    }
    else{
        QString cmd;
        cmd = "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/Qt-6.6.0/lib/ ./installedapps/" + installedAppList[index].foldername + "/" + installedAppList[index].executable + " &";
        qDebug() << cmd;
        system(cmd.toUtf8());
    }
    MyFile.close();

    system("> ps.log");
}

Q_INVOKABLE void AppAsync::runCmd(const QString appName, const QString input)
{
    system("ps -A > ps.log");

    QFile MyFile("ps.log");
    MyFile.open(QIODevice::ReadWrite);
    QTextStream in (&MyFile);
    if (in.readAll().contains(appName, Qt::CaseSensitivity::CaseSensitive)) {
        qDebug() << appName << " is already open";
    }
    else{
        system(input.toUtf8());
    }
    MyFile.close();

    system("> ps.log");
}

// Function to parse marketplaceselection.json and populate a list of MarketplaceInfo
QList<MarketplaceInfo> AppAsync::parseMarketplaceFile(const QString &filePath) 
{
    QList<MarketplaceInfo> marketplaceList;

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "Could not open file:" << filePath;
        return marketplaceList;
    }

    QByteArray jsonData = file.readAll();
    file.close();

    QJsonDocument document = QJsonDocument::fromJson(jsonData);
    if (!document.isArray()) {
        qDebug() << "Invalid JSON format in" << filePath;
        return marketplaceList;
    }

    QJsonArray array = document.array();
    for (const QJsonValue &value : array) {
        if (value.isObject()) {
            QJsonObject obj = value.toObject();
            MarketplaceInfo info;
            info.name = obj["name"].toString();
            info.marketplace_url = obj["marketplace_url"].toString();
            info.login_url = obj["login_url"].toString();
            info.username = obj["username"].toString();
            info.pwd = obj["pwd"].toString();
            marketplaceList.append(info);
        }
    }

    return marketplaceList;
}

void AppAsync::appstore_readAppList(const QString searchName, QList<AppListStruct> &AppListInfo) 
{
    QString marketplaceFolder = DK_CONTAINER_ROOT + "dk_marketplace/";
    QString mpDataPath = marketplaceFolder + "marketplace_data_installcfg.json";

    // queryMarketplacePackages(1, 10, searchName);
    QString marketplace_url = m_marketplaceList[m_current_idx].marketplace_url;
    QString uname = m_marketplaceList[m_current_idx].username;
    QString pwd = m_marketplaceList[m_current_idx].pwd;
    QString login_url = m_marketplaceList[m_current_idx].login_url;

    qDebug() << "Requesting data marketplace_url : " << marketplace_url;
    qDebug() << "Requesting data uname : " << uname;
    qDebug() << "Requesting data pwd : " << pwd;
    qDebug() << "Requesting data login_url : " << login_url;
    qDebug() << "Requesting data searchName : " << searchName;

    QString token = "";
    if (!uname.isEmpty() && !pwd.isEmpty()) {
        // Perform login and query with token if uname and pwd are provided
        token = marketplace_login(login_url, uname, pwd);
        if (!token.isEmpty()) {
            queryMarketplacePackages(marketplace_url, token, 1, 10, searchName);
            // qDebug() << "Authenticated request returned data of length:";
        } else {
            qDebug() << "Failed to authenticate with provided credentials.";
        }
    } else {
        // Query without token if uname and pwd are empty
        queryMarketplacePackages(marketplace_url, token, 1, 10, searchName);
        qDebug() << "Unauthenticated request returned data of length:";
    }

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
        AppListStruct appInfo;

        // Extract relevant fields for AppListStruct
        appInfo.id = jsonObject["_id"].toString();
        appInfo.category = jsonObject["category"].toString();        

        // Extract relevant fields for AppListStruct
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
            AppListInfo.append(appInfo);
        }
    }

    qDebug() << "App list loaded, total apps found:" << AppListInfo.size();
}

Q_INVOKABLE void AppAsync::searchAppFromStore(const QString searchName)
{
    m_current_searchname = searchName;
    if (m_current_searchname == "") {
        m_current_searchname = "vehicle";
    }
//    qDebug() << __func__ << "m_current_searchname = " << m_current_searchname;
    searchedAppList.clear();
    appstore_readAppList(m_current_searchname, searchedAppList);

    if (searchedAppList.size()) {
        for(int i = 0; i < searchedAppList.size(); i++) {
            //        qDebug() << AppListInfo[i].name;
            appendAppInfoToAppList(searchedAppList[i].name, searchedAppList[i].author,
                                   searchedAppList[i].rating, searchedAppList[i].noofdownload,
                                   searchedAppList[i].iconPath,
                                   searchedAppList[i].isInstalled);
        }
    }
    else {
        appendAppInfoToAppList("", "", "", "", "", true);
    }
    appendLastRowToAppList(searchedAppList.size());
}

Q_INVOKABLE void AppAsync::installApp(const int index)
{
    if (index >= searchedAppList.size()) {
        qDebug() << "index out of range";
        return;
    }

    QString appId = searchedAppList[index].id;
    QString appName = searchedAppList[index].name;
    QString thumbnail = searchedAppList[index].iconPath;
    
    qDebug() << searchedAppList[index].name << " index = " << index << " is installing";
    qDebug() << " appId = " << appId;

    QString dockerHubUrl = "";
    if(DK_DOCKER_HUB_NAMESPACE.isEmpty()) {
        DK_DOCKER_HUB_NAMESPACE = qgetenv("DK_DOCKER_HUB_NAMESPACE");
    }
    dockerHubUrl = DK_DOCKER_HUB_NAMESPACE + "/";
     
    QString installCfg = "$(pwd)/dk_marketplace/" + appId + "_installcfg.json";
    QString cmd = "docker kill dk_appinstallservice;docker rm dk_appinstallservice;docker run -d -it --name dk_appinstallservice -v $(pwd):/app/.dk -v /var/run/docker.sock:/var/run/docker.sock --log-opt max-size=10m --log-opt max-file=3 -v " + installCfg + ":/app/installCfg.json " + "autowrx/dk_appinstallservice:latest";
    qDebug() << " install cmd = " << cmd;
    system(cmd.toUtf8()); // this is the exemple, download from local.

    // Update the CSV file
    QString csvPath = "installedapps/installedapps.csv";
    QFile csvFile(csvPath);
    
    // Create directory if it doesn't exist
    QDir dir("installedapps");
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    
    // Check if file exists and create header if needed
    bool fileExists = csvFile.exists();
    if (!fileExists) {
        if (csvFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream stream(&csvFile);
            stream << "foldername,displayname,executable,iconpath\n";
            csvFile.close();
        } else {
            qDebug() << "Error creating CSV file:" << csvFile.errorString();
        }
    }
    
    // Append the new app to the CSV
    if (csvFile.open(QIODevice::Append | QIODevice::Text)) {
        QTextStream stream(&csvFile);
        stream << appId << "," << appName << ",start.sh," << thumbnail << "\n";
        csvFile.close();
        qDebug() << "Updated CSV file with new app";
    } else {
        qDebug() << "Error opening CSV file for writing:" << csvFile.errorString();
    }

    // Also update the JSON file for installedvapps
    // First, ensure DK_CONTAINER_ROOT is set properly
    if (DK_CONTAINER_ROOT.isEmpty()) {
        DK_CONTAINER_ROOT = qgetenv("DK_CONTAINER_ROOT");
        if (DK_CONTAINER_ROOT.isEmpty()) {
            qDebug() << "DK_CONTAINER_ROOT is empty, using default paths";
            DK_CONTAINER_ROOT = "./";
        }
    }
    
    QString jsonFolderPath = DK_CONTAINER_ROOT + "dk_installedapps/";
    QString jsonPath = jsonFolderPath + "installedapps.json";
    
    qDebug() << "Updating JSON file at: " << jsonPath;
    
    // Create JSON directory if needed
    QDir jsonDir(jsonFolderPath);
    if (!jsonDir.exists()) {
        jsonDir.mkpath(".");
        qDebug() << "Created directory: " << jsonFolderPath;
    }
    
    // Read existing JSON file or create empty array
    QJsonArray jsonArray;
    QFile jsonFile(jsonPath);
    if (jsonFile.exists() && jsonFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QByteArray jsonData = jsonFile.readAll();
        jsonFile.close();
        QJsonDocument doc = QJsonDocument::fromJson(jsonData);
        if (!doc.isNull() && doc.isArray()) {
            jsonArray = doc.array();
            qDebug() << "Read existing JSON with " << jsonArray.size() << " apps";
        }
    }
    
    // Check if app already exists in JSON
    bool appExists = false;
    for (int i = 0; i < jsonArray.size(); i++) {
        QJsonObject obj = jsonArray[i].toObject();
        if (obj["_id"].toString() == appId) {
            appExists = true;
            qDebug() << "App already exists in JSON, not adding again";
            break;
        }
    }
    
    // Add the app if it doesn't already exist
    if (!appExists) {
        qDebug() << "Adding app to JSON: " << appName;
        
        // Create a minimal JSON object for the app
        QJsonObject appObj;
        appObj["_id"] = appId;
        appObj["name"] = appName;
        appObj["category"] = "vehicle"; // Default category
        appObj["thumbnail"] = thumbnail;
        appObj["downloads"] = 0;
        
        // Create a createdBy object
        QJsonObject createdBy;
        createdBy["fullName"] = "Unknown";
        appObj["createdBy"] = createdBy;
        
        jsonArray.append(appObj);
        
        // Save updated JSON array
        if (jsonFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QJsonDocument doc(jsonArray);
            jsonFile.write(doc.toJson());
            jsonFile.close();
            qDebug() << "Updated JSON file with new app, total apps: " << jsonArray.size();
        } else {
            qDebug() << "Error opening JSON file for writing: " << jsonFile.errorString() << ". Please ensure proper permissions.";
        }
    }

    // refresh install app view
    initInstalledAppFromDB();
}

Q_INVOKABLE void AppAsync::removeApp(const int index)
{
    if (index >= installedAppList.size()) {
        qDebug() << "index out of range";
        return;
    }

    qDebug() << installedAppList[index].displayname << " index = " << index << " is about to be removed" ;

    QFile file("installedapps/installedapps.csv");
    if (!file.open(QIODevice::ReadWrite | QIODevice::Text)) {
        qDebug() << file.errorString();
        return;
    }

    QString content;
    content.clear();
    QTextStream stream(&file);
    int count = 0;
    while (!file.atEnd()) {
        QByteArray lineData = file.readLine();
        QString line = QString(lineData);
        count++;
        if ((count - 2) == index) continue;
        content.append(line);
    }

    file.resize(0);
    stream << content;
    file.close();

    // remove entire app folder
    QString cmd;
    cmd.clear();
    cmd = "rm -rf installedapps/" + installedAppList[index].foldername;
    qDebug() << cmd;
    system(cmd.toUtf8());
    cmd.clear();
    cmd = "rm -rf installedapps/" + installedAppList[index].foldername + ".zip";
    qDebug() << cmd;
    system(cmd.toUtf8());

    // refresh install app view
    initInstalledAppFromDB();
}
