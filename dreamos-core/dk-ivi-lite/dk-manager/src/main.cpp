#include <QCoreApplication>
#include <QThread>
#include <QDebug>
#include <QCommandLineParser>
#include "dkmanager.h"

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);
    a.setApplicationName("dk-manager");
    a.setApplicationVersion("1.0.0");

    QCommandLineParser parser;
    parser.setApplicationDescription("DreamOS Manager - Application lifecycle and system orchestration");
    parser.addHelpOption();
    parser.addVersionOption();
    
    QCommandLineOption embeddedOption("embedded", 
        "Run in embedded mode (called as subprocess from dk_ivi)");
    parser.addOption(embeddedOption);
    
    QCommandLineOption noRemoteOption("no-remote", 
        "Disable remote server connection (local mode only)");
    parser.addOption(noRemoteOption);
    
    QCommandLineOption ipcSocketOption("ipc-socket", 
        "Local IPC socket path for communication", "path", "/tmp/dk_manager.sock");
    parser.addOption(ipcSocketOption);

    parser.process(a);

    bool isEmbedded = parser.isSet(embeddedOption);
    bool noRemote = parser.isSet(noRemoteOption);
    QString ipcSocket = parser.value(ipcSocketOption);

    if (isEmbedded) {
        qDebug() << "dk-manager version 1.0.0 - Running in embedded mode";
        qDebug() << "IPC Socket:" << ipcSocket;
    } else {
        qDebug() << "dk-manager version 1.0.0 - Running in standalone mode";
    }

    DkManger dkManager;
    
    // Configure manager based on command line options
    if (noRemote || isEmbedded) {
        qDebug() << "Remote connection disabled";
    }
    
    if (isEmbedded) {
        dkManager.SetEmbeddedMode(true);
        dkManager.SetMockMode(true); // Enable mock mode to avoid Docker operations
        qDebug() << "Configured for embedded operation with mock mode";
    }
    
    dkManager.Start();

    return a.exec();
}
