#include <functional>
#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <string>
#include "vcuorchestrator.hpp"
#include <fstream>
#include <sstream>

#define BIND_EVENT(IO, EV, FN) \
    IO->on(EV, FN)

#define kURL "https://127.0.0.1:39562"

DkOrchestrator::DkOrchestrator() : _io(new client())
{
    std::cout << __func__ << __LINE__ << " : setup socket.io\n";

    using std::placeholders::_1;
    using std::placeholders::_2;
    using std::placeholders::_3;
    using std::placeholders::_4;

    socket::ptr sock = _io->socket();
    BIND_EVENT(sock, "vcu_orchestrator_handler", std::bind(&DkOrchestrator::OnVcuRrchestratorHandler, this, _1, _2, _3, _4));

    _io->set_socket_open_listener(std::bind(&DkOrchestrator::OnConnected, this, std::placeholders::_1));
    _io->set_close_listener(std::bind(&DkOrchestrator::OnClosed, this, _1));
    _io->set_fail_listener(std::bind(&DkOrchestrator::OnFailed, this));
}

void DkOrchestrator::UpdateServerConnectionStatus(bool status)
{
    // std::cout << __func__ << __LINE__ << "\n";
    // send command to zonecontroller
    message::ptr obj = object_message::create();
    obj->get_map()["source"] = string_message::create("vcu");
    obj->get_map()["dest"] = string_message::create("global_broadcast_info");
    obj->get_map()["data"] = object_message::create();
    message::ptr dataObj = obj->get_map()["data"];
    dataObj->get_map()["cmd"] = string_message::create("server_connection_status");
    dataObj->get_map()["status"] = bool_message::create(status);
    _io->socket()->emit("send_cmd", obj);
}

void DkOrchestrator::SendCmd(std::string dest, std::string data)
{
    // send command to zonecontroller
    message::ptr obj = object_message::create();
    obj->get_map()["source"] = string_message::create("vcu");
    obj->get_map()["dest"] = string_message::create(dest);
    obj->get_map()["data"] = object_message::create();
    message::ptr dataObj = obj->get_map()["data"];
    dataObj->get_map()["cmd"] = string_message::create(data);
    _io->socket()->emit("send_cmd", obj);
}

void DkOrchestrator::SendFile(std::string dest, std::string filePath)
{
    // send file to zonecontroller
    std::string fileName = filePath.substr(filePath.find_last_of("/\\") + 1);

    std::ifstream t(filePath);
    std::stringstream buffer;
    buffer << t.rdbuf();
    std::string content = buffer.str();

    message::ptr obj = object_message::create();
    obj->get_map()["source"] = string_message::create("vcu");
    obj->get_map()["dest"] = string_message::create(dest);
    obj->get_map()["data"] = object_message::create();
    message::ptr dataObj = obj->get_map()["data"];
    dataObj->get_map()["cmd"] = string_message::create("file_to_zonecontroller");
    dataObj->get_map()["fileName"] = string_message::create(fileName);
    dataObj->get_map()["content"] = string_message::create(content);
    _io->socket()->emit("send_cmd", obj);
}

void DkOrchestrator::OnVcuRrchestratorHandler(std::string const &name, message::ptr const &data, bool hasAck, message::list &ack_resp)
{
    std::cout << __func__ << __LINE__ << "\n";
}

DkOrchestrator::~DkOrchestrator()
{
    _io->socket()->off_all();
    _io->socket()->off_error();
}

void DkOrchestrator::Start()
{
    std::cout << "URL: " << kURL << "\n";
    _io->connect(kURL);
}

void DkOrchestrator::OnConnected(std::string const &nsp)
{
    std::cout << __func__ << " - " << nsp << "\n";
}

void DkOrchestrator::OnClosed(client::close_reason const &reason)
{
    std::cout << __func__ << __LINE__ << "\n";
}

void DkOrchestrator::OnFailed()
{
    std::cout << __func__ << __LINE__ << "\n";
}