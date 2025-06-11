#include "kuksaconnectionmanager.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QNetworkRequest>
#include <QUrl>

KuksaConnectionManager::KuksaConnectionManager(QObject *parent)
    : QObject(parent)
    , m_dockerProcess(std::make_unique<QProcess>(this))
    , m_healthCheckTimer(new QTimer(this))
    , m_networkManager(new QNetworkAccessManager(this))
{
    // Setup health check timer
    m_healthCheckTimer->setInterval(5000); // Check every 5 seconds
    connect(m_healthCheckTimer, &QTimer::timeout, this, &KuksaConnectionManager::checkConnectionHealth);
    
    // Setup docker process connections
    connect(m_dockerProcess.get(), QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &KuksaConnectionManager::handleDockerProcessFinished);
    connect(m_dockerProcess.get(), &QProcess::errorOccurred,
            this, &KuksaConnectionManager::handleDockerProcessError);
    
    // Initial status update
    updateDockerStatus();
    updateConnectionInfo();
    
    // Auto-start if enabled
    if (m_autoStart && m_mode == KuksaConnectionMode::DefaultDocker) {
        QTimer::singleShot(1000, this, &KuksaConnectionManager::startDefaultDocker);
    }
}

KuksaConnectionManager::~KuksaConnectionManager() {
    if (m_healthCheckTimer->isActive()) {
        m_healthCheckTimer->stop();
    }
    
    if (m_dockerProcess && m_dockerProcess->state() != QProcess::NotRunning) {
        m_dockerProcess->kill();
        m_dockerProcess->waitForFinished(3000);
    }
}

void KuksaConnectionManager::setEndpoint(const QString &endpoint) {
    if (m_endpoint != endpoint) {
        m_endpoint = endpoint;
        emit endpointChanged();
        updateConnectionInfo();
    }
}

void KuksaConnectionManager::setDockerImage(const QString &image) {
    if (m_dockerImage != image) {
        m_dockerImage = image;
        emit dockerImageChanged();
    }
}

void KuksaConnectionManager::setAutoStart(bool autoStart) {
    if (m_autoStart != autoStart) {
        m_autoStart = autoStart;
        emit autoStartChanged();
    }
}

void KuksaConnectionManager::connectToKuksa() {
    if (m_status == KuksaConnectionStatus::Connecting || 
        m_status == KuksaConnectionStatus::Connected) {
        return;
    }
    
    setStatus(KuksaConnectionStatus::Connecting);
    
    if (m_mode == KuksaConnectionMode::DefaultDocker) {
        // Start Docker container if not running
        if (!isDockerRunning()) {
            startDefaultDocker();
        } else {
            // Container is already running, just check connection
            startHealthCheck();
        }
    } else {
        // Direct connection to custom endpoint
        startHealthCheck();
    }
}

void KuksaConnectionManager::disconnectFromKuksa() {
    stopHealthCheck();
    setStatus(KuksaConnectionStatus::Disconnected);
}

void KuksaConnectionManager::startDefaultDocker() {
    qDebug() << "Starting KUKSA Docker container...";
    
    // Stop existing container first
    executeDockerCommand("docker stop kuksa-databroker 2>/dev/null || true");
    executeDockerCommand("docker rm kuksa-databroker 2>/dev/null || true");
    
    // Build docker run command
    QString dockerCmd = QString("docker run -d --name kuksa-databroker "
                               "--network host "
                               "-p 55555:55555 "
                               "-p 8090:8090 "
                               "%1 "
                               "--address 0.0.0.0 "
                               "--port 55555 "
                               "--log-level info")
                               .arg(m_dockerImage);
    
    qDebug() << "Docker command:" << dockerCmd;
    
    m_dockerProcess->start("bash", QStringList() << "-c" << dockerCmd);
    
    if (!m_dockerProcess->waitForStarted()) {
        setStatus(KuksaConnectionStatus::Error);
        emit connectionError("Failed to start Docker process");
        return;
    }
    
    // Wait a moment for container to start, then check connection
    QTimer::singleShot(3000, this, &KuksaConnectionManager::connectToKuksa);
}

void KuksaConnectionManager::stopDefaultDocker() {
    qDebug() << "Stopping KUKSA Docker container...";
    
    executeDockerCommand("docker stop kuksa-databroker");
    executeDockerCommand("docker rm kuksa-databroker");
    
    setStatus(KuksaConnectionStatus::Disconnected);
    updateDockerStatus();
}

void KuksaConnectionManager::restartDocker() {
    stopDefaultDocker();
    QTimer::singleShot(2000, this, &KuksaConnectionManager::startDefaultDocker);
}

void KuksaConnectionManager::setConnectionMode(KuksaConnectionMode mode) {
    m_mode = mode;
    updateConnectionInfo();
}

void KuksaConnectionManager::setCustomEndpoint(const QString &host, int port) {
    m_customHost = host;
    m_customPort = port;
    m_endpoint = QString("%1:%2").arg(host).arg(port);
    emit endpointChanged();
    updateConnectionInfo();
}

void KuksaConnectionManager::pullLatestKuksaImage() {
    qDebug() << "Pulling latest KUKSA image:" << m_dockerImage;
    
    QString pullCmd = QString("docker pull %1").arg(m_dockerImage);
    executeDockerCommand(pullCmd);
}

void KuksaConnectionManager::showDockerLogs() {
    QString logsCmd = "docker logs kuksa-databroker -f --tail 50";
    executeDockerCommand(logsCmd);
}

void KuksaConnectionManager::inspectDockerContainer() {
    QString inspectCmd = "docker inspect kuksa-databroker";
    executeDockerCommand(inspectCmd);
}

QString KuksaConnectionManager::getDockerContainerStatus() const {
    QProcess process;
    process.start("docker", QStringList() << "ps" << "-f" << "name=kuksa-databroker" << "--format" << "{{.Status}}");
    process.waitForFinished(3000);
    
    QString output = process.readAllStandardOutput().trimmed();
    return output.isEmpty() ? "Not Running" : output;
}

void KuksaConnectionManager::handleDockerProcessFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    qDebug() << "Docker process finished with exit code:" << exitCode;
    updateDockerStatus();
    
    if (exitCode == 0 && m_status == KuksaConnectionStatus::Connecting) {
        // Container started successfully, check connection
        QTimer::singleShot(2000, this, &KuksaConnectionManager::startHealthCheck);
    } else if (exitCode != 0) {
        setStatus(KuksaConnectionStatus::Error);
        emit connectionError(QString("Docker process failed with exit code: %1").arg(exitCode));
    }
}

void KuksaConnectionManager::handleDockerProcessError() {
    qDebug() << "Docker process error:" << m_dockerProcess->errorString();
    setStatus(KuksaConnectionStatus::Error);
    emit connectionError("Docker process error: " + m_dockerProcess->errorString());
}

void KuksaConnectionManager::checkConnectionHealth() {
    // Try to connect to KUKSA gRPC endpoint to check health
    QString host = m_customHost;
    int port = m_customPort;
    
    if (m_mode == KuksaConnectionMode::DefaultDocker) {
        host = "127.0.0.1";
        port = 55555;
    }
    
    // For now, we'll do a simple TCP connection test
    // In a real implementation, you'd use gRPC client
    QNetworkRequest request;
    request.setUrl(QUrl(QString("http://%1:%2/health").arg(host).arg(port + 8090 - 55555))); // Health endpoint usually on different port
    request.setRawHeader("User-Agent", "DreamKIT-ProtocolBridge");
    
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, &KuksaConnectionManager::handleHealthCheckReply);
    
    // Timeout after 3 seconds
    QTimer::singleShot(3000, reply, &QNetworkReply::abort);
}

void KuksaConnectionManager::handleHealthCheckReply() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    reply->deleteLater();
    
    if (reply->error() == QNetworkReply::NoError) {
        if (m_status != KuksaConnectionStatus::Connected) {
            setStatus(KuksaConnectionStatus::Connected);
            qDebug() << "KUKSA connection established";
        }
    } else {
        // Try alternative connection test - check if Docker container is running
        if (m_mode == KuksaConnectionMode::DefaultDocker && isDockerRunning()) {
            // Container is running but health check failed - assume it's starting up
            if (m_status == KuksaConnectionStatus::Connecting) {
                // Keep trying
                return;
            } else {
                setStatus(KuksaConnectionStatus::Connected);
            }
        } else {
            if (m_status != KuksaConnectionStatus::Error) {
                setStatus(KuksaConnectionStatus::Error);
                emit connectionError("Health check failed: " + reply->errorString());
            }
        }
    }
}

void KuksaConnectionManager::updateConnectionInfo() {
    QString info;
    
    switch (m_mode) {
    case KuksaConnectionMode::DefaultDocker:
        info = QString("Mode: Docker Container\n"
                      "Image: %1\n"
                      "Endpoint: %2\n"
                      "Auto-start: %3\n"
                      "Status: %4")
                      .arg(m_dockerImage)
                      .arg(m_endpoint)
                      .arg(m_autoStart ? "Yes" : "No")
                      .arg(m_dockerStatus);
        break;
        
    case KuksaConnectionMode::CustomEndpoint:
        info = QString("Mode: Custom Endpoint\n"
                      "Host: %1\n"
                      "Port: %2\n"
                      "Endpoint: %3")
                      .arg(m_customHost)
                      .arg(m_customPort)
                      .arg(m_endpoint);
        break;
        
    case KuksaConnectionMode::LocalBinary:
        info = "Mode: Local Binary\n"
               "Binary: kuksa-databroker\n"
               "Endpoint: " + m_endpoint;
        break;
    }
    
    if (m_connectionInfo != info) {
        m_connectionInfo = info;
        emit connectionInfoChanged();
    }
}

void KuksaConnectionManager::setStatus(KuksaConnectionStatus status) {
    if (m_status != status) {
        m_status = status;
        emit statusChanged();
        
        // Manage health check timer based on status
        if (status == KuksaConnectionStatus::Connected || 
            status == KuksaConnectionStatus::Connecting) {
            startHealthCheck();
        } else {
            stopHealthCheck();
        }
        
        updateConnectionInfo();
    }
}

void KuksaConnectionManager::startHealthCheck() {
    if (!m_healthCheckTimer->isActive()) {
        m_healthCheckTimer->start();
        // Do immediate check
        checkConnectionHealth();
    }
}

void KuksaConnectionManager::stopHealthCheck() {
    if (m_healthCheckTimer->isActive()) {
        m_healthCheckTimer->stop();
    }
}

bool KuksaConnectionManager::isDockerRunning() const {
    QProcess process;
    process.start("docker", QStringList() << "ps" << "-q" << "-f" << "name=kuksa-databroker");
    process.waitForFinished(3000);
    
    QString output = process.readAllStandardOutput().trimmed();
    return !output.isEmpty();
}

void KuksaConnectionManager::updateDockerStatus() {
    QString newStatus = getDockerContainerStatus();
    if (m_dockerStatus != newStatus) {
        m_dockerStatus = newStatus;
        emit dockerStatusChanged();
        updateConnectionInfo();
    }
}

void KuksaConnectionManager::executeDockerCommand(const QString &command) {
    QProcess::startDetached("bash", QStringList() << "-c" << command);
}

void KuksaConnectionManager::loadConfiguration(const QString &configFile) {
    QFile file(configFile);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Cannot open config file:" << configFile;
        return;
    }
    
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &error);
    if (error.error != QJsonParseError::NoError) {
        qWarning() << "JSON parse error:" << error.errorString();
        return;
    }
    
    QJsonObject config = doc.object();
    
    if (config.contains("endpoint")) {
        setEndpoint(config["endpoint"].toString());
    }
    
    if (config.contains("dockerImage")) {
        setDockerImage(config["dockerImage"].toString());
    }
    
    if (config.contains("autoStart")) {
        setAutoStart(config["autoStart"].toBool());
    }
    
    if (config.contains("mode")) {
        QString mode = config["mode"].toString();
        if (mode == "docker") {
            setConnectionMode(KuksaConnectionMode::DefaultDocker);
        } else if (mode == "custom") {
            setConnectionMode(KuksaConnectionMode::CustomEndpoint);
        } else if (mode == "local") {
            setConnectionMode(KuksaConnectionMode::LocalBinary);
        }
    }
}

void KuksaConnectionManager::saveConfiguration(const QString &configFile) {
    QJsonObject config;
    config["endpoint"] = m_endpoint;
    config["dockerImage"] = m_dockerImage;
    config["autoStart"] = m_autoStart;
    
    QString mode;
    switch (m_mode) {
    case KuksaConnectionMode::DefaultDocker: mode = "docker"; break;
    case KuksaConnectionMode::CustomEndpoint: mode = "custom"; break;
    case KuksaConnectionMode::LocalBinary: mode = "local"; break;
    }
    config["mode"] = mode;
    
    QJsonDocument doc(config);
    
    QFile file(configFile);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(doc.toJson());
    } else {
        qWarning() << "Cannot save config file:" << configFile;
    }
}