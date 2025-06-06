#ifndef DKMANAGER_H
#define DKMANAGER_H

#include <QObject>
#include <QThread>
#include <QTimer>
#include <sio_client.h>
#include "vcuorchestrator.hpp"
#include "message_to_kit_handler.h"

using namespace sio;

class DkManger : public QObject
{
    Q_OBJECT

public:
    explicit DkManger();
    ~DkManger();
    void Start();

public Q_SLOTS:

protected:
Q_SIGNALS:

private Q_SLOTS:
    void FinishedHandler(MessageToKitHandler *thread);
    void BroadCastGlobalStatus();

private:
    //    void OnExecuteCmd(std::string const& name,message::ptr const& data,bool hasAck,message::list &ack_resp);
    void OnSelfUpdateRequest(std::string const &name, message::ptr const &data, bool hasAck, message::list &ack_resp);
    void OnDownloadFileRequest(std::string const &name, message::ptr const &data, bool hasAck, message::list &ack_resp);
    void OnUploadFileRequest(std::string const &name, message::ptr const &data, bool hasAck, message::list &ack_resp);
    void OnMessageToKit(std::string const &name, message::ptr const &data, bool hasAck, message::list &ack_resp);

    void OnConnected(std::string const &nsp);
    void OnClosed(client::close_reason const &reason);
    void OnFailed();

    void OnReconnectingListener();
    void OnSocketCloseListener(std::string const &nsp);

    void InitDigitalautoFolder();

    void InitUserInfo();

    //    std::unique_ptr<client> _io;
    client *_io;
    DkOrchestrator *m_orchestrator = nullptr;

    QTimer *m_timer;
    bool isSocketConnected = false;
    bool isInternetConnected = false;
};

#endif // DKMANAGER_H
