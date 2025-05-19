#include <QCoreApplication>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QUrlQuery>
#include <QDebug>
#include <QEventLoop>
#include <QFile>
#include <QTextStream>
#include <QDir>

extern QString DK_CONTAINER_ROOT;

// Function to write the entire QJsonArray to a file
void writeJsonArrayToFile(const QJsonArray &data, QString fileName) {
    // Ensure the directory exists
    QFileInfo fileInfo(fileName);
    QDir directory = fileInfo.dir();
    if (!directory.exists()) {
        qDebug() << "Creating directory:" << directory.path();
        if (!directory.mkpath(".")) {
            qDebug() << "Error: Failed to create directory:" << directory.path();
            return;
        }
    }
    
    QFile file(fileName);
    if (file.open(QIODevice::WriteOnly)) {
        // Create a JSON document from the QJsonArray
        QJsonDocument doc(data);

        // Write JSON data to the file
        QTextStream out(&file);
        out << doc.toJson();

        file.close();
        qDebug() << "Data written to file:" << fileName;
    } else {
        qDebug() << "Error: Could not open file for writing:" << fileName 
                 << " - Error:" << file.errorString();
    }
}

// Function to write the JSON object to a file
void writeToJsonObjectFile(const QJsonObject &item, QString fileName) {
    // Ensure the directory exists
    QFileInfo fileInfo(fileName);
    QDir directory = fileInfo.dir();
    if (!directory.exists()) {
        qDebug() << "Creating directory:" << directory.path();
        if (!directory.mkpath(".")) {
            qDebug() << "Error: Failed to create directory:" << directory.path();
            return;
        }
    }
    
    QFile file(fileName);
    if (file.open(QIODevice::WriteOnly)) {
        // Create a JSON document from the QJsonObject
        QJsonDocument doc(item);

        // Write JSON data to the file
        QTextStream out(&file);
        out << doc.toJson();

        file.close();
        qDebug() << "Data written to file:" << fileName;
    } else {
        qDebug() << "Error: Could not open file for writing:" << fileName 
                 << " - Error:" << file.errorString();
    }
}

// Function to perform login and get the token
QString marketplace_login(const QString &login_url, const QString &username, const QString &password) {
    QNetworkAccessManager manager;
    QUrl url(login_url);

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject loginData;
    loginData["email"] = username;
    loginData["password"] = password;
    QJsonDocument jsonDoc(loginData);

    QEventLoop loop;
    QNetworkReply *reply = manager.post(request, jsonDoc.toJson());
    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();

    QString token;
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        QJsonDocument jsonResponse = QJsonDocument::fromJson(responseData);
        QJsonObject jsonObject = jsonResponse.object();
        token = jsonObject["token"].toString();
        if (token.isEmpty()) {
            qDebug() << "Invalid credentials: No token returned";
        }
        else {
            qDebug() << "Successfully login to marketplace !!!";
        }
    } else {
        qDebug() << "Login error:" << reply->errorString();
    }
    reply->deleteLater();
    return token;
}

// Function to parse and print the data
void parseMarketplaceData(const QJsonArray &data) {
    // Handle tilde expansion
    QString expandedContainerRoot = DK_CONTAINER_ROOT;
    if (expandedContainerRoot.startsWith("~")) {
        QString homeDir = QDir::homePath();
        expandedContainerRoot.replace(0, 1, homeDir);
        qDebug() << "Expanded DK_CONTAINER_ROOT from" << DK_CONTAINER_ROOT << "to" << expandedContainerRoot;
    }
    
    QString marketplaceFolder = expandedContainerRoot + "dk_marketplace/";
    qDebug() << "Using marketplace folder:" << marketplaceFolder;
    
    // Ensure directory exists
    QDir marketplaceDir(marketplaceFolder);
    if (!marketplaceDir.exists()) {
        qDebug() << "Creating marketplace directory:" << marketplaceFolder;
        bool success = marketplaceDir.mkpath(".");
        qDebug() << "Directory creation result:" << (success ? "Success" : "Failed");
    }
    
    // Write the individual item files
    for (const QJsonValue &value : data) {
        QJsonObject item = value.toObject();
        QString filePath = marketplaceFolder + item["_id"].toString() + "_installcfg.json";
        writeToJsonObjectFile(item, filePath);
    }

    // Write the entire array to a file
    QString mpDataPath = marketplaceFolder + "marketplace_data_installcfg.json";
    writeJsonArrayToFile(data, mpDataPath);
}

// Function to beautify a QJsonArray (convert and format it)
QJsonArray beautifyJsonArray(const QJsonArray &jsonArray) {
    QJsonArray beautifiedArray;

    // Loop over each element in the original QJsonArray
    for (const QJsonValue &value : jsonArray) {
        if (value.isObject()) {
            // Convert each QJsonObject to a formatted string
            QJsonDocument doc(value.toObject());
            QByteArray beautifiedJson = doc.toJson(QJsonDocument::Indented);

            // Print the beautified JSON (for debug purposes)
            qDebug() << "Beautified JSON Object:" << beautifiedJson;

            // Parse the beautified string back to a QJsonObject and add to the new QJsonArray
            QJsonObject beautifiedObject = QJsonDocument::fromJson(beautifiedJson).object();
            beautifiedArray.append(beautifiedObject);
        } else if (value.isArray()) {
            // If it's another array, recurse
            beautifiedArray.append(beautifyJsonArray(value.toArray()));
        } else {
            // Add other types of values as-is
            beautifiedArray.append(value);
        }
    }

    return beautifiedArray;
}

// Function to make the network request
bool queryMarketplacePackages(const QString &marketplace_url, const QString &token, int page = 1, int limit = 10, const QString &category = "vehicle") {
// bool queryMarketplacePackages(int page = 1, int limit = 10, const QString &category = "vehicle") {

    QUrl url(marketplace_url + "/package");
    QUrlQuery query;
    query.addQueryItem("page", QString::number(page));
    query.addQueryItem("limit", QString::number(limit));
    query.addQueryItem("category", category);
    url.setQuery(query);

    QNetworkAccessManager manager;
    QNetworkRequest request(url);
    QEventLoop loop;

    if (!token.isEmpty()) {
        request.setRawHeader("Authorization", "Bearer " + token.toUtf8());
    }
    
    QNetworkReply *reply = manager.get(request);

    // Wait for the request to finish
    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();

    QJsonArray jsonArray;

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        QJsonDocument jsonResponse = QJsonDocument::fromJson(responseData);
        QJsonObject jsonObject = jsonResponse.object();

        jsonArray = jsonObject["data"].toArray();
        qDebug() << "len of data:" << jsonArray.size();
    } else {
        return false;
        qDebug() << "Error:" << reply->errorString();
    }

    reply->deleteLater();

    parseMarketplaceData(jsonArray);

    return true;
}