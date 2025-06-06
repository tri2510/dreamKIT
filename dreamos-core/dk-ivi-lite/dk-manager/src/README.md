# Require library:
https://github.com/socketio/socket.io-client-cpp


## Build With CMake
Use `git clone --recurse-submodules https://github.com/socketio/socket.io-client-cpp.git` to clone your local repo.

Run `cmake  ./`

Run `make install` (if makefile generated) or open generated project (if project file generated) to build.

Maybe you will need to run `sudo make install`

# Important parameter
- kURL "https://kit.digitalauto.tech"

- DK_BOARD_UNIQUE_SERIAL_NUMBER_FILE `/proc/device-tree/serial-number`
- DK_ECU_LIST `/opt/data/EcuList.json`
- DK_CURRENT_VSS_VERSION `vss3.0`
- DK_VCU_USERNAME `sdv-orin`
- DK_ZC_USERNAME `bluebox`

# Root folder layout

ROOT_DIR: `/usr/bin/dreamkit/`
- serial-number
- log
    - requestdownload.log
    - cmd
- download
- vssmapping
    - vssmapping_global_config.json
    - vssmapping_deploy_config.json
    - vssmapping_dbc_can_channels.json
    - vssmapping_overlay.vspec
    - vss_dbc.json
    - dbc_default_values.json
    - vspec2json.log
    - gen_vehicle_model.log
    - vehicle_databroker.log
    - dbcfeeder.log
    - stop_kuksa_feeder_script.sh
    - start_kuksa_feeder_script.sh
    - vss_specs/
    - vehicle-model-generator/
- prototypes/
    - prototypes.json
    - supportedvssapi.json


# Supported remote cmd

1. `deploy_request`
    > DeploymentHandler(m_data); 
2. `factory_reset`
    > FactoryResetHandler(m_data);
3. `execute_cmd`
    > ExecuteCmd(m_data);
4. `vss_mapping_factory_reset`
    > vssMappingInfo2Client.clear();

    > bool ret = VssMappingFactoryResetHandler(m_data, vssMappingInfo2Client);

    Then response to requester
5. `vss_mapping`
    > vssMappingInfo2Client.clear();

    > bool ret = VssMappingHandler(m_data, vssMappingInfo2Client);
    
    Then response to requester
# Main actions
### `void InitDigitalautoFolder()`
Create neccesary dirs and child dirs

### `void DkManger::BroadCastGlobalStatus()`
try to connect to https://google.com then update online status

### `void MessageToKitHandler::DeploymentHandler(message::ptr const &data)`
```js
data: {
    prototype: {
        id: 'string',
        name: 'string',
    },
    code: 'string',
    convertedCode: 'string',
}
```
1. Save convertedCode to file: `[root_dir]/prototypes/[prototype_id]/main.py`
2. Append prototype to prototype list at file: `[root_dir]/prototypes/prototypes.json` 


### std::string runLinuxCommand(const char *cmd)
```c++
std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
```

### void MessageToKitHandler::StartRunTimeEnv()
- StartVehicleDatabroker();
- StartKuksaFeeder();

### void MessageToKitHandler::StartVehicleDatabroker()
Start vehicledatabroker with dapr
```c++
std::string cmd = "> " + DK_DATABROKER_LOG + ";";
cmd += "sudo -u " + DK_VCU_USERNAME + " dapr run --app-id vehicledatabroker --app-protocol grpc --resources-path /home/" + DK_VCU_USERNAME + "/.dapr/components --config /home/" + DK_VCU_USERNAME + "/.dapr/config.yaml --app-port 6111 -- docker run --rm --init --name vehicledatabroker -e KUKSA_DATA_BROKER_METADATA_FILE=" + DK_VSS_VSPECS_JSON + " -e KUKSA_DATA_BROKER_PORT=6111 -e 50001 -e 3500 -v " + DK_VSS_VSPECS_JSON + ":" + DK_VSS_VSPECS_JSON + " --network host ghcr.io/eclipse/kuksa.val/databroker:0.3.0 > ";
cmd += DK_DATABROKER_LOG + " 2>&1 &";
system(cmd.c_str());
QThread::sleep(3);
```

### void MessageToKitHandler::StartKuksaFeeder()
```c++
if (m_orchestrator)
{
    // check vehicledatabroker status before start kuksa feeder
    std::string cmd = "docker inspect --format '{{json .State.Running}}' vehicledatabroker";
    std::string ret = runLinuxCommand(cmd.c_str());
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
```

### void MessageToKitHandler::StopRuntimeEnv()
```c++
{
    StopAllDigialAutoApps();
    StopVehicleDatabroker();
    StopKuksaFeeder();
}
```

### void MessageToKitHandler::StopRuntimeEnv()
```c++
// read jsonAppList from .../prototypes.json file
for (const auto obj : jsonAppList)
{
    QString appId = obj.toObject().value("id").toString();
    std::string cmd = "dapr stop " + appId.toStdString();
    qDebug() << "dapr cmd : " << QString::fromStdString(cmd);
    std::string ret = runLinuxCommand(cmd.c_str());
}
```

### void MessageToKitHandler::StopVehicleDatabroker()
```c++
{
    qDebug() << "stop vehicledatabroker on vcu";
    runLinuxCommand("docker stop vehicledatabroker");
    QThread::sleep(2);
    runLinuxCommand("dapr stop vehicledatabroker");
    QThread::sleep(2);
}
```


### void MessageToKitHandler::StopKuksaFeeder()
```c++
{
    if (m_orchestrator)
    {
        qDebug() << "Send cmd to stop kuksa-feeder on zonecontroller";
        // send command to zonecontroller
        m_orchestrator->SendCmd("zonecontroller", "stop_kuksa_feeder_script");
    }
}
```


### void MessageToKitHandler::ExecuteCmd(message::ptr const &data)
1. Execute cmd by `system(cmd + ' > ' + logFile + ' 2>&1')`
2. Read logFile
3. Send response back with below format
```j
emit("messageToKit-kitReply", {
    request_from: '',
    cmd: '',
    result: '',
});
```
### bool MessageToKitHandler::VssMappingHandler(message::ptr const &data, QString &vssMappingInfo2Client)
Provide detail later

### bool MessageToKitHandler::GenerateVehicleModel(QString &vssMappingInfo2Client)
Provide detail later

### bool MessageToKitHandler::GenerateVssJson(QString &vssMappingInfo2Client)
Provide detail later


### Run linux cmd

```c++
std::string runLinuxCommand(const char *cmd)
{
    std::array<char, 1024 * 10> buffer;
    std::string result;
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
    if (!pipe)
    {
        throw std::runtime_error("popen() failed!");
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr)
    {
        result += buffer.data();
    }
    return result;
}
```

### void DkManger::OnDownloadFileRequest(std::string const &name, message::ptr const &data, bool hasAck, message::list &ack_resp)
> Using system() to execute wget -0 [Folder]/[FileName] -o [DK_DOWNLOAD_LOGFILE]

```c++
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
}```

