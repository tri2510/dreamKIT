#ifndef DK_VCUORCHESTRATOR_H
#define DK_VCUORCHESTRATOR_H

#include <sio_client.h>

using namespace sio;

class DkOrchestrator
{
public:
    explicit DkOrchestrator();
    ~DkOrchestrator();
    void Start();
    void SendCmd(std::string dest, std::string data);
    void SendFile(std::string dest, std::string filePath);
    void UpdateServerConnectionStatus(bool status);

private:
    void OnVcuRrchestratorHandler(std::string const& name,message::ptr const& data,bool hasAck,message::list &ack_resp);

    void OnConnected(std::string const& nsp);
    void OnClosed(client::close_reason const& reason);
    void OnFailed();

    client *_io;
};

#endif // DK_VCUORCHESTRATOR_H
