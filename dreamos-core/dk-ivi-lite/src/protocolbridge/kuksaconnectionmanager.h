#ifndef KUKSACONNECTIONMANAGER_H
#define KUKSACONNECTIONMANAGER_H

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <memory>

enum class KuksaConnectionMode {
    DefaultDocker,      // Use default KUKSA Docker container
    CustomEndpoint,     // Connect to custom IP:port
    LocalBinary        // Use local KUKSA installation
};

enum class KuksaConnectionStatus {
    Disconnected,
    Connecting,
    Connected,
    Error
};

Q_DECLARE_METATYPE(KuksaConnectionMode)
Q_DECLARE_METATYPE(KuksaConnectionStatus)

class KuksaConnectionManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(KuksaConnectionStatus status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString endpoint READ endpoint WRITE setEndpoint NOTIFY endpointChanged)
    Q_PROPERTY(QString dockerImage READ dockerImage WRITE setDockerImage NOTIFY dockerImageChanged)
    Q_PROPERTY(bool autoStart READ autoStart WRITE setAutoStart NOTIFY autoStartChanged)
    Q_PROPERTY(QString connectionInfo READ connectionInfo NOTIFY connectionInfoChanged)
    Q_PROPERTY(QString dockerStatus READ dockerStatus NOTIFY dockerStatusChanged)

public:
    explicit KuksaConnectionManager(QObject *parent = nullptr);
    ~KuksaConnectionManager();
    
    // Properties
    KuksaConnectionStatus status() const { return m_status; }
    QString endpoint() const { return m_endpoint; }
    QString dockerImage() const { return m_dockerImage; }
    bool autoStart() const { return m_autoStart; }
    QString connectionInfo() const { return m_connectionInfo; }
    QString dockerStatus() const { return m_dockerStatus; }
    
    void setEndpoint(const QString &endpoint);
    void setDockerImage(const QString &image);
    void setAutoStart(bool autoStart);

public slots:
    // Connection management
    void connectToKuksa();
    void disconnectFromKuksa();
    void startDefaultDocker();
    void stopDefaultDocker();
    void restartDocker();
    
    // Configuration
    void setConnectionMode(KuksaConnectionMode mode);
    void setCustomEndpoint(const QString &host, int port);
    void loadConfiguration(const QString &configFile);
    void saveConfiguration(const QString &configFile);
    
    // Docker management
    void pullLatestKuksaImage();
    void showDockerLogs();
    void inspectDockerContainer();
    QString getDockerContainerStatus() const;

signals:
    void statusChanged();
    void endpointChanged();
    void dockerImageChanged();
    void autoStartChanged();
    void connectionInfoChanged();
    void dockerStatusChanged();
    void connectionError(const QString &error);

private slots:
    void handleDockerProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void handleDockerProcessError();
    void checkConnectionHealth();
    void updateConnectionInfo();
    void handleHealthCheckReply();

private:
    void setStatus(KuksaConnectionStatus status);
    void startHealthCheck();
    void stopHealthCheck();
    bool isDockerRunning() const;
    void updateDockerStatus();
    void executeDockerCommand(const QString &command);
    
    KuksaConnectionMode m_mode = KuksaConnectionMode::DefaultDocker;
    KuksaConnectionStatus m_status = KuksaConnectionStatus::Disconnected;
    QString m_endpoint = "127.0.0.1:55555";
    QString m_dockerImage = "ghcr.io/eclipse/kuksa.val/kuksa-databroker:latest";
    bool m_autoStart = true;
    QString m_connectionInfo;
    QString m_dockerStatus = "Not Running";
    
    std::unique_ptr<QProcess> m_dockerProcess;
    QTimer *m_healthCheckTimer;
    QNetworkAccessManager *m_networkManager;
    QString m_dockerContainerId;
    QString m_customHost = "127.0.0.1";
    int m_customPort = 55555;
};

#endif // KUKSACONNECTIONMANAGER_H