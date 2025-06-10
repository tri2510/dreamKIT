#include "marketplace.hpp"
#include "fetching.hpp"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QDir>
#include <QDateTime>
#include <QFileInfo>
#include <QProcess>
#include <QCoreApplication>
#include <QTimer>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(marketplaceLog, "dk.ivi.marketplace")

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

        // Ensure the directory exists first
        QFileInfo fileInfo(marketplaceFilePath);
        QDir dir = fileInfo.absoluteDir();
        if (!dir.exists()) {
            qDebug() << "Creating directory:" << dir.absolutePath();
            if (!dir.mkpath(".")) {
                qDebug() << "Error: Could not create directory" << dir.absolutePath();
                return;
            }
        }

        // Define default JSON content
        QJsonArray defaultArray;
        QJsonObject defaultMarketplace;
        defaultMarketplace["name"] = "BGSV Marketplace";
        defaultMarketplace["marketplace_url"] = "https://store-be.digitalauto.tech";
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

MarketplaceAsync::MarketplaceAsync()
{
    qCInfo(marketplaceLog) << "=== MARKETPLACE CONSTRUCTOR START ===";
    
    QString dkRootFolder = qgetenv("DK_CONTAINER_ROOT");
    if (dkRootFolder.isEmpty()) {
        qCWarning(marketplaceLog) << "DK_CONTAINER_ROOT environment variable is not set, using default";
        dkRootFolder = QDir::homePath() + "/.dk/";
    }
    
    // Ensure dkRootFolder ends with /
    if (!dkRootFolder.endsWith("/")) {
        dkRootFolder += "/";
    }
    
    QString marketplaceFolder = dkRootFolder + "dk_marketplace/";
    QString marketPlaceSelection = marketplaceFolder + "marketplaceselection.json";
    
    qCInfo(marketplaceLog) << "DK Root folder:" << dkRootFolder;
    qCInfo(marketplaceLog) << "Marketplace folder:" << marketplaceFolder;
    qCInfo(marketplaceLog) << "Marketplace selection file:" << marketPlaceSelection;
    
    // Ensure marketplace selection file exists
    qCInfo(marketplaceLog) << "Ensuring marketplace selection file exists...";
    ensureMarketplaceSelectionExists(marketPlaceSelection);

    m_marketplaceList.clear();
    qCInfo(marketplaceLog) << "Parsing marketplace file...";
    m_marketplaceList = parseMarketplaceFile(marketPlaceSelection);
    
    if (m_marketplaceList.isEmpty()) {
        qCWarning(marketplaceLog) << "Failed to load marketplace list, creating default entry";
        // Create a default marketplace entry if parsing failed
        MarketplaceInfo defaultInfo;
        defaultInfo.name = "BGSV Marketplace";
        defaultInfo.marketplace_url = "https://store-be.digitalauto.tech";
        defaultInfo.login_url = "";
        defaultInfo.username = "";
        defaultInfo.pwd = "";
        m_marketplaceList.append(defaultInfo);
    } else {
        qCInfo(marketplaceLog) << "Loaded" << m_marketplaceList.size() << "marketplace(s)";
        for (int i = 0; i < m_marketplaceList.size(); i++) {
            qCInfo(marketplaceLog) << "  [" << i << "]" << m_marketplaceList[i].name << ":" << m_marketplaceList[i].marketplace_url;
        }
    }

    // No timer needed - installation is triggered only on demand
    qCInfo(marketplaceLog) << "Marketplace initialized - installation available on demand";
    qCInfo(marketplaceLog) << "=== MARKETPLACE CONSTRUCTOR COMPLETE ===";
}

void MarketplaceAsync::checkInstallServiceIsRunning()
{
    // This function is no longer used - installation is on-demand only
    qDebug() << "checkInstallServiceIsRunning() called but not needed in new implementation";
}

Q_INVOKABLE void MarketplaceAsync::initMarketplaceListFromDB()
{
    qCInfo(marketplaceLog) << "=== INIT MARKETPLACE LIST FROM DB ===";
    qCInfo(marketplaceLog) << "Clearing marketplace name list...";
    clearMarketplaceNameList();
    
    qCInfo(marketplaceLog) << "Adding" << m_marketplaceList.size() << "marketplace(s) to UI...";
    for (const auto &marketplace : m_marketplaceList) {
        qCInfo(marketplaceLog) << "Adding marketplace to UI:" << marketplace.name;
        appendMarketplaceUrlList(marketplace.name);
    }
    qCInfo(marketplaceLog) << "=== MARKETPLACE LIST INIT COMPLETE ===";
}

Q_INVOKABLE void MarketplaceAsync::setCurrentMarketPlaceIdx(int idx)
{
    qDebug() << __func__ << __LINE__ << " : current idx = " << idx;
    m_current_idx = idx;
    clearAppInfoToAppList();
    searchAppFromStore(m_current_searchname);
}

// Function to parse marketplaceselection.json and populate a list of MarketplaceInfo
QList<MarketplaceInfo> MarketplaceAsync::parseMarketplaceFile(const QString &filePath) 
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

bool MarketplaceAsync::isAppInstalled(const QString &appId, const QString &category) {
    qCInfo(marketplaceLog) << "Checking if app is installed - ID:" << appId << "Category:" << category;
    
    QString dkRootFolder = qgetenv("DK_CONTAINER_ROOT");
    if (dkRootFolder.isEmpty()) {
        dkRootFolder = QDir::homePath() + "/.dk/";
    }
    
    // Ensure dkRootFolder ends with /
    if (!dkRootFolder.endsWith("/")) {
        dkRootFolder += "/";
    }
    
    qCInfo(marketplaceLog) << "DK_CONTAINER_ROOT:" << dkRootFolder;
    
    QString installedFilePath;
    if (category == "vehicle") {
        installedFilePath = dkRootFolder + "dk_installedapps/installedapps.json";
    } else if (category == "vehicle-service") {
        installedFilePath = dkRootFolder + "dk_installedservices/installedservices.json";
    } else {
        qCInfo(marketplaceLog) << "Unknown category" << category << "- not installed";
        return false;
    }
    
    qCInfo(marketplaceLog) << "Checking installed file:" << installedFilePath;
    
    QFile file(installedFilePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qCDebug(marketplaceLog) << "Could not open installed file:" << installedFilePath << "- assuming not installed";
        return false;
    }
    
    QByteArray jsonData = file.readAll();
    file.close();
    
    QJsonDocument document = QJsonDocument::fromJson(jsonData);
    if (!document.isArray()) {
        qCDebug(marketplaceLog) << "Invalid JSON format in" << installedFilePath << "- assuming not installed";
        return false;
    }
    
    QJsonArray array = document.array();
    qCDebug(marketplaceLog) << "Found" << array.size() << "installed items in" << installedFilePath;
    
    for (const QJsonValue &value : array) {
        if (value.isObject()) {
            QJsonObject obj = value.toObject();
            QString installedId = obj["_id"].toString();
            qCDebug(marketplaceLog) << "  Checking installed ID:" << installedId << "vs target:" << appId;
            if (installedId == appId) {
                qCDebug(marketplaceLog) << "✅ App" << appId << "IS INSTALLED";
                return true;
            }
        }
    }
    
    qCDebug(marketplaceLog) << "❌ App" << appId << "is NOT installed";
    return false;
}

void MarketplaceAsync::appstore_readAppList(const QString searchName, QList<AppListStruct> &AppListInfo) 
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
        appInfo.packagelink = jsonObject["dashboardConfig"].toString().isEmpty() ? "N/A" : jsonObject["dashboardConfig"].toString();

        // Check if app is actually installed
        bool installed = isAppInstalled(appInfo.id, appInfo.category);
        qCInfo(marketplaceLog) << "App" << appInfo.name << "(" << appInfo.id << ") installed status:" << installed;
        appInfo.isInstalled = installed;

        // Only add to the list if the name contains the searchName
        if (appInfo.category.contains(searchName, Qt::CaseInsensitive)) {
            AppListInfo.append(appInfo);
        }
    }

    qDebug() << "App list loaded, total apps found:" << AppListInfo.size();
}

Q_INVOKABLE void MarketplaceAsync::searchAppFromStore(const QString searchName)
{
    qCInfo(marketplaceLog) << "=== SEARCH APP FROM STORE ===";
    qCInfo(marketplaceLog) << "Search term:" << searchName;
    
    m_current_searchname = searchName;
    if (m_current_searchname == "") {
        m_current_searchname = "vehicle";
        qCInfo(marketplaceLog) << "Empty search term, using default: vehicle";
    }
    
    qCInfo(marketplaceLog) << "Final search term:" << m_current_searchname;
    qCInfo(marketplaceLog) << "Clearing previous search results...";
    m_searchedAppList.clear();
    
    qCInfo(marketplaceLog) << "Reading app list from store...";
    appstore_readAppList(m_current_searchname, m_searchedAppList);

    qCInfo(marketplaceLog) << "Found" << m_searchedAppList.size() << "apps/services";
    
    if (m_searchedAppList.size()) {
        qCInfo(marketplaceLog) << "Adding apps to UI list:";
        for(int i = 0; i < m_searchedAppList.size(); i++) {
            qCInfo(marketplaceLog) << "  [" << i << "]" << m_searchedAppList[i].name 
                                   << "(" << m_searchedAppList[i].category << ")" 
                                   << "- Installed:" << m_searchedAppList[i].isInstalled;
            appendAppInfoToAppList(m_searchedAppList[i].name, m_searchedAppList[i].author,
                                   m_searchedAppList[i].rating, m_searchedAppList[i].noofdownload,
                                   m_searchedAppList[i].iconPath,
                                   m_searchedAppList[i].isInstalled);
        }
    }
    else {
        qCWarning(marketplaceLog) << "No apps found, adding empty result";
        appendAppInfoToAppList("", "", "", "", "", true);
    }
    
    qCInfo(marketplaceLog) << "Finalizing app list with" << m_searchedAppList.size() << "items";
    appendLastRowToAppList(m_searchedAppList.size());
    qCInfo(marketplaceLog) << "=== SEARCH COMPLETE ===";
}

Q_INVOKABLE void MarketplaceAsync::installApp(const int index)
{
    qCInfo(marketplaceLog) << "=== INSTALL APP REQUEST ===";
    qCInfo(marketplaceLog) << "Requested index:" << index << "of" << m_searchedAppList.size() << "apps";
    
    if (index >= m_searchedAppList.size()) {
        qCCritical(marketplaceLog) << "Install failed: index" << index << "out of range (max:" << m_searchedAppList.size()-1 << ")";
        return;
    }

    QString appId = m_searchedAppList[index].id;
    QString appName = m_searchedAppList[index].name;
    QString category = m_searchedAppList[index].category;
    
    qCInfo(marketplaceLog) << "Installing app:";
    qCInfo(marketplaceLog) << "  Name:" << appName;
    qCInfo(marketplaceLog) << "  ID:" << appId;
    qCInfo(marketplaceLog) << "  Category:" << category;
    qCInfo(marketplaceLog) << "  Author:" << m_searchedAppList[index].author;

    // Create installation config file
    QString installCfg = "/home/" + DK_VCU_USERNAME + "/.dk/dk_marketplace/" + appId + "_installcfg.json";
    qCInfo(marketplaceLog) << "Installation config path:" << installCfg;
    
    QDir().mkpath(QFileInfo(installCfg).absolutePath());
    qCInfo(marketplaceLog) << "Created directory for config file";
    
    // Create installation config with marketplace app data
    QJsonObject installConfig;
    installConfig["_id"] = appId;
    installConfig["name"] = appName;
    installConfig["category"] = category;
    
    // Create dashboard config for the app installation service
    QJsonObject dashboardConfig;
    dashboardConfig["DockerImageURL"] = "mock-service:latest";
    dashboardConfig["Target"] = "xip";
    dashboardConfig["Platform"] = "linux/arm64";
    dashboardConfig["RuntimeCfg"] = QJsonObject();
    
    installConfig["dashboardConfig"] = QString(QJsonDocument(dashboardConfig).toJson(QJsonDocument::Compact));
    
    qCInfo(marketplaceLog) << "Created installation config JSON";
    
    // Write installation config file
    QJsonDocument doc(installConfig);
    QFile file(installCfg);
    if (!file.open(QIODevice::WriteOnly)) {
        qCCritical(marketplaceLog) << "Install failed: Could not create config file:" << installCfg;
        return;
    }
    
    file.write(doc.toJson());
    file.close();
    qCInfo(marketplaceLog) << "Install config file written successfully";
    
    // Show installation progress
    qCInfo(marketplaceLog) << "Showing installation progress indicator...";
    setInstallServiceRunningStatus(true);
    
    // Run the dk_appinstallservice script directly
    // Check if running in Docker environment
    QString appInstallScript;
    if (QFile::exists("/app/exec/dk_ivi")) {
        // Running in Docker - use absolute path to host-mounted scripts
        appInstallScript = "/home/" + DK_VCU_USERNAME + "/01_SDV/10_dreamkit_v2/dreamKIT/dreamos-core/dk-ivi-lite/scripts/run_appinstallservice.sh";
    } else {
        // Running locally - use relative path
        appInstallScript = QCoreApplication::applicationDirPath() + "/../scripts/run_appinstallservice.sh";
    }
    QString cmd = appInstallScript + " " + installCfg;
    qCInfo(marketplaceLog) << "Executing installation command:" << cmd;
    
    // Execute installation script and wait for completion
    qCInfo(marketplaceLog) << "Starting installation process...";
    int result = system(cmd.toUtf8());
    qCInfo(marketplaceLog) << "Installation process finished with exit code:" << result;
    
    // Hide installation progress after completion
    qCInfo(marketplaceLog) << "Hiding installation progress indicator...";
    setInstallServiceRunningStatus(false);
    
    if (result == 0) {
        qCInfo(marketplaceLog) << "✅ Installation completed successfully for:" << appName;
        
        // Refresh the app list to update installation status
        qCInfo(marketplaceLog) << "Refreshing app list to update installation status...";
        clearAppInfoToAppList();
        searchAppFromStore(m_current_searchname);
        
        qCInfo(marketplaceLog) << "App list refreshed - installation status should now be updated";
    } else {
        qCCritical(marketplaceLog) << "❌ Installation failed for:" << appName << "Exit code:" << result;
    }
    qCInfo(marketplaceLog) << "=== INSTALL APP COMPLETE ===";
}
