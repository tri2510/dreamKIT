#include "protocolbridge.h"
#include <QQmlEngine>
#include <QDebug>

ProtocolBridge::ProtocolBridge(QObject *parent)
    : QObject(parent)
    , m_manager(new ProtocolBridgeManager(this))
{
    qDebug() << "ProtocolBridge created";
}

void ProtocolBridge::initialize()
{
    qDebug() << "Initializing Protocol Bridge...";
    // Any additional initialization can go here
}

void ProtocolBridge::registerQMLTypes()
{
    // Register types - simplified registration
    qmlRegisterType<ProtocolBridgeManager>("ProtocolBridge", 1, 0, "ProtocolBridgeManager");
    qmlRegisterType<KuksaConnectionManager>("ProtocolBridge", 1, 0, "KuksaConnectionManager");
    qmlRegisterType<TerminalConsole>("ProtocolBridge", 1, 0, "TerminalConsole");
    qmlRegisterType<VSSSignalModel>("ProtocolBridge", 1, 0, "VSSSignalModel");
    
    qDebug() << "Protocol Bridge QML types registered";
}

void ProtocolBridge::exposeToQML(QQmlContext *context)
{
    if (!context) {
        qWarning() << "Cannot expose Protocol Bridge to null QML context";
        return;
    }
    
    // Create global instance
    static ProtocolBridge *instance = new ProtocolBridge();
    
    // Expose to QML context
    context->setContextProperty("protocolBridge", instance->manager());
    context->setContextProperty("kuksaManager", instance->manager()->kuksaManager());
    context->setContextProperty("terminalConsole", instance->manager()->terminal());
    context->setContextProperty("vssSignalModel", instance->manager()->vssSignalModel());
    
    qDebug() << "Protocol Bridge exposed to QML context";
}