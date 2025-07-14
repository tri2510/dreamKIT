#include "dkmanager.h"
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

QMutex digitalAutoPrototypeMutex;
QMutex vssMappingMutex;
QMutex vssMappingFactoryResetMutex;
QMutex dreamOsPatchUpdateMutex;

/*
dk_manager features:
- Connect and register client_id to digital.auto server
- Provide supported vss api list
- Receive prototype deployment
- Perform some actions on prototype e.g., get list of prototypes (prototypes.json), run/stop, get log, edit supported api list file.
- vssmapping:
*/

#if 1
// docker mount option: -v ~/.dk:/app/.dk
std::string DK_ROOT_DIR = "/app/.dk/";

std::string DK_SWUPDATE_DIR = DK_ROOT_DIR + "dk_swupdate/";
std::string DK_SWUPDATE_PATCH_DIR = DK_SWUPDATE_DIR + "dk_patch/";

std::string DK_MARKETPLACE_DIR = DK_ROOT_DIR + "dk_marketplace/";
std::string DK_INSTALLEDSERVICES_DIR = DK_ROOT_DIR + "dk_installedservices/";
std::string DK_INSTALLEDSERVICES_MGRFILE = DK_INSTALLEDSERVICES_DIR + "installedservices.json";
std::string DK_INSTALLEDAPPS_DIR = DK_ROOT_DIR + "dk_installedapps/";
std::string DK_INSTALLEDAPSS_MGRFILE = DK_INSTALLEDAPPS_DIR + "installedapps.json";

std::string DK_MGR_ROOT_DIR = (DK_ROOT_DIR + "dk_manager/");

std::string DK_VSSGEN_ROOT_DIR = (DK_ROOT_DIR + "dk_vssgeneration/");
std::string DK_VSSGEN_VSSJSON  = (DK_VSSGEN_ROOT_DIR + "vss.json");
std::string DK_VSSGEN_VMODEL   = (DK_VSSGEN_ROOT_DIR + "vehicle_gen/");
#endif

// std::string DK_ROOT_DIR = "/usr/bin/dreamkit/";
std::string DK_SYSTEM_CONFIG_FILE = (DK_MGR_ROOT_DIR + "dk_system_cfg.json");
std::string DK_LOG_FOLDER = (DK_MGR_ROOT_DIR + "log/");
std::string DK_LOG_CMD_FOLDER = (DK_LOG_FOLDER + "cmd/");
std::string DK_DOWNLOAD_FOLDER = (DK_MGR_ROOT_DIR + "download/");
std::string DK_VSSMAPPING_FOLDER = (DK_MGR_ROOT_DIR + "vssmapping/");
std::string DK_VSSMAPPING_GLOBAL_CONFIG = (DK_VSSMAPPING_FOLDER + "vssmapping_global_config.json");
std::string DK_VSSMAPPING_DEPLOY_CONFIG = (DK_VSSMAPPING_FOLDER + "vssmapping_deploy_config.json");
std::string DK_VSSMAPPING_DBC_CAN = (DK_VSSMAPPING_FOLDER + "vssmapping_dbc_can_channels.json");
std::string DK_VSSOVERLAY_VSPECS = (DK_VSSMAPPING_FOLDER + "vssmapping_overlay.vspec");
// std::string DK_VSS_VSPECS_JSON = (DK_VSSMAPPING_FOLDER + "vss_dbc.json");
std::string DK_VSS_VSPECS_JSON = DK_VSSGEN_VSSJSON;
std::string DK_DBCDEFAULT_VALUES = (DK_VSSMAPPING_FOLDER + "dbc_default_values.json");
std::string DK_VSPECS2JSON_LOG = (DK_VSSMAPPING_FOLDER + "vspec2json.log");
std::string DK_VMODEL_GEN_LOG = (DK_VSSMAPPING_FOLDER + "gen_vehicle_model.log");
std::string DK_DATABROKER_LOG = (DK_VSSMAPPING_FOLDER + "vehicle_databroker.log");
std::string DK_DBCFEEDER_LOG = (DK_VSSMAPPING_FOLDER + "dbcfeeder.log");
std::string DK_VSS_SPECS_FOLDER = (DK_VSSMAPPING_FOLDER + "vss_specs/");
std::string DK_VMODEL_GEN_FOLDER = (DK_VSSMAPPING_FOLDER + "vehicle-model-generator/");
std::string DK_ZONECTL_FOLDER = (DK_VSSMAPPING_FOLDER);
std::string DK_STOPKUKFEEDER_SCRIPT = (DK_ZONECTL_FOLDER + "stop_kuksa_feeder_script.sh");
std::string DK_STARTKUKFEEDER_SCRIPT = (DK_ZONECTL_FOLDER + "start_kuksa_feeder_script.sh");
std::string DK_DOWNLOAD_LOGFILE = (DK_LOG_FOLDER + "requestdownload.log");
std::string DK_PROTOTYPES_FOLDER = (DK_MGR_ROOT_DIR + "prototypes/");
std::string DK_PROTOTYPES_LIST = (DK_PROTOTYPES_FOLDER + "prototypes.json");
std::string DK_SUPPORTED_VSS_FILE = (DK_PROTOTYPES_FOLDER + "supportedvssapi.json");
std::string DK_BOARD_UNIQUE_SERIAL_NUMBER_FILE = "/proc/device-tree/serial-number";
std::string DK_DREAMKIT_UNIQUE_SERIAL_NUMBER_FILE = DK_MGR_ROOT_DIR + "serial-number";
std::string DK_ECU_LIST = DK_ROOT_DIR + "EcuList.json";
std::string DK_CURRENT_VSS_VERSION = "vss4.0";
std::string DK_VCU_USERNAME = "sdv-orin";
std::string DK_ARCH = "arm64";
std::string DK_DOCKER_HUB_NAMESPACE = "";

#if 1
#ifdef DREAMKIT_MINI
std::string DK_ZC_USERNAME = "sdv";
#else
std::string DK_ZC_USERNAME = "bluebox";
#endif
#else
// if testing on VCU
std::string DK_ZC_USERNAME = "sdv-orin";
#endif

#define BIND_EVENT(IO, EV, FN) IO->on(EV, FN)

DkManger::DkManger() : _io(new client())
{
    qDebug() << __func__ << __LINE__ << " : setup socket.io";

    InitDigitalautoFolder();

    InitUserInfo();

    using std::placeholders::_1;
    using std::placeholders::_2;
    using std::placeholders::_3;
    using std::placeholders::_4;

    socket::ptr sock = _io->socket();
    BIND_EVENT(sock, "dk_selfUpdate", std::bind(&DkManger::OnSelfUpdateRequest, this, _1, _2, _3, _4));
    BIND_EVENT(sock, "dk_downloadFile", std::bind(&DkManger::OnDownloadFileRequest, this, _1, _2, _3, _4));
    BIND_EVENT(sock, "dk_uploadFile", std::bind(&DkManger::OnUploadFileRequest, this, _1, _2, _3, _4));
    BIND_EVENT(sock, "messageToKit", std::bind(&DkManger::OnMessageToKit, this, _1, _2, _3, _4));

    _io->set_socket_open_listener(std::bind(&DkManger::OnConnected, this, _1));
    _io->set_close_listener(std::bind(&DkManger::OnClosed, this, _1));
    _io->set_fail_listener(std::bind(&DkManger::OnFailed, this));
    _io->set_reconnecting_listener(std::bind(&DkManger::OnReconnectingListener, this));
    _io->set_socket_close_listener(std::bind(&DkManger::OnSocketCloseListener, this, _1));
    // _io->set_reconnect_delay(1000);
    // _io->set_reconnect_delay_max(1000);
#ifdef USING_DK_ORCHESTRATOR
    m_orchestrator = new DkOrchestrator();
#endif
    m_timer = new QTimer(this);
    connect(m_timer, SIGNAL(timeout()), this, SLOT(BroadCastGlobalStatus()));
    m_timer->start(2000);
}

void DkManger::OnReconnectingListener()
{
    qDebug() << __func__ << __LINE__;
    isSocketConnected = false;
}

void DkManger::OnSocketCloseListener(std::string const &nsp)
{
    qDebug() << __func__ << __LINE__;
}

void DkManger::InitUserInfo()
{
    QString username_ = "";
    QString arch_ = "";
    QString docker_hub_name_space_ = "";

    username_ = qgetenv("USER");
    if (username_.isEmpty())
    {
        username_ = "sdv-orin";
    }

    arch_ = qgetenv("ARCH");
    docker_hub_name_space_ = qgetenv("DOCKER_HUB_NAMESPACE");

    DK_VCU_USERNAME = username_.toStdString();
    DK_ARCH = arch_.toStdString();
    DK_DOCKER_HUB_NAMESPACE = docker_hub_name_space_.toStdString();

    qDebug() << __func__ << __LINE__ << " : DK_VCU_USERNAME = " << QString::fromStdString(DK_VCU_USERNAME);
}

void DkManger::InitDigitalautoFolder()
{
    qDebug() << __func__ << __LINE__;
    // Try to Create Log foler
    {
        std::string cmd;
        cmd.clear();

        cmd = "mkdir -p " + DK_LOG_CMD_FOLDER + " " + DK_PROTOTYPES_FOLDER + " " + DK_DOWNLOAD_FOLDER + " " + DK_VSSMAPPING_FOLDER + " " + DK_ZONECTL_FOLDER + " " + DK_MARKETPLACE_DIR + " " + DK_INSTALLEDSERVICES_DIR + " " + DK_INSTALLEDAPPS_DIR + ";";
        cmd += "rm " + DK_LOG_CMD_FOLDER + "*;";
        cmd += "touch " + DK_STOPKUKFEEDER_SCRIPT + ";";
        cmd += "touch " + DK_STARTKUKFEEDER_SCRIPT + ";";
        
        if (!FileUtils::fileExists(DK_INSTALLEDSERVICES_MGRFILE))
        {
            cmd += "echo \"[]\" > " + DK_INSTALLEDSERVICES_MGRFILE + ";";
        }
        if (!FileUtils::fileExists(DK_INSTALLEDAPSS_MGRFILE))
        {
            cmd += "echo \"[]\" > " + DK_INSTALLEDAPSS_MGRFILE + ";";
        }

        if (!FileUtils::fileExists(DK_VSSOVERLAY_VSPECS))
        {
            cmd += "echo 'Vehicle:\n  type: branch\n\n' > " + DK_VSSOVERLAY_VSPECS + ";";
            // cmd += "touch " + DK_VSSOVERLAY_VSPECS + ";";
        }
        if (!FileUtils::fileExists(DK_SUPPORTED_VSS_FILE))
        {
            cmd += "echo \"[]\" > " + DK_SUPPORTED_VSS_FILE + ";";
        }
        if (!FileUtils::fileExists(DK_VSSMAPPING_DBC_CAN))
        {
            cmd += "echo \"[]\" > " + DK_VSSMAPPING_DBC_CAN + ";";
        }
        if (!FileUtils::fileExists(DK_DBCDEFAULT_VALUES))
        {
            cmd += "echo \"{}\" > " + DK_DBCDEFAULT_VALUES + ";";
        }
        if (!FileUtils::fileExists(DK_PROTOTYPES_LIST))
        {
            cmd += "touch " + DK_PROTOTYPES_LIST + ";";
            cmd += "chmod 777 " + DK_PROTOTYPES_LIST + ";";
            cmd += "chmod 777 -R " + DK_PROTOTYPES_FOLDER + ";";
        }
        cmd += "chmod 777 -R " + DK_VSSMAPPING_FOLDER + ";";
        qDebug() << __func__ << __LINE__ << " cmd = " << QString::fromStdString(cmd);
        system(cmd.data());
        QThread::msleep(100);

        if (!FileUtils::fileExists(DK_SYSTEM_CONFIG_FILE)) {
            cmd.clear();
            cmd = "echo \"{\\n"
            "    \\\"xip\\\": {\\n"
            "        \\\"ip\\\": \\\"192.168.56.48\\\"\\n"
            "    },\\n"
            "    \\\"vip\\\": {\\n"
            "        \\\"ip\\\": \\\"192.168.56.49\\\",\\n"
            "        \\\"user\\\": \\\"root\\\",\\n"
            "        \\\"pwd\\\": \\\"\\\"\\n"
            "    }\\n"
            "}\" > ";
            cmd += DK_SYSTEM_CONFIG_FILE;
            system(cmd.data());
        }
    }
}

void DkManger::Start()
{
    qDebug() << "URL: " << kURL;
    _io->connect(kURL);
    if (m_orchestrator)
    {
        m_orchestrator->Start();
    }
}

DkManger::~DkManger()
{
    _io->socket()->off_all();
    _io->socket()->off_error();
    delete m_timer;
    delete _io;
    delete m_orchestrator;
}

void DkManger::OnMessageToKit(std::string const &name, message::ptr const &data, bool hasAck, message::list &ack_resp)
{
    // qDebug() << __func__ << __LINE__;

    MessageToKitHandler *messageToKitHandler = new MessageToKitHandler(_io, data, m_orchestrator);
    connect(messageToKitHandler, &MessageToKitHandler::messageToKitHandlerFinished, this, &DkManger::FinishedHandler);
    messageToKitHandler->start();
    // qDebug() << __func__ << __LINE__ << "messageToKitHandler address = " << messageToKitHandler;
}

void DkManger::OnSelfUpdateRequest(std::string const &name, message::ptr const &data, bool hasAck, message::list &ack_resp)
{
    qDebug() << __func__ << __LINE__;
}

void DkManger::OnDownloadFileRequest(std::string const &name, message::ptr const &data, bool hasAck, message::list &ack_resp)
{
    qDebug() << __func__ << __LINE__;

    if (data->get_flag() == message::flag_object)
    {
        std::string cmd;
        cmd.clear();
        cmd = "> " + DK_DOWNLOAD_LOGFILE;
        system(cmd.data()); // clear old log,

        std::string filename = data->get_map()["filename"]->get_string();
        std::string url = data->get_map()["url"]->get_string();

        cmd.clear();
        cmd = "wget -O " + DK_DOWNLOAD_FOLDER + filename + " " + url + " -o " + DK_DOWNLOAD_LOGFILE;
        qDebug() << __func__ << __LINE__ << " cmd : " << QString::fromStdString(cmd);
        system(cmd.data());
    }
}

void DkManger::OnUploadFileRequest(std::string const &name, message::ptr const &data, bool hasAck, message::list &ack_resp)
{
    qDebug() << __func__ << __LINE__;
}

void DkManger::OnConnected(std::string const &nsp)
{
    // qDebug() << __func__ << " - " << QString::fromStdString(nsp);

    QString supportAPIs = FileUtils::ReadFile(QString::fromStdString(DK_SUPPORTED_VSS_FILE));
    QString serialNo = CommonUtils::get_dreamkit_code(DK_BOARD_UNIQUE_SERIAL_NUMBER_FILE, DK_DREAMKIT_UNIQUE_SERIAL_NUMBER_FILE);

    // register the dreamkit ID to server
    message::ptr obj = object_message::create();
    obj->get_map()["kit_id"] = string_message::create(serialNo.toStdString());
    obj->get_map()["name"] = string_message::create(serialNo.toStdString());
    obj->get_map()["support_apis"] = string_message::create(supportAPIs.toStdString());
    _io->socket()->emit("register_kit", obj);

    isSocketConnected = true;
}

void DkManger::OnClosed(client::close_reason const &reason)
{
    qDebug() << __func__ << __LINE__;
}

void DkManger::OnFailed()
{
    qDebug() << __func__ << __LINE__;
}

void DkManger::BroadCastGlobalStatus()
{
    m_timer->stop();

    // qDebug() << __func__ << __LINE__;
    if (m_orchestrator)
    {
        bool status = isSocketConnected;
#if 1
        QNetworkAccessManager nam;
        QNetworkRequest req(QUrl("http://google.com"));
        QNetworkReply *reply = nam.get(req);
        QEventLoop loop;
        QTimer timeoutTimer;
        connect(&timeoutTimer, SIGNAL(timeout()), &loop, SLOT(quit()));
        connect(reply, SIGNAL(finished()), &loop, SLOT(quit()));
        timeoutTimer.setSingleShot(true);
        timeoutTimer.start(5000); // this is your timeout in milliseconds
        loop.exec();
        if (reply->bytesAvailable())
            isInternetConnected = true;
        else
            isInternetConnected = false;
        status = status & isInternetConnected;
#endif
        // qDebug() << __func__ << __LINE__ << " : internet sts : " << isInternetConnected;
        m_orchestrator->UpdateServerConnectionStatus(status);
    }
    m_timer->start(1000);
}

void DkManger::FinishedHandler(MessageToKitHandler *thread)
{
    qDebug() << __func__ << __LINE__ << "messageToKitHandler address = " << thread;

    // qDebug() << __func__ << __LINE__ << " : update API supported list";
    // std::string nsp = "/";
    // OnConnected(nsp); // update API supported list

    if (thread)
    {
        for (int i = 0; i < 100; i++)
        {
            QThread::msleep(100);
            //            qDebug() << __func__ << __LINE__ << " - messageToKitHandler->isFinished = " << thread->isFinished();
            if (thread->isFinished())
            {
                delete thread;
                return;
            }
        }
    }
}
