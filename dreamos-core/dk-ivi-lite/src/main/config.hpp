#ifndef CONFIG_HPP
#define CONFIG_HPP

#include <QString>
#include <QLoggingCategory>

/**
 * Configuration class for dk_ivi application
 * Handles CLI arguments and configuration management
 */
class Config {
public:
    Config();
    
    // Parse command line arguments
    bool parseArguments(int argc, char *argv[]);
    
    // Show help message
    void showHelp(const QString& programName) const;
    
    // Configuration getters
    QString configFile() const { return m_configFile; }
    QString logLevel() const { return m_logLevel; }
    QString canInterface() const { return m_canInterface; }
    QString vapiDataBroker() const { return m_vapiDataBroker; }
    QString systemDataBroker() const { return m_systemDataBroker; }
    QString qtBackend() const { return m_qtBackend; }
    bool enableDebug() const { return m_enableDebug; }
    bool showVersion() const { return m_showVersion; }
    bool showHelp() const { return m_showHelp; }
    
    // Apply configuration to Qt logging
    void applyLoggingConfiguration() const;
    
    // Apply configuration to Qt backend
    void applyQtConfiguration() const;
    
    // Print current configuration
    void printConfiguration() const;

private:
    QString m_configFile;
    QString m_logLevel;
    QString m_canInterface;
    QString m_vapiDataBroker;
    QString m_systemDataBroker;
    QString m_qtBackend;
    bool m_enableDebug;
    bool m_showVersion;
    bool m_showHelp;
    
    // Load default values
    void loadDefaults();
    
    // Validate configuration
    bool validateConfiguration() const;
    
    // Set logging level
    void setLoggingLevel(const QString& level) const;
};

#endif // CONFIG_HPP