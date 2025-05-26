#ifndef MESSAGE_TO_KIT_HANDLER_H
#define MESSAGE_TO_KIT_HANDLER_H

#include <QObject>
#include <QThread>
#include <QTimer>
#include <sio_client.h>
#include "vcuorchestrator.hpp"
#include "prototype_utils.h"
#include "dapr_utils.h"

#define kURL "https://kit.digitalauto.tech"

class MessageToKitHandler : public QThread
{
    Q_OBJECT
    void run() override;

public:
    MessageToKitHandler(client *_io, message::ptr const &data, DkOrchestrator *orchestrator);
    ~MessageToKitHandler();

Q_SIGNALS:
    void messageToKitHandlerFinished(MessageToKitHandler *thread);

private Q_SLOTS:

private:
    void ExecuteCmd(message::ptr const &data);
    void FactoryResetHandler(message::ptr const &data);
    void AraDeploymentHandler(message::ptr const &data);
    void DeploymentHandler(message::ptr const &data);
    void HandleListPrototype(message::ptr const &data);
    void HandleActionOnPrototype(message::ptr const &data);
    bool VssMappingHandler(message::ptr const &data, QString &vssMappingInfo2Client);
    bool VssMappingFactoryResetHandler(message::ptr const &data, QString &vssMappingInfo2Client);

    void StopRuntimeEnv();
    void StopAllDigialAutoApps();
    void StopVehicleDatabroker();
    void StopKuksaFeeder();

    void StartRunTimeEnv();
    void StartVehicleDatabroker();
    void StartKuksaFeeder();

    bool GenerateVssJson(QString &vssMappingInfo2Client);
    bool GenerateVehicleModel(QString &vssMappingInfo2Client);
    void GetSupportAPIs(message::ptr const &data);
    void SetSupportAPIs(message::ptr const &data);

    void updateSupportedApiList2Server();

    message::ptr m_data;
    client *m_io;
    DkOrchestrator *m_orchestrator;
    Prototype_Utils *m_proto_utils;
    Dapr_Utils *m_dapr_utils;
};
#endif // MESSAGE_TO_KIT_HANDLER_H
