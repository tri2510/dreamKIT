#include "dapr_utils.h"
#include "fileutils.h"
#include "common_utils.h"
#include <QFile>
#include <QDebug>
#include <QThread>
#include <QCryptographicHash>
#include <QMutex>
#include <QFileInfo>
#include <QtNetwork>

#include <QJsonDocument>
#include <QJsonValue>
#include <QJsonArray>
#include <QJsonObject>
#include <QRandomGenerator>

extern std::string DK_VCU_USERNAME;
extern std::string DK_ARCH;
extern std::string DK_DOCKER_HUB_NAMESPACE;

Dapr_Utils::Dapr_Utils(QString dapr_dir, QString proto_dir, QString _log_dir)
{
    this->_dapr_dir = dapr_dir;
    this->_proto_dir = proto_dir;
    this->_log_dir = _log_dir;
    this->_app_args = " --app-protocol grpc --resources-path " + this->_dapr_dir + "components --config " + this->_dapr_dir + "config.yaml --app-port 50008 ";
}

int Dapr_Utils::stopApp(QString app_id) {
    if(app_id.length()<=0) return -1;

    QString cmd;
    cmd.clear();

    cmd += "docker stop " + app_id + "; docker rm " + app_id + ";";
    qDebug() << cmd;
    return system(cmd.toUtf8());
}

int Dapr_Utils::startApp(QString app_id) {
    if(app_id.length()<=0) return -1;

    // try to stop app before start
    this->stopApp(app_id);

    QString cmd;
    cmd.clear();

    // docker run -d -it --name giWROQ6WzQcJOkEd3OFn --log-opt max-size=10m --log-opt max-file=3 -v ~/.dk/dk_vssgeneration/vehicle_gen/:/home/vss/vehicle_gen:ro -v ~/.dk/dk_app_python_template/target/amd64/python-packages:/home/python-packages:ro --network host -v ~/.dk/dk_manager/prototypes/giWROQ6WzQcJOkEd3OFn:/app/exec phongbosch/dk_app_python_template:baseimage
    // cmd += "docker run -d -it --name " + app_id + " --log-opt max-size=10m --log-opt max-file=3 -v /app/.dk/dk_vssgeneration/vehicle_gen/:/home/vss/vehicle_gen:ro -v /app/.dk/dk_app_python_template/target/amd64/python-packages:/home/python-packages:ro --network host -v /app/.dk/dk_manager/prototypes/" + app_id + ":/app/exec dk_app_python_template:baseimage";
    cmd += "docker run -d -it --name " + app_id + " --log-opt max-size=10m --log-opt max-file=3 -v /home/" + QString::fromStdString(DK_VCU_USERNAME) + "/.dk/dk_vssgeneration/vehicle_gen/:/home/vss/vehicle_gen:ro -v /home/" + QString::fromStdString(DK_VCU_USERNAME) + "/.dk/dk_app_python_template/target/" + QString::fromStdString(DK_ARCH) + "/python-packages:/home/python-packages:ro --network host -v /home/" + QString::fromStdString(DK_VCU_USERNAME) + "/.dk/dk_manager/prototypes/" + app_id + ":/app/exec " + QString::fromStdString(DK_DOCKER_HUB_NAMESPACE) +"/dk_app_python_template:baseimage";
    // cmd += "python3 main.py  > main.log 2>&1 &";
    qDebug() << cmd;
    return system(cmd.toUtf8());
}

QString Dapr_Utils::daprCliList() {
    QString cmd;
    QString listcmdlogFile = this->_log_dir + "listcmd.log";

    cmd.clear();
    cmd += "dapr list > " + listcmdlogFile;
    qDebug() << cmd;
    system(cmd.toUtf8());

    QThread::msleep(10);
    QString rawDaprRunStatus = FileUtils::ReadFile(listcmdlogFile);

    qDebug() << "Result";
    qDebug() << rawDaprRunStatus;

    cmd.clear();
    cmd += "> " + listcmdlogFile;
    system(cmd.toUtf8());
    return rawDaprRunStatus;
}

int Dapr_Utils::stopAllApp() {
    qDebug() << "stop all dapr digital.auto apps and the apps based on velocitas";
    QString prototypes_file_path = this->_log_dir + "prototypes.json";
    QFile file(prototypes_file_path);
    file.open(QIODevice::ReadOnly | QIODevice::Text);
    if (file.isOpen())
    {
        QString data = QString(file.readAll());
        file.close();
        //        qDebug() << "raw file: " << data;
        QJsonArray jsonAppList = QJsonDocument::fromJson(data.toUtf8()).array();
        for (const auto obj : jsonAppList)
        {
            QString appId = obj.toObject().value("id").toString();
            std::string cmd = "dapr stop " + appId.toStdString();
            qDebug() << "dapr cmd : " << QString::fromStdString(cmd);
            std::string ret = CommonUtils::runLinuxCommand(cmd.c_str());
        }
    } else {
        return -1;
    }
    return 0;
}
