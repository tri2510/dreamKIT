#ifndef PROTOCOLBRIDGE_H
#define PROTOCOLBRIDGE_H

#include <QObject>
#include <QQmlContext>
#include "protocolbridgemanager.h"

class ProtocolBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ProtocolBridgeManager* manager READ manager CONSTANT)

public:
    explicit ProtocolBridge(QObject *parent = nullptr);
    
    ProtocolBridgeManager* manager() const { return m_manager; }
    
    // Register QML types and expose to QML context
    static void registerQMLTypes();
    static void exposeToQML(QQmlContext *context);

public slots:
    void initialize();

private:
    ProtocolBridgeManager *m_manager;
};

#endif // PROTOCOLBRIDGE_H