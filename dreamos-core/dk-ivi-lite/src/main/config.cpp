#include "config.hpp"
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QDebug>
#include <QLoggingCategory>
#include <QStandardPaths>
#include <QDir>
#include <QRegularExpression>
#include <iostream>

Q_LOGGING_CATEGORY(configLog, "dk.ivi.config")

Config::Config() {
    loadDefaults();
}

void Config::loadDefaults() {
    m_configFile = "/app/config/dk_ivi.yml";
    m_logLevel = "info";
    m_canInterface = "vcan0";
    m_vapiDataBroker = "127.0.0.1:55555";
    m_systemDataBroker = "127.0.0.1:55569";
    m_qtBackend = "software";
    m_enableDebug = false;
    m_showVersion = false;
    m_showHelp = false;
}

bool Config::parseArguments(int argc, char *argv[]) {
    QCommandLineParser parser;
    parser.setApplicationDescription("DreamKIT IVI Application - In-Vehicle Infotainment System");
    
    // Define command line options
    QCommandLineOption configOption(QStringList() << "c" << "config",
                                   "Configuration file path",
                                   "file", m_configFile);
    
    QCommandLineOption logLevelOption(QStringList() << "l" << "log-level",
                                     "Set logging level (debug, info, warn, error)",
                                     "level", m_logLevel);
    
    QCommandLineOption canInterfaceOption(QStringList() << "i" << "can-interface", 
                                         "CAN interface name (e.g., vcan0, can0)",
                                         "interface", m_canInterface);
    
    QCommandLineOption vapiOption(QStringList() << "v" << "vapi-broker",
                                 "VAPI data broker endpoint (IP:PORT)",
                                 "endpoint", m_vapiDataBroker);
    
    QCommandLineOption systemOption(QStringList() << "s" << "system-broker",
                                   "System data broker endpoint (IP:PORT)", 
                                   "endpoint", m_systemDataBroker);
    
    QCommandLineOption qtBackendOption(QStringList() << "b" << "qt-backend",
                                      "Qt Quick backend (software, opengl, vulkan)",
                                      "backend", m_qtBackend);
    
    QCommandLineOption debugOption(QStringList() << "d" << "debug",
                                  "Enable debug mode with verbose output");
    
    QCommandLineOption versionOption(QStringList() << "V" << "version",
                                    "Show version information");
    
    // Add options to parser
    parser.addOption(configOption);
    parser.addOption(logLevelOption);
    parser.addOption(canInterfaceOption);
    parser.addOption(vapiOption);
    parser.addOption(systemOption);
    parser.addOption(qtBackendOption);
    parser.addOption(debugOption);
    parser.addOption(versionOption);
    parser.addHelpOption();
    
    // Parse arguments
    QStringList arguments;
    for (int i = 0; i < argc; ++i) {
        arguments << QString::fromLocal8Bit(argv[i]);
    }
    
    if (!parser.parse(arguments)) {
        std::cerr << "Error parsing arguments: " << parser.errorText().toStdString() << std::endl;
        return false;
    }
    
    // Check for help and version first
    m_showHelp = parser.isSet("help");
    m_showVersion = parser.isSet(versionOption);
    
    if (m_showHelp) {
        showHelp(arguments.first());
        return true;
    }
    
    if (m_showVersion) {
        std::cout << "DreamKIT IVI Application v1.0.0" << std::endl;
        std::cout << "Built with Qt " << QT_VERSION_STR << std::endl;
        return true;
    }
    
    // Extract option values
    m_configFile = parser.value(configOption);
    m_logLevel = parser.value(logLevelOption);
    m_canInterface = parser.value(canInterfaceOption);
    m_vapiDataBroker = parser.value(vapiOption);
    m_systemDataBroker = parser.value(systemOption);
    m_qtBackend = parser.value(qtBackendOption);
    m_enableDebug = parser.isSet(debugOption);
    
    // If debug is enabled, override log level
    if (m_enableDebug) {
        m_logLevel = "debug";
    }
    
    // Validate configuration
    if (!validateConfiguration()) {
        return false;
    }
    
    return true;
}

void Config::showHelp(const QString& programName) const {
    std::cout << "Usage: " << programName.toStdString() << " [OPTIONS]" << std::endl;
    std::cout << std::endl;
    std::cout << "DreamKIT IVI Application - In-Vehicle Infotainment System" << std::endl;
    std::cout << std::endl;
    std::cout << "Options:" << std::endl;
    std::cout << "  -c, --config <file>        Configuration file path" << std::endl;
    std::cout << "                             (default: /app/config/dk_ivi.yml)" << std::endl;
    std::cout << "  -l, --log-level <level>    Set logging level" << std::endl;
    std::cout << "                             (debug, info, warn, error - default: info)" << std::endl;
    std::cout << "  -i, --can-interface <name> CAN interface name" << std::endl;
    std::cout << "                             (e.g., vcan0, can0 - default: vcan0)" << std::endl;
    std::cout << "  -v, --vapi-broker <addr>   VAPI data broker endpoint" << std::endl;
    std::cout << "                             (IP:PORT - default: 127.0.0.1:55555)" << std::endl;
    std::cout << "  -s, --system-broker <addr> System data broker endpoint" << std::endl;
    std::cout << "                             (IP:PORT - default: 127.0.0.1:55569)" << std::endl;
    std::cout << "  -b, --qt-backend <backend> Qt Quick backend" << std::endl;
    std::cout << "                             (software, opengl, vulkan - default: software)" << std::endl;
    std::cout << "  -d, --debug                Enable debug mode with verbose output" << std::endl;
    std::cout << "  -V, --version              Show version information" << std::endl;
    std::cout << "  -h, --help                 Show this help message" << std::endl;
    std::cout << std::endl;
    std::cout << "Examples:" << std::endl;
    std::cout << "  " << programName.toStdString() << " --log-level debug --can-interface can0" << std::endl;
    std::cout << "  " << programName.toStdString() << " --debug --qt-backend opengl" << std::endl;
    std::cout << "  " << programName.toStdString() << " --config /custom/config.yml --vapi-broker 192.168.1.100:55555" << std::endl;
    std::cout << std::endl;
    std::cout << "Environment Variables:" << std::endl;
    std::cout << "  QT_QUICK_BACKEND           Override Qt backend (if not set via --qt-backend)" << std::endl;
    std::cout << "  DK_LOG_LEVEL               Override log level (if not set via --log-level)" << std::endl;
    std::cout << "  DK_CAN_INTERFACE           Override CAN interface (if not set via --can-interface)" << std::endl;
}

bool Config::validateConfiguration() const {
    // Validate log level
    QStringList validLogLevels = {"debug", "info", "warn", "error"};
    if (!validLogLevels.contains(m_logLevel.toLower())) {
        std::cerr << "Error: Invalid log level '" << m_logLevel.toStdString() 
                  << "'. Valid levels: debug, info, warn, error" << std::endl;
        return false;
    }
    
    // Validate Qt backend
    QStringList validBackends = {"software", "opengl", "vulkan"};
    if (!validBackends.contains(m_qtBackend.toLower())) {
        std::cerr << "Error: Invalid Qt backend '" << m_qtBackend.toStdString() 
                  << "'. Valid backends: software, opengl, vulkan" << std::endl;
        return false;
    }
    
    // Validate data broker endpoints (basic IP:PORT format check)
    QRegularExpression endpointPattern("^\\d+\\.\\d+\\.\\d+\\.\\d+:\\d+$");
    if (!endpointPattern.match(m_vapiDataBroker).hasMatch()) {
        std::cerr << "Error: Invalid VAPI data broker format '" << m_vapiDataBroker.toStdString() 
                  << "'. Expected format: IP:PORT" << std::endl;
        return false;
    }
    
    if (!endpointPattern.match(m_systemDataBroker).hasMatch()) {
        std::cerr << "Error: Invalid system data broker format '" << m_systemDataBroker.toStdString() 
                  << "'. Expected format: IP:PORT" << std::endl;
        return false;
    }
    
    return true;
}

void Config::applyLoggingConfiguration() const {
    setLoggingLevel(m_logLevel);
    
    if (m_enableDebug) {
        // Enable debug output for all dk.ivi categories
        QLoggingCategory::setFilterRules("dk.ivi.*.debug=true");
        qCDebug(configLog) << "Debug mode enabled - verbose logging active";
    }
    
    qCInfo(configLog) << "Logging configuration applied - level:" << m_logLevel;
}

void Config::applyQtConfiguration() const {
    // Set Qt Quick backend
    if (!m_qtBackend.isEmpty()) {
        qputenv("QT_QUICK_BACKEND", m_qtBackend.toLocal8Bit());
        qCInfo(configLog) << "Qt Quick backend set to:" << m_qtBackend;
    }
    
    // Additional Qt configuration based on debug mode
    if (m_enableDebug) {
        qputenv("QT_LOGGING_RULES", "*.debug=true");
        qputenv("QML_DISABLE_DISK_CACHE", "1");
        qCDebug(configLog) << "Qt debug configuration applied";
    }
}

void Config::printConfiguration() const {
    qCInfo(configLog) << "=== DK IVI Configuration ===";
    qCInfo(configLog) << "Config File:       " << m_configFile;
    qCInfo(configLog) << "Log Level:         " << m_logLevel;
    qCInfo(configLog) << "CAN Interface:     " << m_canInterface;
    qCInfo(configLog) << "VAPI Data Broker:  " << m_vapiDataBroker;
    qCInfo(configLog) << "System Data Broker:" << m_systemDataBroker;
    qCInfo(configLog) << "Qt Backend:        " << m_qtBackend;
    qCInfo(configLog) << "Debug Mode:        " << (m_enableDebug ? "enabled" : "disabled");
    qCInfo(configLog) << "============================";
}

void Config::setLoggingLevel(const QString& level) const {
    QString lowerLevel = level.toLower();
    
    if (lowerLevel == "debug") {
        QLoggingCategory::setFilterRules("*.debug=true\n*.info=true\n*.warning=true\n*.critical=true");
    } else if (lowerLevel == "info") {
        QLoggingCategory::setFilterRules("*.debug=false\n*.info=true\n*.warning=true\n*.critical=true");
    } else if (lowerLevel == "warn") {
        QLoggingCategory::setFilterRules("*.debug=false\n*.info=false\n*.warning=true\n*.critical=true");
    } else if (lowerLevel == "error") {
        QLoggingCategory::setFilterRules("*.debug=false\n*.info=false\n*.warning=false\n*.critical=true");
    }
}