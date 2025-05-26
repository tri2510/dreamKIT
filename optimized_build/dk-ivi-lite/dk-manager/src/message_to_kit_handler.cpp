#include "message_to_kit_handler.h"
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

extern std::string DK_PROTOTYPES_FOLDER;
extern std::string DK_LOG_FOLDER;
extern std::string DK_PROTOTYPES_LIST;
extern std::string DK_VSSMAPPING_DEPLOY_CONFIG;
extern std::string DK_VSSMAPPING_DBC_CAN;
extern std::string DK_VSSMAPPING_FOLDER;
extern std::string DK_STARTKUKFEEDER_SCRIPT;
extern std::string DK_ZC_USERNAME;
extern std::string DK_STOPKUKFEEDER_SCRIPT;
extern std::string DK_VSSOVERLAY_VSPECS;
extern std::string DK_DBCDEFAULT_VALUES;
extern std::string DK_VSS_VSPECS_JSON;
extern std::string DK_SUPPORTED_VSS_FILE;
extern std::string DK_VMODEL_GEN_LOG;
extern std::string DK_VMODEL_GEN_FOLDER;
extern std::string DK_VCU_USERNAME;
extern std::string DK_CURRENT_VSS_VERSION;
extern std::string DK_VSPECS2JSON_LOG;
extern std::string DK_VSS_SPECS_FOLDER;
extern std::string DK_LOG_CMD_FOLDER;
extern std::string DK_DATABROKER_LOG;
extern std::string DK_BOARD_UNIQUE_SERIAL_NUMBER_FILE;
extern std::string DK_DREAMKIT_UNIQUE_SERIAL_NUMBER_FILE;

extern QMutex digitalAutoPrototypeMutex;
extern QMutex vssMappingMutex;
extern QMutex vssMappingFactoryResetMutex;

MessageToKitHandler::MessageToKitHandler(client *_io, message::ptr const &data, DkOrchestrator *orchestrator)
{
    m_data = data;
    m_io = _io;
    m_orchestrator = orchestrator;
    m_proto_utils = new Prototype_Utils(QString::fromStdString(DK_PROTOTYPES_FOLDER));

    QString user_name = qgetenv("USER");
    if (user_name.isEmpty())
    {
        user_name = qgetenv("USERNAME");
    }
    if (user_name.isEmpty())
    {
        user_name = "sdv";
    }

    qDebug() << "Username" << user_name;

    QString dapr_dir = "/home/" + user_name + "/.dapr/";
    m_dapr_utils = new Dapr_Utils(dapr_dir, QString::fromStdString(DK_PROTOTYPES_FOLDER), QString::fromStdString(DK_LOG_FOLDER));
}

MessageToKitHandler::~MessageToKitHandler()
{
    qDebug() << __func__ << __LINE__ << " : exit the thread !!!";
    delete m_dapr_utils;
    delete m_proto_utils;
}

void MessageToKitHandler::AraDeploymentHandler(message::ptr const &data)
{
    digitalAutoPrototypeMutex.lock();

    qDebug() << __func__ << __LINE__;

    message::ptr obj = data->get_map()["data"];

    std::string deployFrom = obj->get_map()["deployFrom"]->get_string();
    std::string id = obj->get_map()["id"]->get_string();
    std::string execType = obj->get_map()["execType"]->get_string();
    std::string appName = obj->get_map()["appName"]->get_string();
    std::string codeName = obj->get_map()["codeName"]->get_string();
    std::string codeContent = obj->get_map()["codeContent"]->get_string();
    int appContentFlag = obj->get_map()["appContent"]->get_flag();
    std::string appContent = obj->get_map()["appContent"]->get_string();
    QByteArray binContent = QString::fromStdString(appContent).toLatin1();
    bool is_run_after_deploy = obj->get_map()["run_after_deploy"]->get_bool();

    qDebug() << __func__ << __LINE__ << " id : " << QString::fromStdString(id);
    qDebug() << __func__ << __LINE__ << " execType : " << QString::fromStdString(execType);
    qDebug() << __func__ << __LINE__ << " appName : " << QString::fromStdString(appName);
    qDebug() << __func__ << __LINE__ << " codeName : " << QString::fromStdString(codeName);
    qDebug() << __func__ << __LINE__ << " appContentFlag : " << appContentFlag;
    qDebug() << __func__ << __LINE__ << " appContentSize : " << appContent.size();
    qDebug() << __func__ << __LINE__ << " binContentSize : " << binContent.size();
    qDebug() << __func__ << __LINE__ << " is_run_after_deploy : " << is_run_after_deploy;

    std::string idFolder = DK_PROTOTYPES_FOLDER + id;

    int n_write_ret = FileUtils::CreateDirIfNotExist(QString::fromStdString(idFolder));

    // write app content to executable file
    if (n_write_ret >= 0)
    {
        std::string araApp = DK_PROTOTYPES_FOLDER + id + "/" + appName;
        QFile file(QString::fromStdString(araApp));
        file.open(QIODevice::ReadWrite);
        file.resize(0);
        QThread::msleep(50);
        n_write_ret = file.write(binContent);
        file.close();
    }

    // write source code to file
    if (n_write_ret >= 0)
    {
        std::string codePath = DK_PROTOTYPES_FOLDER + id + "/" + codeName;
        n_write_ret = FileUtils::WriteFile(QString::fromStdString(codePath), QString::fromStdString(codeContent));
    }

    // Update prototypes.json
    if (n_write_ret >= 0)
    {
        n_write_ret = m_proto_utils->AppendPrototypeToList(QString::fromStdString(id), QString::fromStdString(appName),
                                                           QString::fromStdString(execType), QString::fromStdString(deployFrom));
    }

    std::string request_cmd = data->get_map()["cmd"]->get_string();
    std::string request_from = m_data->get_map()["request_from"]->get_string();
    message::ptr Obj = object_message::create();
    Obj->get_map()["request_from"] = string_message::create(request_from);
    Obj->get_map()["cmd"] = string_message::create(request_cmd);
    if (n_write_ret >= 0)
    {
        Obj->get_map()["result"] = string_message::create("success");
    }
    else
    {
        Obj->get_map()["result"] = string_message::create("failed");
    }

    m_io->socket()->emit("messageToKit-kitReply", Obj);

    std::string cmd = "chmod 777 -R " + idFolder;
    system(cmd.c_str());

    digitalAutoPrototypeMutex.unlock();
}

void MessageToKitHandler::DeploymentHandler(message::ptr const &data)
{
    digitalAutoPrototypeMutex.lock();
    std::string request_cmd = data->get_map()["cmd"]->get_string();
    std::string code = data->get_map()["code"]->get_string();
    message::ptr obj = data->get_map()["prototype"];
    std::string name = obj->get_map()["name"]->get_string();
    qDebug() << __func__ << __LINE__ << " name : " << QString::fromStdString(name);

    bool is_run_after_deploy = false;
    try
    {
        message::ptr ptr_run_after_deploy = obj->get_map()["run_after_deploy"];
        if (ptr_run_after_deploy != NULL)
        {
            is_run_after_deploy = ptr_run_after_deploy->get_bool();
        }
    }
    catch (...)
    {
    }

    std::string id = obj->get_map()["id"]->get_string();
    qDebug() << __func__ << __LINE__ << " id : " << QString::fromStdString(id);

    std::string convertedCode = "";
    int convertedCodeFlag = data->get_map()["convertedCode"]->get_flag();
    // qDebug() << __func__ << __LINE__ << " convertedCodeFlag = " << convertedCodeFlag;
    if (sio::message::flag::flag_string == convertedCodeFlag)
    {
        convertedCode = data->get_map()["convertedCode"]->get_string();
    }
    else
    {
        qDebug() << __func__ << __LINE__ << ": Your convertedCode is incorrect. Please check again !!!";

        std::string request_from = m_data->get_map()["request_from"]->get_string();
        message::ptr Obj = object_message::create();
        Obj->get_map()["request_from"] = string_message::create(request_from);
        Obj->get_map()["cmd"] = string_message::create(request_cmd);
        Obj->get_map()["result"] = string_message::create("fail");
        m_io->socket()->emit("messageToKit-kitReply", Obj);
        digitalAutoPrototypeMutex.unlock();
        return;
    }

    std::string idFolder = DK_PROTOTYPES_FOLDER + id;
    // qDebug() << __func__ << __LINE__ << " got idFolder data.";
    std::string mainPyPath = DK_PROTOTYPES_FOLDER + id + "/main.py";
    // qDebug() << __func__ << __LINE__ << " got mainPyPath data.";

    int n_write_ret = FileUtils::CreateDirIfNotExist(QString::fromStdString(idFolder));
    if (n_write_ret >= 0)
    {
        n_write_ret = FileUtils::WriteFile(QString::fromStdString(mainPyPath), QString::fromStdString(convertedCode));
    }
    if (n_write_ret >= 0)
    {
        n_write_ret = m_proto_utils->AppendPrototypeToList(QString::fromStdString(id), QString::fromStdString(name));
    }
    if (n_write_ret < 0)
    {
        std::string request_from = m_data->get_map()["request_from"]->get_string();
        message::ptr Obj = object_message::create();
        Obj->get_map()["request_from"] = string_message::create(request_from);
        Obj->get_map()["cmd"] = string_message::create(request_cmd);
        Obj->get_map()["result"] = string_message::create("fail");
        m_io->socket()->emit("messageToKit-kitReply", Obj);
        digitalAutoPrototypeMutex.unlock();
        return;
    }

    if (is_run_after_deploy)
    {
        this->m_dapr_utils->startApp(QString::fromStdString(id));
    }

    std::string request_from = m_data->get_map()["request_from"]->get_string();
    message::ptr Obj = object_message::create();
    Obj->get_map()["request_from"] = string_message::create(request_from);
    Obj->get_map()["cmd"] = string_message::create(request_cmd);
    Obj->get_map()["result"] = string_message::create("success");
    m_io->socket()->emit("messageToKit-kitReply", Obj);

    std::string cmd = "chmod 777 -R " + idFolder;
    system(cmd.c_str());
    digitalAutoPrototypeMutex.unlock();
}

void MessageToKitHandler::HandleListPrototype(message::ptr const &data)
{
    QString s_prototypes = FileUtils::ReadFile(QString::fromStdString(DK_PROTOTYPES_LIST));
    std::string request_from = data->get_map()["request_from"]->get_string();
    std::string command = data->get_map()["cmd"]->get_string();
    message::ptr Obj = object_message::create();

    QString rawDaprRunStatus = this->m_dapr_utils->daprCliList();

    Obj->get_map()["request_from"] = string_message::create(request_from);
    Obj->get_map()["cmd"] = string_message::create(command);
    Obj->get_map()["result"] = string_message::create(s_prototypes.toStdString());
    Obj->get_map()["dapr_status"] = string_message::create(rawDaprRunStatus.toStdString());
    m_io->socket()->emit("messageToKit-kitReply", Obj);
}

void MessageToKitHandler::GetSupportAPIs(message::ptr const &data)
{
    QString s_prototypes = FileUtils::ReadFile(QString::fromStdString(DK_PROTOTYPES_LIST));
    std::string request_from = data->get_map()["request_from"]->get_string();
    std::string command = data->get_map()["cmd"]->get_string();
    message::ptr Obj = object_message::create();

    QString supportAPIs = FileUtils::ReadFile(QString::fromStdString(DK_PROTOTYPES_FOLDER + "supportedvssapi.json"));

    Obj->get_map()["request_from"] = string_message::create(request_from);
    Obj->get_map()["cmd"] = string_message::create(command);
    Obj->get_map()["result"] = string_message::create(supportAPIs.toStdString());
    m_io->socket()->emit("messageToKit-kitReply", Obj);
}

void MessageToKitHandler::SetSupportAPIs(message::ptr const &data)
{
    QString s_prototypes = FileUtils::ReadFile(QString::fromStdString(DK_PROTOTYPES_LIST));
    std::string request_from = data->get_map()["request_from"]->get_string();
    std::string command = data->get_map()["cmd"]->get_string();
    std::string apis = data->get_map()["apis"]->get_string();
    message::ptr Obj = object_message::create();

    QString s_result = "fail";
    int n_write_result = FileUtils::WriteFile(QString::fromStdString(DK_PROTOTYPES_FOLDER + "supportedvssapi.json"), QString::fromStdString(apis));
    if (n_write_result >= 0)
    {
        s_result = "success";
    }

    Obj->get_map()["request_from"] = string_message::create(request_from);
    Obj->get_map()["cmd"] = string_message::create(command);
    Obj->get_map()["result"] = string_message::create(s_result.toStdString());
    m_io->socket()->emit("messageToKit-kitReply", Obj);

    // notify to all client that apis list is changed
    updateSupportedApiList2Server();
}

void MessageToKitHandler::HandleActionOnPrototype(message::ptr const &data)
{
    QString s_result = "";
    std::string request_from = data->get_map()["request_from"]->get_string();
    std::string command = data->get_map()["cmd"]->get_string();
    std::string action = data->get_map()["action"]->get_string();
    std::string proto_id = data->get_map()["prototype_id"]->get_string();
    QString s_proto_id = QString::fromStdString(proto_id);
    message::ptr Obj = object_message::create();

    qDebug() << __func__ << __LINE__ << " : action = " << QString::fromStdString(action)
             << " : s_proto_id = " << s_proto_id;

    QString cmd;
    cmd.clear();
    if (action == "start")
    {
        this->m_dapr_utils->startApp(s_proto_id);
    }
    else if (action == "stop")
    {
        this->m_dapr_utils->stopApp(s_proto_id);
    }
    else if (action == "get-log")
    {
        s_result = FileUtils::ReadFile(QString::fromStdString(DK_PROTOTYPES_FOLDER + proto_id + "/main.log"));
    }
    else if (action == "get-app-log")
    {
        s_result = FileUtils::ReadFile(QString::fromStdString(DK_PROTOTYPES_FOLDER + proto_id + "/app.log"));
    }
    else if (action == "get-python-code")
    {
        s_result = FileUtils::ReadFile(QString::fromStdString(DK_PROTOTYPES_FOLDER + proto_id + "/main.py"));
    }
    else if (action == "set-python-code")
    {
        // first try to stop app if it is running
        cmd += "dapr stop --app-id " + s_proto_id + "  &";
        system(cmd.toUtf8());
        QThread::msleep(50);

        // then write file
        std::string code = data->get_map()["code"]->get_string();
        int write_ret = FileUtils::WriteFile(QString::fromStdString(DK_PROTOTYPES_FOLDER + proto_id + "/main.py"), QString::fromStdString(code));
        if (write_ret >= 0)
        {
            s_result = "Success";
        }
        else
        {
            s_result = QString::fromStdString("Write Error " + std::to_string(write_ret));
        }
    }

    Obj->get_map()["request_from"] = string_message::create(request_from);
    Obj->get_map()["cmd"] = string_message::create(command);
    Obj->get_map()["action"] = string_message::create(action);
    Obj->get_map()["result"] = string_message::create(s_result.toStdString());
    m_io->socket()->emit("messageToKit-kitReply", Obj);
}

typedef struct
{
    QString mappingType;
    QString vss;
    QString vssType = "unknown";
    QString dataType;
    QString canSignal;
    QString canChannel;
    bool isWishlist = false;
    bool isDeleted = false;
} Vss_Mapping_Item;

typedef struct
{
    QString dbcName;
    QStringList canChannels;
} Vssmapping_Dbc_CanChannels_Struct;

bool MessageToKitHandler::VssMappingHandler(message::ptr const &data, QString &vssMappingInfo2Client)
{
    vssMappingMutex.lock();

    qDebug() << __func__ << __LINE__;
    if (data->get_flag() == message::flag_object)
    {
        message::ptr obj = data->get_map()["data"];
        std::string config = obj->get_map()["cmd"]->get_string();
        std::string payload = obj->get_map()["payload"]->get_string();
        //        qDebug() << __func__ << __LINE__ << " config : " << QString::fromStdString(config);
        //        qDebug() << __func__ << __LINE__ << " payload : " << QString::fromStdString(payload);

        QList<Vssmapping_Dbc_CanChannels_Struct> dbcCanList;
        dbcCanList.clear();
        {
            // init dbcCanList
            QFile file(QString::fromStdString(DK_VSSMAPPING_DBC_CAN));
            file.open(QIODevice::ReadOnly | QIODevice::Text);
            if (file.isOpen())
            {
                QString data = QString(file.readAll());
                file.close();
                //        qDebug() << "raw file: " << data;
                QJsonArray list = QJsonDocument::fromJson(data.toUtf8()).array();
                qDebug() << "init dbcCanList: " << list;
                for (const auto obj : list)
                {
                    Vssmapping_Dbc_CanChannels_Struct dbcCanItem;
                    dbcCanItem.dbcName = obj.toObject().value("dbcName").toString();
                    QJsonArray mappingList = obj.toObject().value("canChannels").toArray();
                    for (int i = 0; i < mappingList.count(); i++)
                    {
                        dbcCanItem.canChannels.append(mappingList[i].toString());
                    }
                    dbcCanList.append(dbcCanItem);
                }
            }
        }

        {
            // save vss mapping configuration
            QFile file(QString::fromStdString(DK_VSSMAPPING_DEPLOY_CONFIG));
            if (!file.open(QIODevice::ReadWrite | QIODevice::Text))
            {
                qDebug() << __func__ << __LINE__ << file.errorString();
                vssMappingInfo2Client += "Failed to open vss mapping configuration file.\n";
                vssMappingMutex.unlock();
                return false;
            }
            file.resize(0);
            QTextStream stream(&file);
            stream << QString::fromStdString(config);
            QThread::msleep(50);
            file.flush();
            file.close();
            QThread::msleep(50);
        }

        QList<Vss_Mapping_Item> mappingItems;
        mappingItems.clear();

        // Read vss mapping configuration
        std::string dbcFileName = "vehicle_default.dbc";
        {
            QFile vssmappingFile(QString::fromStdString(DK_VSSMAPPING_DEPLOY_CONFIG));
            vssmappingFile.open(QIODevice::ReadOnly | QIODevice::Text);
            if (vssmappingFile.isOpen())
            {
                QString data = QString(vssmappingFile.readAll());
                //                qDebug() << "vssmapping: " << data;
                QJsonDocument doc = QJsonDocument::fromJson(data.toUtf8());
                QJsonObject obj = doc.object();
                QString ecuName = obj.value("ecuName").toString();
                QString aliveMessageID = obj.value("aliveMessageID").toString();
                QString dbcFilename_ = obj.value("dbcFilename").toString();
                dbcFilename_.replace(' ', "_");
                dbcFileName.clear();
                dbcFileName = dbcFilename_.toStdString();
                qDebug() << "ecuName: " << ecuName;
                qDebug() << "aliveMessageID: " << aliveMessageID;
                qDebug() << "dbcFilename: " << dbcFilename_;

                QJsonArray mappingList = obj.value("mappingItems").toArray();
                for (int i = 0; i < mappingList.count(); i++)
                {
                    QJsonObject obj = mappingList[i].toObject();

                    Vss_Mapping_Item item;
                    item.vss = obj.value("vss").toString();
                    item.mappingType = obj.value("mappingType").toString();
                    if (item.mappingType == "dbc2vss")
                    {
                        item.mappingType = "dbc"; // this is for vss3.0
                        item.vssType = "sensor";
                    }
                    else if (item.mappingType == "vss2dbc")
                    {
                        item.vssType = "actuator";
                    }
                    else
                    {
                        item.vssType = "unknown";
                    }
                    item.canSignal = obj.value("canSignal").toString();
                    item.canChannel = obj.value("canChannel").toString();
                    item.dataType = obj.value("dataType").toString();
                    if (item.dataType == "")
                    {
                        item.dataType = "boolean";
                    }
                    item.isWishlist = obj.value("isWishlist").toBool();
                    item.isDeleted = obj.value("isDeleted").toBool();
                    mappingItems.append(item);

                    qDebug() << "vss: " << item.vss;
                    qDebug() << "mappingType: " << item.mappingType;
                    qDebug() << "canSignal: " << item.canSignal;
                    qDebug() << "canChannel: " << item.canChannel;
                    qDebug() << "dataType: " << item.dataType;
                    qDebug() << "isWishlist: " << item.isWishlist;
                    qDebug() << "isDeleted: " << item.isDeleted;
                }
            }
            vssmappingFile.close();
        }

        // save dbc file
        std::string dbcFile = DK_VSSMAPPING_FOLDER + dbcFileName;
        {
            QFile file(QString::fromStdString(dbcFile));
            if (!file.open(QIODevice::ReadWrite | QIODevice::Text))
            {
                qDebug() << __func__ << __LINE__ << file.errorString();
                vssMappingInfo2Client += "Failed to save dbc file.\n";
                vssMappingMutex.unlock();
                return false;
            }
            file.resize(0);
            QTextStream stream(&file);
            stream << QString::fromStdString(payload);
            QThread::msleep(50);
            file.flush();
            file.close();
        }

        //////////////////////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////// the deployment of new mapping //////////////////////////////////////
        QStringList addedVssMappingList;
        addedVssMappingList.clear();

        QStringList deleteVssMappingList;
        deleteVssMappingList.clear();

        {
            // update dbc_overlay file. dbc_overlay helps to manager the number of actual CAN Signals which are used in the system.
            QFile file(QString::fromStdString(DK_VSSOVERLAY_VSPECS));
            if (!file.open(QIODevice::ReadWrite | QIODevice::Text))
            {
                qDebug() << __func__ << __LINE__ << file.errorString();
                vssMappingInfo2Client += "Failed to open vss overlay file.\n";
                vssMappingMutex.unlock();
                return false;
            }

            QTextStream stream(&file);
            for (int i = 0; i < mappingItems.count(); i++)
            {
                stream.seek(0);
                QString overlayContent = stream.readAll(); // readAll shall set the cursor to end of file.
                stream.seek(0);
                Vss_Mapping_Item item = mappingItems[i];

                bool isMappingValid = false;

                if (overlayContent.contains(item.vss, Qt::CaseSensitivity::CaseSensitive))
                {
                    // update/delete existing vss mapping
                    //                    qDebug() << __func__ << __LINE__ << ": update/delete existing vss mapping";
                    QString s;
                    while (!stream.atEnd())
                    {
                        QString line = stream.readLine();
                        if (line.contains(item.vss, Qt::CaseSensitivity::CaseSensitive))
                        {
                            if (item.isDeleted == true)
                            {
                                qDebug() << __func__ << __LINE__ << ": delete existing vss mapping: " << item.vss;
                                // delete this mapping
                                stream.readLine();                      // discard datatype
                                stream.readLine();                      // discard vssType
                                stream.readLine();                      // discard description
                                stream.readLine();                      // discard mappingType
                                QString _canSignal = stream.readLine(); // discard canSignal
                                if (_canSignal == "")
                                {
                                    qDebug() << __func__ << __LINE__ << " : delete NONE-dbc-mapping API ---------";
                                    // if _canSignal is empty, then there is no canSignal lines
                                    // s.append("\n");
                                }
                                else
                                {
                                    qDebug() << __func__ << __LINE__ << " : delete dbc-mapping API ---------";
                                    stream.readLine(); // discard "\n"
                                }

                                deleteVssMappingList.append(item.vss);
                            }
                            else
                            {
                                qDebug() << __func__ << __LINE__ << ": update existing vss mapping: " << item.vss;
                                // update this mapping
                                s.append(line + "\n");                  // keep vss api
                                stream.readLine();                      // discard datatype
                                stream.readLine();                      // discard vssType
                                stream.readLine();                      // discard description
                                stream.readLine();                      // discard mappingType
                                QString _canSignal = stream.readLine(); // discard canSignal
                                if ((_canSignal == "") && (item.canSignal == ""))
                                {
                                    qDebug() << __func__ << __LINE__ << " : update dbc-mapping API --------- N-N";
                                    s.append("  datatype: " + item.dataType + "\n"); // update datatype
                                    s.append("  type: " + item.vssType + "\n");      // update vssType
                                    s.append("  description: T.B.D\n");              // update description
                                    s.append("  " + item.mappingType + ":\n");       // update mappingType
                                    s.append("\n");
                                }
                                else if ((_canSignal == "") && (item.canSignal != ""))
                                {
                                    qDebug() << __func__ << __LINE__ << " : update dbc-mapping API --------- N-Y";
                                    s.append("  datatype: " + item.dataType + "\n");  // update datatype
                                    s.append("  type: " + item.vssType + "\n");       // update vssType
                                    s.append("  description: T.B.D\n");               // update description
                                    s.append("  " + item.mappingType + ":\n");        // update mappingType
                                    s.append("    signal: " + item.canSignal + "\n"); // update canSignal
                                    s.append("\n");
                                }
                                else if ((_canSignal != "") && (item.canSignal == ""))
                                {
                                    qDebug() << __func__ << __LINE__ << " : update dbc-mapping API --------- Y-N";
                                    s.append("  datatype: " + item.dataType + "\n"); // update datatype
                                    s.append("  type: " + item.vssType + "\n");      // update vssType
                                    s.append("  description: T.B.D\n");              // update description
                                    s.append("  " + item.mappingType + ":\n");       // update mappingType
                                }
                                else if ((_canSignal != "") && (item.canSignal != ""))
                                {
                                    qDebug() << __func__ << __LINE__ << " : update dbc-mapping API --------- Y-Y";
                                    s.append("  datatype: " + item.dataType + "\n");  // update datatype
                                    s.append("  type: " + item.vssType + "\n");       // update vssType
                                    s.append("  description: T.B.D\n");               // update description
                                    s.append("  " + item.mappingType + ":\n");        // update mappingType
                                    s.append("    signal: " + item.canSignal + "\n"); // update canSignal
                                }
                            }
                            continue;
                        }
                        s.append(line + "\n");
                    }
                    file.resize(0);
                    stream << s;

                    isMappingValid = true;
                }
                else
                {
                    if (item.isDeleted == true)
                    {
                        qDebug() << __func__ << __LINE__ << ": can't delete not-mapped vss.";
                        continue;
                    }

                    while (!stream.atEnd())
                    {
                        QString line = stream.readLine();
                        //                        qDebug() << "till the end: " << line;
                    }
                    // create new vss mapping
                    qDebug() << __func__ << __LINE__ << ": create new vss mapping";
                    // add missing branches. It is only for vss3.0, vss4.0 doesn't need it.
                    QStringList vssBranches = item.vss.split('.');
                    if (vssBranches.size())
                        vssBranches.removeLast();
                    int branchCount = vssBranches.size();
                    if (branchCount)
                    {
                        for (int j = 0; j < branchCount; j++)
                        {
                            QString branch;
                            branch.clear();
                            for (int k = 0; k <= j; k++)
                            {
                                branch += vssBranches[k];
                                if (k < j)
                                {
                                    branch += ".";
                                }
                            }
                            branch += ":\n";
                            branch += "  type: branch\n";
                            branch += "  description: T.B.D\n\n";
                            qDebug() << "branch: " << branch;
                            if (!overlayContent.contains(branch, Qt::CaseSensitivity::CaseSensitive))
                            {
                                stream << branch;
                            }
                        }
                    }

                    // add new vss mapping
                    QString newMapping;
                    newMapping.clear();
                    newMapping = item.vss + ":\n";
                    newMapping += "  datatype: " + item.dataType + "\n";
                    newMapping += "  type: " + item.vssType + "\n";
                    newMapping += "  description: T.B.D\n";
                    newMapping += "  " + item.mappingType + ":\n";
                    if (item.canSignal != "")
                    {
                        newMapping += "    signal: " + item.canSignal + "\n";
                    }
                    newMapping += "\n";
                    stream << newMapping;

                    addedVssMappingList.append(item.vss);

                    isMappingValid = true;
                }

                // update dbc_default_values.json
                if (isMappingValid)
                {
                    qDebug() << __func__ << __LINE__ << ": update dbc_default_values";
                    // update dbcCanList
                    if (item.canSignal == "")
                    {
                        // signal empty means that just add the vss to supported List.
                        // so don't need to update dbcCanList and CAN default values.
                        continue;
                    }

                    {
                        int count = dbcCanList.size();
                        bool foundDbcName = false;
                        for (int i = 0; i < count; i++)
                        {
                            bool foundCanChanel = false;
                            if (dbcCanList[i].dbcName == QString::fromStdString(dbcFileName))
                            {
                                for (int j = 0; j < dbcCanList[i].canChannels.size(); j++)
                                {
                                    if (dbcCanList[i].canChannels[j] == item.canChannel)
                                    {
                                        foundCanChanel = true;
                                        break;
                                    }
                                }
                                if (!foundCanChanel)
                                {
                                    dbcCanList[i].canChannels.append(item.canChannel);
                                }
                                foundDbcName = true;
                                break;
                            }
                        }
                        if (!foundDbcName)
                        {
                            Vssmapping_Dbc_CanChannels_Struct dbcCanItem;
                            dbcCanItem.dbcName = QString::fromStdString(dbcFileName);
                            dbcCanItem.canChannels.append(item.canChannel);
                            dbcCanList.append(dbcCanItem);
                        }
                    }

                    // parse dbc file to look for the all the signals in the frame.
                    QFile dbc(QString::fromStdString(dbcFile));
                    if (!dbc.open(QIODevice::ReadWrite | QIODevice::Text))
                    {
                        qDebug() << __func__ << __LINE__ << dbc.errorString();
                        vssMappingInfo2Client += "Failed to open dbc default values file.\n";
                        vssMappingMutex.unlock();
                        return false;
                    }
                    QTextStream dbcStream(&dbc);
                    QStringList dbclines;
                    QStringList allRelatedSignals;
                    while (!dbcStream.atEnd())
                    {
                        QString line = dbcStream.readLine();
                        dbclines.append(line);
                        if (line.contains(item.canSignal, Qt::CaseSensitivity::CaseSensitive))
                        {
                            // found the signal location
                            int lineMax = dbclines.size() - 1;
                            int startLine = 0;
                            for (int i = lineMax; i >= 0; i--)
                            {
                                if (dbclines[i].at(0) != ' ')
                                {
                                    // found the message ID line
                                    QStringList msgDbcLine = dbclines[i].split(' ');
                                    //                                    qDebug() << __func__ << __LINE__ << " : msgDbcLine : " << msgDbcLine;
                                    startLine = i;
                                    // append from the CAN msg line postition to the line of mapping singal
                                    for (int j = (startLine + 1); j < dbclines.size(); j++)
                                    {
                                        QStringList signalDbcLine = dbclines[j].split(' ');
                                        //                                        qDebug() << __func__ << __LINE__ << " : canDbcLine append: " << signalDbcLine;
                                        allRelatedSignals.append(signalDbcLine[2]);
                                    }
                                    break;
                                }
                            }
                            break;
                        }
                    }
                    // append from the line of mapping singal to the rest of signals of CAN msg.
                    while (!dbcStream.atEnd())
                    {
                        QString line = dbcStream.readLine();
                        if (line.isEmpty() || (line == "\n"))
                        {
                            break;
                        }
                        QStringList signalDbcLine = line.split(' ');
                        //                        qDebug() << __func__ << __LINE__ << " : canDbcLine append: " << signalDbcLine;
                        allRelatedSignals.append(signalDbcLine[2]);
                    }
                    qDebug() << __func__ << __LINE__ << " : allRelatedSignals : " << allRelatedSignals;

                    // update DK_DBCDEFAULT_VALUES
                    QFile file1(QString::fromStdString(DK_DBCDEFAULT_VALUES));
                    file1.open(QIODevice::ReadWrite | QIODevice::Text);
                    if (file1.isOpen())
                    {
                        QString data = QString(file1.readAll());
                        QJsonDocument doc = QJsonDocument::fromJson(data.toUtf8());
                        QJsonObject root = doc.object();
                        for (int i = 0; i < allRelatedSignals.size(); i++)
                        {
                            if (!data.contains(allRelatedSignals[i], Qt::CaseSensitivity::CaseSensitive))
                            {
                                root[allRelatedSignals[i]] = 0;
                            }
                        }
                        //                        qDebug() << "after append: signalList: " << root;
                        QJsonDocument newDoc(root);
                        file1.resize(0);
                        file1.write(newDoc.toJson());
                    }

                    dbc.close();
                }
            }

            QThread::msleep(50);
            file.flush();
            file.close();
            system("sync");
            QThread::msleep(50);
        }

        // Create vss.json based on the overlay
        if (!GenerateVssJson(vssMappingInfo2Client))
        {
            vssMappingMutex.unlock();
            return false;
        }

        // Create vehicle model
        if (!GenerateVehicleModel(vssMappingInfo2Client))
        {
            vssMappingMutex.unlock();
            return false;
        }

        // create content for DK_STOPKUKFEEDER_SCRIPT and DK_STARTKUKFEEDER_SCRIPT
        {
            qDebug() << "create content for DK_STOPKUKFEEDER_SCRIPT and DK_STARTKUKFEEDER_SCRIPT";
            {
                // create content for DK_STOPKUKFEEDER_SCRIPT
                std::string cmd = "> " + DK_STOPKUKFEEDER_SCRIPT + ";";
                cmd += "echo \"pkill -f 'python3 dbcfeeder.py'\" > " + DK_STOPKUKFEEDER_SCRIPT;
                std::string ret = CommonUtils::runLinuxCommand(cmd.c_str());
            }
#if 1
            {
                // update dbcCanList json file
                {
                    qDebug() << "update dbcCanList json file";
                    QFile file1(QString::fromStdString(DK_VSSMAPPING_DBC_CAN));
                    file1.open(QIODevice::ReadWrite | QIODevice::Text);
                    if (file1.isOpen())
                    {
                        QString data = QString(file1.readAll());
                        QJsonDocument doc = QJsonDocument::fromJson(data.toUtf8());
                        QJsonArray list;
                        for (int i = 0; i < dbcCanList.size(); i++)
                        {
                            QJsonObject obj;
                            obj["dbcName"] = dbcCanList[i].dbcName;
                            obj["canChannels"] = QJsonArray::fromStringList(dbcCanList[i].canChannels);
                            QJsonValue value(obj);
                            list.append(value);
                        }
                        qDebug() << "after append: jsonAppList: " << list;

                        QJsonDocument newDoc(list);
                        //        qDebug() << "after: \n" << newDoc;
                        file1.resize(0);
                        file1.write(newDoc.toJson());

                        QThread::msleep(50);
                        file1.flush();
                        file1.close();
                    }
                }

                // create content for DK_STARTKUKFEEDER_SCRIPT
                std::string cmd = "> " + DK_STARTKUKFEEDER_SCRIPT + ";";
                std::string ret = CommonUtils::runLinuxCommand(cmd.c_str());
                cmd.clear();

                std::string kuksaFeederPath = "/usr/bin/dreamkit/kuksa/kuksa.val.feeders/dbc2val";
                std::string content = "cd " + kuksaFeederPath + "\n";
                for (int i = 0; i < dbcCanList.count(); i++)
                {
                    for (int j = 0; j < dbcCanList[i].canChannels.count(); j++)
                    {
                        std::string dbcName_ = dbcCanList[i].dbcName.toStdString();
                        std::string logpath = DK_VSSMAPPING_FOLDER + "dbcfeeder_" + dbcName_ + "_" + dbcCanList[i].canChannels[j].toStdString() + ".log";
                        content += "> " + logpath + "\n"; // clear old log file
                        content += "sudo -u " + DK_ZC_USERNAME;
#ifdef DREAMKIT_MINI
                        content += " PYTHONPATH=$PYTHONPATH:/usr/bin/dreamkit/kuksa/kuksa.val.feeders/py-kuksa-val-feeders-env/lib/python3.11/site-packages/ ";
#endif
                        content += " python3 dbcfeeder.py --val2dbc --dbc2val --use-socketcan ";
                        content += " --canport " + dbcCanList[i].canChannels[j].toStdString();
                        content += " --dbcfile " + DK_VSSMAPPING_FOLDER + dbcName_ + " ";
                        content += " --dbc-default " + DK_DBCDEFAULT_VALUES + " ";
                        content += " --mapping " + DK_VSS_VSPECS_JSON + " ";
                        content += " > " + logpath;
                        content += " 2>&1 &\n";
                    }
                }

                // write content to a file
                cmd += "echo '" + content + "' > " + DK_STARTKUKFEEDER_SCRIPT;
                qDebug() << "kuksa-feeder DK_STARTKUKFEEDER_SCRIPT : " << QString::fromStdString(content);
                ret = CommonUtils::runLinuxCommand(cmd.c_str());
            }
#endif
        }

        // restart runtime environment
        // s1: stop all dapr digital.auto apps and the apps based on velocitas
        // s2: stop vehicledatabroker on vcu
        // s3: Send cmd to stop kuksa-feeder on zonecontroller
        StopRuntimeEnv();

        // s4: update EcuList.json
        {
            // Warning: Need to double-check with the mechanism from ivi to get diagnostic info.
            // DK_ECU_LIST
        }

        // s4.1: update vss.json, dbc file, EcuList.json
        // related signal defaul values of the same CAN fream in dbc_default_values.json,
        // and kuksa-feeder startup/stop script on zonecontroller (can start TWO kuksa-feeder for 2 CAN channels)
        {
            qDebug() << "update artifacts for zone controller";
#if 0
            // NOTE: ONLY use this just in case there is NO socket.so-client on the destination

            std::string vssMappingFolderOnZoneController = DK_VSSMAPPING_FOLDER;
            qDebug() << "update artifacts for zone controller";
            // TODO: need to send file through the socket programming to make the SW moduler .
            // NOT recommend to use scp, since it shall depend on the user password.
            std::string cmd = "sshpass -p 123456 scp -r " + DK_VSS_VSPECS_JSON + " bluebox@192.168.56.49:" + vssMappingFolderOnZoneController + ";";
            cmd += "sshpass -p 123456 scp -r " + dbcFile + " bluebox@192.168.56.49:" + vssMappingFolderOnZoneController + ";";
            cmd += "sshpass -p 123456 scp -r " + DK_DBCDEFAULT_VALUES + " bluebox@192.168.56.49:" + vssMappingFolderOnZoneController + ";";
            cmd += "sshpass -p 123456 scp -r " + DK_STOPKUKFEEDER_SCRIPT + " bluebox@192.168.56.49:" + vssMappingFolderOnZoneController + ";";
            cmd += "sshpass -p 123456 scp -r " + DK_STARTKUKFEEDER_SCRIPT + " bluebox@192.168.56.49:" + vssMappingFolderOnZoneController + ";";
            qDebug() << "copy cmd : " << QString::fromStdString(cmd);
            system(cmd.c_str());
#else
            if (m_orchestrator)
            {
                qDebug() << "update artifacts for zone controller: m_orchestrator is available";
                // send file to zonecontroller
                m_orchestrator->SendFile("zonecontroller", DK_VSS_VSPECS_JSON);
                m_orchestrator->SendFile("zonecontroller", dbcFile);
                m_orchestrator->SendFile("zonecontroller", DK_DBCDEFAULT_VALUES);
                m_orchestrator->SendFile("zonecontroller", DK_STOPKUKFEEDER_SCRIPT);
                m_orchestrator->SendFile("zonecontroller", DK_STARTKUKFEEDER_SCRIPT);
                QThread::sleep(2);
            }
            else
            {
                vssMappingInfo2Client += "Send file to kuksa-feeder failed. orchestrator is not working.\n";
                qDebug() << "Send file to kuksa-feeder failed. orchestrator is not working.";
            }
#endif
        }

        // start vehicle runtime
        // s5: start vehicledatabroker on vcu
        // s6: Send cmd to start kuksa-feeder startup script on zonecontroller
        StartRunTimeEnv();

        // s7: update std::string DK_SUPPORTED_VSS_FILE = (DK_PROTOTYPES_FOLDER + "supportedvssapi.json");
        {
            QFile file1(QString::fromStdString(DK_SUPPORTED_VSS_FILE));
            file1.open(QIODevice::ReadWrite | QIODevice::Text);
            if (file1.isOpen())
            {
                QString data = QString(file1.readAll());
                QJsonDocument doc = QJsonDocument::fromJson(data.toUtf8());
                QJsonArray jsonArray = doc.array();
                //                qDebug() << __func__ << __LINE__ <<  " - jsonArray DK_SUPPORTED_VSS_FILE : " << jsonArray;

                // add new vss mapping to supported list
                for (int i = 0; i < addedVssMappingList.size(); i++)
                {
                    if (!data.contains(addedVssMappingList[i]))
                    {
                        jsonArray.append(addedVssMappingList[i]);
                        qDebug() << __func__ << __LINE__ << " - append DK_SUPPORTED_VSS_FILE : " << addedVssMappingList[i];
                    }
                }

                // remove deleted vss mapping from supported list
                for (int i = 0; i < deleteVssMappingList.size(); i++)
                {
                    for (int j = 0; j < jsonArray.count(); j++)
                    {
                        if (jsonArray[j].toString() == deleteVssMappingList[i])
                        {
                            jsonArray.removeAt(j);
                            qDebug() << __func__ << __LINE__ << " - remove DK_SUPPORTED_VSS_FILE : " << deleteVssMappingList[i];
                            break;
                        }
                    }
                }
                //                qDebug() << __func__ << __LINE__ <<  " - after append DK_SUPPORTED_VSS_FILE : " << jsonArray;
                QJsonDocument newDoc(jsonArray);
                file1.resize(0);
                file1.write(newDoc.toJson());
            }
            file1.flush();
            file1.close();
        }

        // note: during the deployment of new mapping, if there is any error at any step, the system shall report to web client -> done
    }

    vssMappingInfo2Client += "Vss Mapping is deployed successfully !!!\n";

    qDebug() << "Vss Mapping is deployed successfully !!!";

    // make sure data is written to files.
    system("sync");
    QThread::msleep(50);

    vssMappingMutex.unlock();
    return true;
}

bool MessageToKitHandler::GenerateVehicleModel(QString &vssMappingInfo2Client)
{
    std::string cmd = "> " + DK_VMODEL_GEN_LOG + ";";
    cmd += "cd " + DK_VMODEL_GEN_FOLDER + ";";

    std::string python_version_for_model_gen = "python";
    if (system("which python3.9 > /dev/null 2>&1"))
    {
        // Command doesn't exist...
        python_version_for_model_gen = "python";
    }
    else
    {
        // Command does exist, do something with it...
        python_version_for_model_gen = "python3.9";
    }

    cmd += "sudo -u " + DK_VCU_USERNAME + " " + python_version_for_model_gen + " gen_vehicle_model.py -I " + DK_VSS_SPECS_FOLDER + DK_CURRENT_VSS_VERSION + "/vehicle_signal_specification/spec/ " + DK_VSS_VSPECS_JSON + " > " + DK_VMODEL_GEN_LOG;
    //cmd += "sudo -u " + DK_VCU_USERNAME + " python3.9 gen_vehicle_model.py -I " + DK_VSS_SPECS_FOLDER + DK_CURRENT_VSS_VERSION + "/vehicle_signal_specification/spec/ " + DK_VSS_VSPECS_JSON + " > " + DK_VMODEL_GEN_LOG;
    qDebug() << "vehicle gen command: " << QString::fromStdString(cmd);
    std::string ret = CommonUtils::runLinuxCommand(cmd.c_str());

    QString output;
    QFile outputFile(QString::fromStdString(DK_VMODEL_GEN_LOG));
    if (outputFile.open(QIODevice::ReadOnly))
    {
        QTextStream outputStream(&outputFile);
        output = outputStream.readAll();
        outputFile.close();
    }

    if (!output.contains("All done"))
    {
        vssMappingInfo2Client += "Failed to generate vehicle model\n";
        vssMappingInfo2Client += output + "\n";
        qDebug() << "generate vehicle model failed: " << output;
        return false;
    }
    else
    {
        qDebug() << "generate vehicle model OK: " << output;
    }

    // make link to the lib folder
    {
        std::string cmd = "ln -s /home/" + DK_VCU_USERNAME + "/.local/lib/python3.8/site-packages/sdv /home/" + DK_VCU_USERNAME + "/.local/lib/python3.8/site-packages/velocitas_sdk";
        qDebug() << "make link to the lib folder cmd : " << QString::fromStdString(cmd);
        std::string ret = CommonUtils::runLinuxCommand(cmd.c_str());
        qDebug() << "link sdv sdk ret : " << QString::fromStdString(ret);

        cmd.clear();
        ret.clear();

        cmd = "ln -s " + DK_VMODEL_GEN_FOLDER + "gen_model/vehicle " + "/home/" + DK_VCU_USERNAME + "/.local/lib/python3.8/site-packages/";
        qDebug() << "make link to the lib folder cmd : " << QString::fromStdString(cmd);
        ret = CommonUtils::runLinuxCommand(cmd.c_str());
        qDebug() << "link new vehicle model ret : " << QString::fromStdString(ret);
    }

    return true;
}

bool MessageToKitHandler::GenerateVssJson(QString &vssMappingInfo2Client)
{
    std::string cmd = "> " + DK_VSPECS2JSON_LOG + ";";
    cmd += "sudo -u " + DK_VCU_USERNAME + " " + DK_VSS_SPECS_FOLDER + DK_CURRENT_VSS_VERSION + "/vehicle_signal_specification/vss-tools/vspec2json.py -e vss2dbc,dbc2vss,dbc -o " + DK_VSSOVERLAY_VSPECS + " --json-pretty " + DK_VSS_SPECS_FOLDER + DK_CURRENT_VSS_VERSION + "/vehicle_signal_specification/spec/VehicleSignalSpecification.vspec " + DK_VSS_VSPECS_JSON + " > " + DK_VSPECS2JSON_LOG + " 2>&1";
    qDebug() << "vss gen command: " << QString::fromStdString(cmd);
    std::string ret = CommonUtils::runLinuxCommand(cmd.c_str());

    QString output;
    QFile outputFile(QString::fromStdString(DK_VSPECS2JSON_LOG));
    if (outputFile.open(QIODevice::ReadOnly))
    {
        QTextStream outputStream(&outputFile);
        output = outputStream.readAll();
        outputFile.close();
    }

    if (!output.contains("All done"))
    {
        vssMappingInfo2Client += "Failed to generate vss.json\n";
        vssMappingInfo2Client += output + "\n";
        qDebug() << "generate vss json failed: " << output;
        return false;
    }
    else
    {
        qDebug() << "Create vss.json OK: " << output;
    }
    return true;
}

void MessageToKitHandler::StartRunTimeEnv()
{
    StartVehicleDatabroker();
    StartKuksaFeeder();
}

void MessageToKitHandler::StartVehicleDatabroker()
{
    qDebug() << "start vehicledatabroker on vcu";
    std::string cmd = "> " + DK_DATABROKER_LOG + ";";
    // cmd += "sudo -u " + DK_VCU_USERNAME + " dapr run --app-id vehicledatabroker --app-protocol grpc --resources-path /home/" + DK_VCU_USERNAME + "/.dapr/components --config /home/" + DK_VCU_USERNAME + "/.dapr/config.yaml --app-port 6111 -- docker run --rm --init --name vehicledatabroker -e KUKSA_DATA_BROKER_METADATA_FILE=" + DK_VSS_VSPECS_JSON + " -e KUKSA_DATA_BROKER_PORT=6111 -e 50001 -e 3500 -v " + DK_VSS_VSPECS_JSON + ":" + DK_VSS_VSPECS_JSON + " --network host ghcr.io/eclipse/kuksa.val/databroker:0.3.0 > ";
    cmd += "sudo -u " + DK_VCU_USERNAME + " dapr run --app-id vehicledatabroker --app-protocol grpc --resources-path /home/" + DK_VCU_USERNAME + "/.dapr/components --config /home/" + DK_VCU_USERNAME + "/.dapr/config.yaml --app-port 55555 -- docker run --rm --init --name vehicledatabroker -e KUKSA_DATA_BROKER_METADATA_FILE=" + DK_VSS_VSPECS_JSON + " -e KUKSA_DATA_BROKER_PORT=55555 -e 50001 -e 3500 -v " + DK_VSS_VSPECS_JSON + ":" + DK_VSS_VSPECS_JSON + " --network host ghcr.io/eclipse/kuksa.val/databroker:0.3.0 > ";
    cmd += DK_DATABROKER_LOG + " 2>&1 &";
    qDebug() << "vehicledatabroker cmd : " << QString::fromStdString(cmd);
    system(cmd.c_str());
    QThread::sleep(3);
}

void MessageToKitHandler::StartKuksaFeeder()
{
#if 1
    if (m_orchestrator)
    {
        // check vehicledatabroker status before start kuksa feeder
        std::string cmd = "docker inspect --format '{{json .State.Running}}' vehicledatabroker";
        std::string ret = CommonUtils::runLinuxCommand(cmd.c_str());
        QString databrokerStatus = QString::fromStdString(ret);
        databrokerStatus.remove(QChar::Null);
        databrokerStatus.replace("\n", "");
        qDebug() << "------ vehicledatabroker status : " << databrokerStatus;
        if (databrokerStatus == "true")
        {
            qDebug() << "------ Send cmd to start kuksa-feeder startup script on zonecontroller";
            m_orchestrator->SendCmd("zonecontroller", "start_kuksa_feeder_script");
        }
    }
#ifdef DREAMKIT_MINI
    else
    {
        qDebug() << __func__ << __LINE__ << ": start_kuksa_feeder_script ret : " << 
        QString::fromStdString(CommonUtils::runLinuxCommand(DK_STARTKUKFEEDER_SCRIPT.c_str()));
    }
#endif
#else
    // This is for the testing on VCU.
    std::string ret = runLinuxCommand(DK_STARTKUKFEEDER_SCRIPT.c_str());
    std::cout << __func__ << __LINE__ << ": start_kuksa_feeder_script ret : " << ret << "\n";
#endif
}

void MessageToKitHandler::StopRuntimeEnv()
{
    StopAllDigialAutoApps();
    StopVehicleDatabroker();
    StopKuksaFeeder();
    QThread::sleep(1);
}

void MessageToKitHandler::StopAllDigialAutoApps()
{
    // TODO
    qDebug() << "stop all dapr digital.auto apps and the apps based on velocitas";
    QFile file(QString::fromStdString(DK_PROTOTYPES_LIST));
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
    }
}

void MessageToKitHandler::StopVehicleDatabroker()
{
    qDebug() << "stop vehicledatabroker on vcu";
    CommonUtils::runLinuxCommand("docker stop vehicledatabroker");
    QThread::sleep(2);
    CommonUtils::runLinuxCommand("dapr stop vehicledatabroker");
    QThread::sleep(2);
}

void MessageToKitHandler::StopKuksaFeeder()
{
#if 1
    if (m_orchestrator)
    {
        qDebug() << "Send cmd to stop kuksa-feeder on zonecontroller";
        // send command to zonecontroller
        m_orchestrator->SendCmd("zonecontroller", "stop_kuksa_feeder_script");
    }
#ifdef DREAMKIT_MINI
    else {
        qDebug() << __func__ << __LINE__ << ": stop_kuksa_feeder_script ret : " << 
        QString::fromStdString(CommonUtils::runLinuxCommand(DK_STOPKUKFEEDER_SCRIPT.c_str()));
    }
#endif
#else
    // This is for the testing on VCU.
    {
        std::string ret = runLinuxCommand(DK_STOPKUKFEEDER_SCRIPT.c_str());
        std::cout << __func__ << __LINE__ << ": stop_kuksa_feeder_script ret : " << ret << "\n";
    }
#endif
}

void MessageToKitHandler::ExecuteCmd(message::ptr const &data)
{
    qDebug() << __func__ << __LINE__;
    if (data->get_flag() == message::flag_object)
    {
        message::ptr obj = data->get_map()["data"];
        std::string command = obj->get_map()["cmd"]->get_string();
        qDebug() << __func__ << __LINE__ << " command : " << QString::fromStdString(command);

        QString hashinput = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss") + QString::fromStdString(command);
        QString hash = QString::number(CommonUtils::dk_hash(hashinput));
        qDebug() << __func__ << __LINE__ << " hash : " << hash;

        std::string logFile = DK_LOG_CMD_FOLDER + hash.toStdString();

        std::string cmd;
        cmd.clear();
        cmd = "> " + logFile;
        system(cmd.data()); // clear old log,

        cmd.clear();
        cmd = command + " > " + logFile + " 2>&1"; // append cmd to get cmd log into a file
        qDebug() << __func__ << " message = " << QString::fromStdString(cmd);
        system(cmd.data());

        QString output;
        QFile outputFile(QString::fromStdString(logFile));
        if (!outputFile.open(QIODevice::ReadOnly))
        {
            qDebug() << __func__ << __LINE__ << outputFile.errorString();
        }
        else
        {
            QTextStream outputStream(&outputFile);
            output = outputStream.readAll();
            outputFile.close();
        }

        std::string request_from = data->get_map()["request_from"]->get_string();
        message::ptr Obj = object_message::create();
        Obj->get_map()["request_from"] = string_message::create(request_from);
        Obj->get_map()["cmd"] = string_message::create(command);
        Obj->get_map()["result"] = string_message::create(output.toStdString());
        m_io->socket()->emit("messageToKit-kitReply", Obj);
    }
}

void MessageToKitHandler::FactoryResetHandler(message::ptr const &data)
{
    qDebug() << __func__ << __LINE__;
}

bool MessageToKitHandler::VssMappingFactoryResetHandler(message::ptr const &data, QString &vssMappingInfo2Client)
{
    vssMappingFactoryResetMutex.lock();
    qDebug() << __func__ << __LINE__;
    // stop runtime env on vcu and zone controller
    {
        StopRuntimeEnv();
    }

    // reset DK_VSSMAPPING_DBC_CAN
    {
        std::string cmd = "> " + DK_VSSMAPPING_DBC_CAN + ";";
        cmd += "echo \"[]\" > " + DK_VSSMAPPING_DBC_CAN + ";";
        std::string ret = CommonUtils::runLinuxCommand(cmd.c_str());
    }

    // reset supportedvssapi.json and update to server to notify the web client
    {
        std::string cmd = "> " + DK_SUPPORTED_VSS_FILE + ";";
        cmd += "echo \"[]\" > " + DK_SUPPORTED_VSS_FILE + ";";
        std::string ret = CommonUtils::runLinuxCommand(cmd.c_str());
    }

    // reset overlay file
    {
        std::string cmd = "> " + DK_VSSOVERLAY_VSPECS + ";";
        cmd += "echo 'Vehicle:\n  type: branch\n\n' > " + DK_VSSOVERLAY_VSPECS + ";";
        std::string ret = CommonUtils::runLinuxCommand(cmd.c_str());
    }

    // remove dbc files
    {
        // TODO: T.B.D
    }

    // reset dbc default value
    {
        std::string cmd = "> " + DK_DBCDEFAULT_VALUES + ";";
        cmd += "echo \"{}\" > " + DK_DBCDEFAULT_VALUES + ";";
        std::string ret = CommonUtils::runLinuxCommand(cmd.c_str());
    }

    // reset EcuList.json
    {
        // TODO: T.B.D
    }

    // clear start kuksa feeder scripts
    {
        std::string cmd = "> " + DK_STARTKUKFEEDER_SCRIPT + ";";
        std::string ret = CommonUtils::runLinuxCommand(cmd.c_str());
    }

    // update all reset artifacts to zonecontroller
    if (m_orchestrator)
    {
        // send file to zonecontroller
        m_orchestrator->SendFile("zonecontroller", DK_VSS_VSPECS_JSON);
        m_orchestrator->SendFile("zonecontroller", DK_DBCDEFAULT_VALUES);
        m_orchestrator->SendFile("zonecontroller", DK_STOPKUKFEEDER_SCRIPT);
        m_orchestrator->SendFile("zonecontroller", DK_STARTKUKFEEDER_SCRIPT);
        QThread::sleep(2);
    }

    // regenerate vss_specs and vehicle_model
    if (!GenerateVssJson(vssMappingInfo2Client))
    {
        vssMappingFactoryResetMutex.unlock();
        return false;
    }
    if (!GenerateVehicleModel(vssMappingInfo2Client))
    {
        vssMappingFactoryResetMutex.unlock();
        return false;
    }

    // restart the runtime env on vcu and zone controller
    {
        StartRunTimeEnv();
        QThread::sleep(1);
    }

    qDebug() << "Vss Mapping Factory Reset is executed successfully !!!";

    vssMappingFactoryResetMutex.unlock();
    return true;
}

void MessageToKitHandler::updateSupportedApiList2Server()
{
    // notify to all client that apis list is changed
    QString supportAPIs = FileUtils::ReadFile(QString::fromStdString(DK_SUPPORTED_VSS_FILE));
    QString serialNo = CommonUtils::get_dreamkit_code(DK_BOARD_UNIQUE_SERIAL_NUMBER_FILE, DK_DREAMKIT_UNIQUE_SERIAL_NUMBER_FILE);

    // register the dreamkit ID to server
    message::ptr obj = object_message::create();
    obj->get_map()["kit_id"] = string_message::create(serialNo.toStdString());
    obj->get_map()["name"] = string_message::create(serialNo.toStdString());
    obj->get_map()["support_apis"] = string_message::create(supportAPIs.toStdString());
    m_io->socket()->emit("register_kit", obj);
}

void MessageToKitHandler::run()
{
    // qDebug() << __func__ << __LINE__;
    if (m_data->get_flag() == message::flag_object)
    {
        std::string cmd = m_data->get_map()["cmd"]->get_string();
        qDebug() << __func__ << __LINE__ << " cmd : " << QString::fromStdString(cmd);

        if (cmd == "deploy_request")
        {
            DeploymentHandler(m_data);
        }
        else if (cmd == "deploy_AraApp_Request")
        {
            AraDeploymentHandler(m_data);
        }
        else if (cmd == "get_support_apis")
        {
            GetSupportAPIs(m_data);
        }
        else if (cmd == "set_support_apis")
        {
            SetSupportAPIs(m_data);
        }
        else if (cmd == "list_prototypes")
        {
            HandleListPrototype(m_data);
        }
        else if (cmd == "action_on_prototype")
        {
            HandleActionOnPrototype(m_data);
        }
        else if (cmd == "factory_reset")
        {
            FactoryResetHandler(m_data);
        }
        else if (cmd == "execute_cmd")
        {
            ExecuteCmd(m_data);
        }
        else if (cmd == "vss_mapping_factory_reset")
        {
            QString vssMappingInfo2Client;
            vssMappingInfo2Client.clear();
            bool ret = VssMappingFactoryResetHandler(m_data, vssMappingInfo2Client);
            qDebug() << __func__ << __LINE__ << " : vssMappingInfo2Client : " << vssMappingInfo2Client;

            // send the result of the vss mapping factory reset to client (e.g., web client from digital.auto)
            std::string request_from = m_data->get_map()["request_from"]->get_string();
            message::ptr Obj = object_message::create();
            Obj->get_map()["request_from"] = string_message::create(request_from);
            Obj->get_map()["cmd"] = string_message::create("vss_mapping_factory_reset_result");
            Obj->get_map()["result"] = bool_message::create(ret);
            Obj->get_map()["log"] = string_message::create(vssMappingInfo2Client.toStdString());
            m_io->socket()->emit("messageToKit-kitReply", Obj);

            updateSupportedApiList2Server();
        }
        else if (cmd == "vss_mapping")
        {
            QString vssMappingInfo2Client;
            vssMappingInfo2Client.clear();
            bool ret = VssMappingHandler(m_data, vssMappingInfo2Client);
            qDebug() << __func__ << __LINE__ << " : vssMappingInfo2Client : " << vssMappingInfo2Client;

            // send the result of the deployment to client (e.g., web client from digital.auto)
            std::string request_from = m_data->get_map()["request_from"]->get_string();
            message::ptr Obj = object_message::create();
            Obj->get_map()["request_from"] = string_message::create(request_from);
            Obj->get_map()["cmd"] = string_message::create("vss_mapping_result");
            Obj->get_map()["result"] = bool_message::create(ret);
            Obj->get_map()["log"] = string_message::create(vssMappingInfo2Client.toStdString());
            m_io->socket()->emit("messageToKit-kitReply", Obj);

            updateSupportedApiList2Server();
        }
        else
        {
            qDebug() << __func__ << __LINE__ << ": " << QString::fromStdString(cmd) << " is not supported.";
        }
    }

    qDebug() << __func__ << __LINE__ << " MessageToKitHandler::run - end !!!!!!!";
    Q_EMIT messageToKitHandlerFinished(this);
}
