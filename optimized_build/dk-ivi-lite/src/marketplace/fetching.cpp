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

extern QString DK_CONTAINER_ROOT;

// Function to write the entire QJsonArray to a file
void writeJsonArrayToFile(const QJsonArray &data, QString fileName) {
    // QString fileName = "marketplace_data_installcfg.json";
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
        qDebug() << "Error: Could not open file for writing:" << fileName;
    }
}

// Function to write the JSON object to a file
void writeToJsonObjectFile(const QJsonObject &item, QString fileName) {
    // QString id = item["_id"].toString();  // Use _id for the filename
    // QString fileName = id + "_installcfg.json";
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
        qDebug() << "Error: Could not open file for writing:" << fileName;
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
    QString marketplaceFolder = DK_CONTAINER_ROOT + "dk_marketplace/";
    // qDebug() << "--------------------------------------------------";
    // qDebug() << "Marketplace Data:\n" << data;
    // qDebug() << "--------------------------------------------------";
    for (const QJsonValue &value : data) {
        QJsonObject item = value.toObject();

        // qDebug() << "ID:" << item["_id"].toString();
        // qDebug() << "Name:" << item["name"].toString();
        // qDebug() << "Category:" << item["category"].toString();
        // qDebug() << "Thumbnail:" << item["thumbnail"].toString();
        // qDebug() << "Short Description:" << item["shortDesc"].toString();
        // qDebug() << "Full Description:" << item["fullDesc"].toString();
        // qDebug() << "Visibility:" << item["visibility"].toString();
        // qDebug() << "Created By:" << item["createdBy"].toString();
        // qDebug() << "State:" << item["state"].toString();
        // qDebug() << "Created At:" << item["createdAt"].toString();
        // qDebug() << "Updated At:" << item["updatedAt"].toString();

        // Check if 'dashboardConfig' is present
        if (item.contains("dashboardConfig")) {
            // Parse the dashboardConfig if it's a stringified JSON
            QString rawDashboardConfig = item["dashboardConfig"].toString();
            
            if (!rawDashboardConfig.isEmpty()) {
                QJsonDocument dashboardDoc = QJsonDocument::fromJson(rawDashboardConfig.toUtf8());
                if (!dashboardDoc.isNull()) {
                    QJsonObject dashboardConfig = dashboardDoc.object();

                    // qDebug() << "Dashboard Config:";
                    // qDebug() << "  Docker Image URL:" << dashboardConfig.value("DockerImageURL").toString();
                    // qDebug() << "  Execution Command:" << dashboardConfig.value("ExecutionCommand").toString();
                    // qDebug() << "  Execution File URL:" << dashboardConfig.value("ExecutionFileURL").toString();
                    // qDebug() << "  Execution File Type:" << dashboardConfig.value("ExecutionFileType").toString();

                    // qDebug() << "  Signal List:";
                    QJsonArray signalList = dashboardConfig.value("SignalList").toArray();
                    for (const QJsonValue &signalValue : signalList) {
                        QJsonObject signal = signalValue.toObject();
                        // qDebug() << "    VSS API:" << signal.value("vss_api").toString();
                        // qDebug() << "    Type:" << signal.value("vss_type").toString();
                        // qDebug() << "    Datatype:" << signal.value("datatype").toString();
                        // qDebug() << "    Description:" << signal.value("description").toString();
                        // qDebug() << "    VSS to DBC Signal:" << signal.value("vss2dbc_signal").toString();
                        // qDebug() << "    DBC to VSS Signal:" << signal.value("dbc2vss_signal").toString();
                    }
                } else {
                    qDebug() << "Error: Failed to parse 'dashboardConfig' as a JSON object.";
                }
            } else {
                qDebug() << "Dashboard Config is empty.";
            }
        } else {
            qDebug() << "Dashboard Config: N/A";
        }

        // Write the current object to a JSON file
        QString filePath = marketplaceFolder + item["_id"].toString() + "_installcfg.json";
        writeToJsonObjectFile(item, filePath);
        // qDebug() << "--------------------------------------------------";
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