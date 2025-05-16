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
        defaultMarketplace["marketplace_url"] = "";
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
    QString dkRootFolder = DK_CONTAINER_ROOT;
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
    qDebug() << "==== BEGIN" << __func__ << "====";
    qDebug() << "Current working directory:" << QDir::currentPath();
    qDebug() << "Clearing installedAppList";
    installedAppList.clear();

    QString csvPath = "./installedapps/installedapps.csv";
    qDebug() << "CSV path:" << csvPath;
    QFile file(csvPath);
    
    // Check if file and directory exist
    QFileInfo fileInfo(csvPath);
    QDir dir = fileInfo.dir();
    qDebug() << "Directory path:" << dir.absolutePath();
    qDebug() << "Directory exists:" << dir.exists();
    qDebug() << "File exists:" << fileInfo.exists();
    qDebug() << "File is readable:" << fileInfo.isReadable();
    
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "ERROR: Failed to open CSV file:" << file.errorString();
        
        // Try to create directory if it doesn't exist
        if (!dir.exists()) {
            qDebug() << "Directory doesn't exist, attempting to create it...";
            bool dirCreated = dir.mkpath(".");
            qDebug() << "Directory creation result:" << dirCreated;
            
            // Try to create an empty CSV file
            QFile newFile(csvPath);
            if (newFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
                QTextStream stream(&newFile);
                stream << "foldername,displayname,executable,iconpath\n";
                newFile.close();
                qDebug() << "Created new CSV file with header";
            } else {
                qDebug() << "Failed to create new CSV file:" << newFile.errorString();
            }
        }
        
        qDebug() << "Exiting" << __func__ << "due to file open error";
        return;
    }
    
    QList<QStringList> appList;
    qDebug() << "Reading CSV data...";
    
    int lineCount = 0;
    while (!file.atEnd()) {
        QByteArray lineData = file.readLine();
        QString line = QString(lineData);
        line.replace("\r\n", "");
        line.replace("\n", "");
        lineCount++;
        
        qDebug() << "Line" << lineCount << ":" << line;
        QStringList splitLine = QString(line).split(',');
        qDebug() << "  Split into" << splitLine.size() << "parts";
        appList.append(splitLine);
    }
    
    qDebug() << "Total lines read:" << lineCount;
    qDebug() << "Total items in appList:" << appList.size();
    
    if (appList.size() <= 1) {
        qDebug() << "Warning: CSV contains only header or is empty";
    }
    
    qDebug() << "Initializing installedAppList with size:" << (appList.size() - 1);
    initInstalledAppList(appList.size() - 1);

    for(int i = 1; i < appList.size(); i++) {
        qDebug() << "Processing app index:" << i;
        
        // Check if the line has enough elements
        if (appList[i].size() < 4) {
            qDebug() << "WARNING: Line" << i << "has insufficient data:" << appList[i].join(",");
            continue;
        }
        
        InstalledAppListStruct appInfo;
        appInfo.foldername  = appList[i][0];
        appInfo.displayname = appList[i][1];
        appInfo.executable  = appList[i][2];
        appInfo.iconPath    = "file:./installedapps/" + appInfo.foldername + "/" + appList[i][3];

        qDebug() << "App" << i << "details:";
        qDebug() << "  Folder name:" << appInfo.foldername;
        qDebug() << "  Display name:" << appInfo.displayname;
        qDebug() << "  Executable:" << appInfo.executable;
        qDebug() << "  Icon path:" << appInfo.iconPath;
        
        // Check if the app folder exists
        QDir appDir("./installedapps/" + appInfo.foldername);
        qDebug() << "  App directory exists:" << appDir.exists();
        
        // Check if the icon file exists
        QFileInfo iconInfo("./installedapps/" + appInfo.foldername + "/" + appList[i][3]);
        qDebug() << "  Icon file exists:" << iconInfo.exists();
        
        qDebug() << "  Appending to UI list...";
        appendAppInfoToInstalledAppList(appInfo.displayname, appInfo.iconPath);

        qDebug() << "  Adding to installedAppList";
        installedAppList.append(appInfo);
    }

    qDebug() << "Appending last row";
    appendLastRowToInstalledAppList();

    qDebug() << "Closing file";
    file.close();
    qDebug() << "==== END" << __func__ << "====";
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
    qDebug() << "==== BEGIN installApp ====";
    qDebug() << "Current working directory:" << QDir::currentPath();
    
    if (index >= searchedAppList.size()) {
        qDebug() << "ERROR: Index" << index << "out of range (searchedAppList size:" << searchedAppList.size() << ")";
        return;
    }

    QString appId = searchedAppList[index].id;
    QString appName = searchedAppList[index].name;
    QString thumbnail = searchedAppList[index].iconPath;
    
    // Check if this is a service (important: do this check before any file operations)
    bool isService = searchedAppList[index].category.contains("vehicle-service", Qt::CaseInsensitive);
    
    qDebug() << "Installing " << (isService ? "service" : "app") << ": " << appName << " at index: " << index;
    qDebug() << "App ID:" << appId;
    qDebug() << "Thumbnail:" << thumbnail;
    qDebug() << "Is Service:" << isService;

    // Debug environment variables
    qDebug() << "DK_VCU_USERNAME:" << DK_VCU_USERNAME;
    qDebug() << "DK_CONTAINER_ROOT:" << DK_CONTAINER_ROOT;
    qDebug() << "DK_DOCKER_HUB_NAMESPACE:" << DK_DOCKER_HUB_NAMESPACE;
    qDebug() << "DK_ARCH:" << DK_ARCH;
    
    QString dockerHubUrl = "";
    if(DK_DOCKER_HUB_NAMESPACE.isEmpty()) {
        DK_DOCKER_HUB_NAMESPACE = qgetenv("DK_DOCKER_HUB_NAMESPACE");
        qDebug() << "Getting DK_DOCKER_HUB_NAMESPACE from env:" << DK_DOCKER_HUB_NAMESPACE;
    }
    dockerHubUrl = DK_DOCKER_HUB_NAMESPACE + "/";
    qDebug() << "Docker Hub URL:" << dockerHubUrl;

    QString installCfg = "/home/" + DK_VCU_USERNAME + "/.dk/dk_marketplace/" + appId + "_installcfg.json";
    qDebug() << "Install config path:" << installCfg;
    qDebug() << "Install config exists:" << QFileInfo(installCfg).exists();

    QString cmd = "docker kill dk_appinstallservice;docker rm dk_appinstallservice;docker run -d -it --name dk_appinstallservice -v /home/" + DK_VCU_USERNAME + "/.dk:/app/.dk -v /var/run/docker.sock:/var/run/docker.sock --log-opt max-size=10m --log-opt max-file=3 -v " + installCfg + ":/app/installCfg.json " + "autowrx/dk_appinstallservice:latest";
    qDebug() << "Docker install command:" << cmd;
    
    int cmdResult = system(cmd.toUtf8());
    qDebug() << "Docker command result code:" << cmdResult;

    // First, ensure DK_CONTAINER_ROOT is set properly
    if (DK_CONTAINER_ROOT.isEmpty()) {
        DK_CONTAINER_ROOT = qgetenv("DK_CONTAINER_ROOT");
        qDebug() << "Getting DK_CONTAINER_ROOT from env:" << DK_CONTAINER_ROOT;
        if (DK_CONTAINER_ROOT.isEmpty()) {
            qDebug() << "DK_CONTAINER_ROOT is empty, using default paths";
            DK_CONTAINER_ROOT = "./";
        }
    }

    // Create a JSON object for the app/service
    QJsonObject appObj;
    appObj["_id"] = appId;
    appObj["name"] = appName;
    appObj["thumbnail"] = thumbnail;
    appObj["downloads"] = 0;
    appObj["category"] = isService ? "vehicle-service" : "vehicle";
    
    // Create a createdBy object
    QJsonObject createdBy;
    createdBy["fullName"] = "Unknown";
    appObj["createdBy"] = createdBy;
    
    if (isService) {
        // ======= SERVICE INSTALLATION PATH =======
        qDebug() << "Processing as a SERVICE";
        
        // For services, save to services JSON
        QString servicesJsonFolderPath = DK_CONTAINER_ROOT + "dk_installedservices/";
        QString servicesJsonPath = servicesJsonFolderPath + "installedservices.json";
        
        qDebug() << "Saving to services JSON:" << servicesJsonPath;
        
        // Create services JSON directory if needed
        QDir servicesJsonDir(servicesJsonFolderPath);
        if (!servicesJsonDir.exists()) {
            bool dirCreated = servicesJsonDir.mkpath(".");
            qDebug() << "Services directory creation result:" << dirCreated;
        }
        
        // Read existing services JSON file or create empty array
        QJsonArray servicesJsonArray;
        QFile servicesJsonFile(servicesJsonPath);
        
        if (servicesJsonFile.exists() && servicesJsonFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QByteArray jsonData = servicesJsonFile.readAll();
            servicesJsonFile.close();
            QJsonDocument doc = QJsonDocument::fromJson(jsonData);
            if (!doc.isNull() && doc.isArray()) {
                servicesJsonArray = doc.array();
                qDebug() << "Services JSON array read, size:" << servicesJsonArray.size();
            }
        }
        
        // Check if service already exists in services JSON
        bool serviceExists = false;
        for (int i = 0; i < servicesJsonArray.size(); i++) {
            QJsonObject obj = servicesJsonArray[i].toObject();
            if (obj["_id"].toString() == appId) {
                serviceExists = true;
                qDebug() << "Service already exists in JSON at index" << i;
                break;
            }
        }
        
        // Add the service if it doesn't already exist
        if (!serviceExists) {
            servicesJsonArray.append(appObj);
            
            // Save updated services JSON array
            if (servicesJsonFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
                QJsonDocument doc(servicesJsonArray);
                servicesJsonFile.write(doc.toJson());
                servicesJsonFile.close();
                qDebug() << "Service JSON file updated with new service:" << appName;
            } else {
                qDebug() << "Service JSON file write error:" << servicesJsonFile.errorString();
            }
        }
    } else {
        // ======= APP INSTALLATION PATH =======
        qDebug() << "Processing as a regular APP";
        
        // Update the CSV file for regular apps
        QString csvPath = "installedapps/installedapps.csv";
        qDebug() << "CSV path:" << csvPath;
        QFile csvFile(csvPath);
        
        // Create directory if it doesn't exist
        QDir dir("installedapps");
        qDebug() << "installedapps directory exists:" << dir.exists();
        if (!dir.exists()) {
            qDebug() << "Creating installedapps directory...";
            bool dirCreated = dir.mkpath(".");
            qDebug() << "Directory creation result:" << dirCreated;
            if (!dirCreated) {
                qDebug() << "Directory creation failed - check permissions";
            }
        }
        
        // Check if file exists and create header if needed
        bool fileExists = csvFile.exists();
        qDebug() << "CSV file exists:" << fileExists;
        
        if (!fileExists) {
            qDebug() << "Creating CSV file with header";
            bool fileOpened = csvFile.open(QIODevice::WriteOnly | QIODevice::Text);
            qDebug() << "CSV file opened for header creation:" << fileOpened;
            if (fileOpened) {
                QTextStream stream(&csvFile);
                stream << "foldername,displayname,executable,iconpath\n";
                csvFile.close();
                qDebug() << "CSV header written";
            } else {
                qDebug() << "CSV file creation error:" << csvFile.errorString();
            }
        }
        
        // Append the new app to the CSV
        qDebug() << "Appending to CSV file";
        bool csvOpened = csvFile.open(QIODevice::Append | QIODevice::Text);
        qDebug() << "CSV file opened for append:" << csvOpened;
        if (csvOpened) {
            QTextStream stream(&csvFile);
            stream << appId << "," << appName << ",start.sh," << thumbnail << "\n";
            csvFile.close();
            qDebug() << "App appended to CSV";
        } else {
            qDebug() << "CSV append error:" << csvFile.errorString();
        }
        
        // For regular apps, save to apps JSON
        QString jsonFolderPath = DK_CONTAINER_ROOT + "dk_installedapps/";
        QString jsonPath = jsonFolderPath + "installedapps.json";
        
        qDebug() << "Saving to apps JSON:" << jsonPath;
        
        // Create JSON directory if needed
        QDir jsonDir(jsonFolderPath);
        if (!jsonDir.exists()) {
            bool jsonDirCreated = jsonDir.mkpath(".");
            qDebug() << "JSON directory creation result:" << jsonDirCreated;
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
                qDebug() << "JSON array read, size:" << jsonArray.size();
            }
        }
        
        // Check if app already exists in JSON
        bool appExists = false;
        for (int i = 0; i < jsonArray.size(); i++) {
            QJsonObject obj = jsonArray[i].toObject();
            if (obj["_id"].toString() == appId) {
                appExists = true;
                qDebug() << "App already exists in JSON at index" << i;
                break;
            }
        }
        
        // Add the app if it doesn't already exist
        if (!appExists) {
            jsonArray.append(appObj);
            
            // Save updated JSON array
            if (jsonFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
                QJsonDocument doc(jsonArray);
                jsonFile.write(doc.toJson());
                jsonFile.close();
                qDebug() << "JSON file updated with new app, total apps:" << jsonArray.size();
            } else {
                qDebug() << "JSON file write error:" << jsonFile.errorString();
            }
        }
    }

    qDebug() << "Refreshing installed app view";
    initInstalledAppFromDB();
    qDebug() << "==== END installApp ====";
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
