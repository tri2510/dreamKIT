#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QLoggingCategory>
#include <QDebug>
#include <iostream>

#include "config.hpp"
#include "../digitalauto/digitalauto.hpp"
#include "../marketplace/marketplace.hpp"
#include "../installedservices/installedservices.hpp"
#include "../installedvapps/installedvapps.hpp"
#include "../controls/controls.hpp"
#include "../library/vapiclient/vapiclient.hpp"

Q_LOGGING_CATEGORY(mainLog, "dk.ivi.main")

int main(int argc, char *argv[])
{
    // Create configuration object and parse command line arguments
    Config config;
    
    // Parse arguments before creating QGuiApplication to handle early options
    if (!config.parseArguments(argc, argv)) {
        return 1; // Exit on parse error
    }
    
    // Handle help and version (these don't need QGuiApplication)
    if (config.showHelp() || config.showVersion()) {
        return 0;
    }

    // qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));

    QGuiApplication app(argc, argv);
    
    // Set application metadata
    app.setApplicationName("DreamKIT IVI");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("DreamKIT");
    app.setOrganizationDomain("dreamkit.org");

    // Apply configuration settings
    config.applyLoggingConfiguration();
    config.applyQtConfiguration();
    
    // Print configuration for debugging
    config.printConfiguration();
    
    qCInfo(mainLog) << "Starting DreamKIT IVI Application...";
    qCDebug(mainLog) << "Qt version:" << QT_VERSION_STR;
    qCDebug(mainLog) << "Command line arguments:" << app.arguments();

    // VAPI Client Initialization with configurable endpoint
    QString vapiEndpoint = config.vapiDataBroker();
    qCInfo(mainLog) << "Connecting to VAPI Data Broker:" << vapiEndpoint;
    
    VAPI_CLIENT.connectToServer(vapiEndpoint.toStdString().c_str());
    // Register QML types for pages
    qCInfo(mainLog) << "Registering QML types...";
    qmlRegisterType<DigitalAutoAppAsync>("DigitalAutoAppAsync", 1, 0, "DigitalAutoAppAsync");
    qmlRegisterType<MarketplaceAsync>("MarketplaceAsync", 1, 0, "MarketplaceAsync");
    qmlRegisterType<ServicesAsync>("ServicesAsync", 1, 0, "ServicesAsync");
    qmlRegisterType<VappsAsync>("VappsAsync", 1, 0, "VappsAsync");
    qmlRegisterType<ControlsAsync>("ControlsAsync", 1, 0, "ControlsAsync");

    QQmlApplicationEngine engine;
    
    // Expose configuration to QML context
    QQmlContext* rootContext = engine.rootContext();
    rootContext->setContextProperty("dkConfig", QVariant::fromValue(QVariantMap{
        {"logLevel", config.logLevel()},
        {"canInterface", config.canInterface()},
        {"vapiDataBroker", config.vapiDataBroker()},
        {"systemDataBroker", config.systemDataBroker()},
        {"qtBackend", config.qtBackend()},
        {"debugMode", config.enableDebug()}
    }));
    
    qCInfo(mainLog) << "Configuration exposed to QML context";
    
    const QUrl url1(QStringLiteral("qrc:/untitled2/main/main.qml"));
    const QUrl url2(QStringLiteral("qrc:/main/main.qml"));

    // Track which url is being tried
    static bool triedFallback = false;

    // Use a lambda that can capture and modify triedFallback
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                 &app, [&engine, &app, url1, url2](QObject *obj, const QUrl &objUrl) mutable {
                     static bool triedFallback = false;
                     if (!obj) {
                         if (!triedFallback && objUrl == url1) {
                             // First URL failed, try second
                             qCWarning(mainLog) << "Failed to load primary QML file, trying fallback...";
                             triedFallback = true;
                             engine.load(url2);
                         } else {
                             // Second URL also failed, exit with error
                             qCCritical(mainLog) << "Failed to load QML files - exiting with error";
                             QCoreApplication::exit(-1);
                         }
                     } else {
                         qCInfo(mainLog) << "QML engine loaded successfully from:" << objUrl;
                     }
                 }, Qt::QueuedConnection);

    qCInfo(mainLog) << "Loading QML main interface...";
    engine.load(url1);
    
    qCInfo(mainLog) << "Starting application event loop...";
    int result = app.exec();
    
    qCInfo(mainLog) << "Application finished with exit code:" << result;
    return result;
}
