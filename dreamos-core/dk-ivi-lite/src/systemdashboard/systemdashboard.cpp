#include "systemdashboard.hpp"
#include <QDebug>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QVariantMap>
#include <QRegularExpression>

SystemDashboardBackend::SystemDashboardBackend(QObject *parent)
    : QObject(parent)
    , m_monitoringTimer(new QTimer(this))
    , m_statsTimer(new QTimer(this))
    , m_dockerProcess(new QProcess(this))
    , m_systemProcess(new QProcess(this))
    , m_commandProcess(new QProcess(this))
    , m_systemHealthy(false)
    , m_cpuUsage(0.0)
    , m_memoryUsage(0.0)
    , m_diskUsage(0.0)
    , m_memoryUsedGB(0.0)
    , m_diskUsedGB(0.0)
    , m_memoryTotalGB(8.0)
    , m_diskTotalGB(32.0)
{
    // Define SDV services based on installation scripts
    m_dockerServices << "sdv-runtime" << "dk_manager" << "dk_ivi" 
                     << "dk_appinstallservice" << "kuksa-client" << "dk_local_registry";
    
    m_nativeServices << "dk_can_provider" << "dk_service_manager" << "system_monitor";
    
    // Service descriptions
    m_serviceDescriptions["sdv-runtime"] = "Eclipse KUKSA databroker (port 55555)";
    m_serviceDescriptions["dk_manager"] = "DreamOS core manager with Docker access";
    m_serviceDescriptions["dk_ivi"] = "In-Vehicle Infotainment interface";
    m_serviceDescriptions["dk_appinstallservice"] = "Application lifecycle management";
    m_serviceDescriptions["kuksa-client"] = "Vehicle signal specification client";
    m_serviceDescriptions["dk_local_registry"] = "Local Docker registry";
    m_serviceDescriptions["dk_can_provider"] = "CAN bus data provider";
    m_serviceDescriptions["dk_service_manager"] = "Native service manager";
    m_serviceDescriptions["system_monitor"] = "System resource monitor";
    
    initializeServices();
    
    // Setup timers
    m_monitoringTimer->setInterval(5000); // 5 seconds
    m_statsTimer->setInterval(2000); // 2 seconds
    
    connect(m_monitoringTimer, &QTimer::timeout, this, &SystemDashboardBackend::updateDockerServices);
    connect(m_statsTimer, &QTimer::timeout, this, &SystemDashboardBackend::updateSystemStats);
    connect(m_commandProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &SystemDashboardBackend::onCommandFinished);
}

void SystemDashboardBackend::initializeServices()
{
    m_services.clear();
    
    // Initialize Docker services
    for (const QString &serviceName : m_dockerServices) {
        QVariantMap service;
        service["name"] = serviceName;
        service["description"] = m_serviceDescriptions.value(serviceName, "Docker service");
        service["status"] = "unknown";
        service["type"] = "docker";
        service["uptime"] = "";
        service["cpuUsage"] = 0.0;
        service["memoryUsage"] = 0.0;
        m_services.append(service);
    }
    
    // Initialize native services
    for (const QString &serviceName : m_nativeServices) {
        QVariantMap service;
        service["name"] = serviceName;
        service["description"] = m_serviceDescriptions.value(serviceName, "Native service");
        service["status"] = "unknown";
        service["type"] = "native";
        service["uptime"] = "";
        service["cpuUsage"] = 0.0;
        service["memoryUsage"] = 0.0;
        m_services.append(service);
    }
    
    emit serviceStatusChanged();
}

QVariantList SystemDashboardBackend::services() const
{
    return m_services;
}

bool SystemDashboardBackend::systemHealthy() const
{
    return m_systemHealthy;
}

double SystemDashboardBackend::cpuUsage() const
{
    return m_cpuUsage;
}

double SystemDashboardBackend::memoryUsage() const
{
    return m_memoryUsage;
}

double SystemDashboardBackend::diskUsage() const
{
    return m_diskUsage;
}

double SystemDashboardBackend::memoryUsedGB() const
{
    return m_memoryUsedGB;
}

double SystemDashboardBackend::diskUsedGB() const
{
    return m_diskUsedGB;
}

void SystemDashboardBackend::startMonitoring()
{
    qDebug() << "Starting system monitoring...";
    refreshServices();
    updateSystemStats();
    
    m_monitoringTimer->start();
    m_statsTimer->start();
}

void SystemDashboardBackend::stopMonitoring()
{
    qDebug() << "Stopping system monitoring...";
    m_monitoringTimer->stop();
    m_statsTimer->stop();
}

void SystemDashboardBackend::refreshServices()
{
    updateDockerServices();
    updateNativeServices();
}

void SystemDashboardBackend::updateDockerServices()
{
    // Get Docker container status
    QProcess dockerPs;
    dockerPs.start("docker", QStringList() << "ps" << "-a" << "--format" 
                   << "{{.Names}}|{{.Status}}|{{.CreatedAt}}|{{.Image}}");
    dockerPs.waitForFinished(3000);
    
    if (dockerPs.exitCode() != 0) {
        qWarning() << "Failed to get Docker status:" << dockerPs.readAllStandardError();
        return;
    }
    
    QString output = dockerPs.readAllStandardOutput();
    QStringList lines = output.split('\n', Qt::SkipEmptyParts);
    
    // Reset all Docker services to stopped
    for (int i = 0; i < m_services.size(); ++i) {
        QVariantMap service = m_services[i].toMap();
        if (service["type"].toString() == "docker") {
            service["status"] = "stopped";
            service["uptime"] = "";
            m_services[i] = service;
        }
    }
    
    // Update with actual status
    for (const QString &line : lines) {
        QStringList parts = line.split('|');
        if (parts.size() >= 3) {
            QString containerName = parts[0];
            QString status = parts[1];
            QString createdAt = parts[2];
            
            // Update service status
            for (int i = 0; i < m_services.size(); ++i) {
                QVariantMap service = m_services[i].toMap();
                if (service["name"].toString() == containerName && service["type"].toString() == "docker") {
                    if (status.contains("Up", Qt::CaseInsensitive)) {
                        service["status"] = "running";
                        service["uptime"] = formatUptime(createdAt);
                    } else {
                        service["status"] = "stopped";
                        service["uptime"] = "";
                    }
                    m_services[i] = service;
                    break;
                }
            }
        }
    }
    
    // Get Docker stats for running containers
    QProcess dockerStats;
    dockerStats.start("docker", QStringList() << "stats" << "--no-stream" << "--format" 
                      << "{{.Container}}|{{.CPUPerc}}|{{.MemUsage}}");
    dockerStats.waitForFinished(3000);
    
    if (dockerStats.exitCode() == 0) {
        QString statsOutput = dockerStats.readAllStandardOutput();
        parseDockerStats(statsOutput);
    }
    
    updateSystemHealth();
    emit serviceStatusChanged();
}

void SystemDashboardBackend::updateNativeServices()
{
    // Check native services using ps command
    QProcess psProcess;
    psProcess.start("ps", QStringList() << "aux");
    psProcess.waitForFinished(3000);
    
    if (psProcess.exitCode() != 0) {
        return;
    }
    
    QString output = psProcess.readAllStandardOutput();
    
    // Update native service status based on process names
    for (int i = 0; i < m_services.size(); ++i) {
        QVariantMap service = m_services[i].toMap();
        if (service["type"].toString() == "native") {
            QString serviceName = service["name"].toString();
            if (output.contains(serviceName)) {
                service["status"] = "running";
            } else {
                service["status"] = "stopped";
            }
            m_services[i] = service;
        }
    }
}

void SystemDashboardBackend::updateSystemStats()
{
    // Get CPU usage
    QProcess topProcess;
    topProcess.start("top", QStringList() << "-bn1");
    topProcess.waitForFinished(3000);
    
    if (topProcess.exitCode() == 0) {
        QString output = topProcess.readAllStandardOutput();
        parseSystemStats(output);
    }
    
    // Get memory usage
    QProcess freeProcess;
    freeProcess.start("free", QStringList() << "-m");
    freeProcess.waitForFinished(3000);
    
    if (freeProcess.exitCode() == 0) {
        QString output = freeProcess.readAllStandardOutput();
        QStringList lines = output.split('\n');
        for (const QString &line : lines) {
            if (line.startsWith("Mem:")) {
                QStringList parts = line.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
                if (parts.size() >= 3) {
                    double total = parts[1].toDouble();
                    double used = parts[2].toDouble();
                    m_memoryTotalGB = total / 1024.0;
                    m_memoryUsedGB = used / 1024.0;
                    m_memoryUsage = (used / total) * 100.0;
                }
                break;
            }
        }
    }
    
    // Get disk usage
    QProcess dfProcess;
    dfProcess.start("df", QStringList() << "-h" << "/");
    dfProcess.waitForFinished(3000);
    
    if (dfProcess.exitCode() == 0) {
        QString output = dfProcess.readAllStandardOutput();
        QStringList lines = output.split('\n');
        if (lines.size() > 1) {
            QStringList parts = lines[1].split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
            if (parts.size() >= 5) {
                QString sizeStr = parts[1];
                QString usedStr = parts[2];
                QString percentStr = parts[4];
                
                // Convert sizes (remove G suffix and convert to double)
                m_diskTotalGB = sizeStr.replace("G", "").toDouble();
                m_diskUsedGB = usedStr.replace("G", "").toDouble();
                m_diskUsage = percentStr.replace("%", "").toDouble();
            }
        }
    }
    
    emit systemStatsChanged();
}

void SystemDashboardBackend::parseDockerStats(const QString &output)
{
    QStringList lines = output.split('\n', Qt::SkipEmptyParts);
    
    for (const QString &line : lines) {
        QStringList parts = line.split('|');
        if (parts.size() >= 3) {
            QString containerName = parts[0];
            QString cpuPercent = parts[1].replace("%", "");
            QString memUsage = parts[2];
            
            // Update service with stats
            for (int i = 0; i < m_services.size(); ++i) {
                QVariantMap service = m_services[i].toMap();
                if (service["name"].toString() == containerName) {
                    service["cpuUsage"] = cpuPercent.toDouble();
                    // Parse memory usage (e.g., "123.4MiB / 2GiB")
                    QStringList memParts = memUsage.split(" / ");
                    if (memParts.size() >= 1) {
                        QString usedMem = memParts[0].replace("MiB", "").replace("GiB", "");
                        service["memoryUsage"] = usedMem.toDouble();
                    }
                    m_services[i] = service;
                    break;
                }
            }
        }
    }
}

void SystemDashboardBackend::parseSystemStats(const QString &output)
{
    QStringList lines = output.split('\n');
    for (const QString &line : lines) {
        if (line.contains("%Cpu(s):")) {
            // Parse CPU usage from top output
            QRegularExpression re("(\\d+\\.\\d+)\\s*us");
            QRegularExpressionMatch match = re.match(line);
            if (match.hasMatch()) {
                m_cpuUsage = match.captured(1).toDouble();
            }
            break;
        }
    }
}

QString SystemDashboardBackend::formatUptime(const QString &createdTime)
{
    // Simple uptime formatting - could be enhanced
    QDateTime created = QDateTime::fromString(createdTime.split(' ')[0], Qt::ISODate);
    if (created.isValid()) {
        qint64 seconds = created.secsTo(QDateTime::currentDateTime());
        if (seconds < 60) {
            return QString("%1s").arg(seconds);
        } else if (seconds < 3600) {
            return QString("%1m").arg(seconds / 60);
        } else if (seconds < 86400) {
            return QString("%1h").arg(seconds / 3600);
        } else {
            return QString("%1d").arg(seconds / 86400);
        }
    }
    return "Unknown";
}

void SystemDashboardBackend::updateSystemHealth()
{
    int runningServices = 0;
    int totalCriticalServices = 0;
    
    // Count critical services (sdv-runtime, dk_manager)
    QStringList criticalServices = {"sdv-runtime", "dk_manager"};
    
    for (const QVariant &serviceVar : m_services) {
        QVariantMap service = serviceVar.toMap();
        QString serviceName = service["name"].toString();
        QString status = service["status"].toString();
        
        if (criticalServices.contains(serviceName)) {
            totalCriticalServices++;
            if (status == "running") {
                runningServices++;
            }
        }
    }
    
    bool wasHealthy = m_systemHealthy;
    m_systemHealthy = (runningServices == totalCriticalServices) && (m_cpuUsage < 90.0) && (m_memoryUsage < 90.0);
    
    if (wasHealthy != m_systemHealthy) {
        emit systemHealthChanged();
    }
}

void SystemDashboardBackend::startService(const QString &serviceName)
{
    if (isDockerService(serviceName)) {
        QStringList args;
        args << "start" << serviceName;
        
        QProcess::startDetached("docker", args);
        emit consoleOutputChanged(QString("Starting Docker service: %1").arg(serviceName));
        
        // Refresh services after a short delay
        QTimer::singleShot(2000, this, &SystemDashboardBackend::refreshServices);
    } else {
        // Handle native service start
        emit consoleOutputChanged(QString("Starting native service: %1").arg(serviceName));
        // Implement native service start logic here
    }
}

void SystemDashboardBackend::stopService(const QString &serviceName)
{
    if (isDockerService(serviceName)) {
        QStringList args;
        args << "stop" << serviceName;
        
        QProcess::startDetached("docker", args);
        emit consoleOutputChanged(QString("Stopping Docker service: %1").arg(serviceName));
        
        // Refresh services after a short delay
        QTimer::singleShot(2000, this, &SystemDashboardBackend::refreshServices);
    } else {
        // Handle native service stop
        emit consoleOutputChanged(QString("Stopping native service: %1").arg(serviceName));
        // Implement native service stop logic here
    }
}

void SystemDashboardBackend::executeCommand(const QString &command)
{
    if (m_commandProcess->state() != QProcess::NotRunning) {
        emit consoleOutputChanged("Previous command still running...");
        return;
    }
    
    emit consoleOutputChanged(QString("$ %1").arg(command));
    
    // Define safe commands for SDV system
    QStringList safeCommands = {
        "docker ps", "docker ps -a", "docker images", "docker stats --no-stream",
        "docker logs", "ps aux", "top -bn1", "free -h", "df -h",
        "systemctl status", "journalctl -n 20", "lscpu", "lsmem",
        "ip addr", "netstat -tlnp", "ss -tlnp"
    };
    
    bool commandAllowed = false;
    for (const QString &safeCmd : safeCommands) {
        if (command.startsWith(safeCmd)) {
            commandAllowed = true;
            break;
        }
    }
    
    if (!commandAllowed) {
        emit consoleOutputChanged("Command not allowed for security reasons.");
        emit consoleOutputChanged("Allowed commands: docker ps, docker logs [container], ps aux, top, free, df, systemctl status [service]");
        return;
    }
    
    QStringList arguments = command.split(' ', Qt::SkipEmptyParts);
    QString program = arguments.takeFirst();
    
    m_commandProcess->start(program, arguments);
}

void SystemDashboardBackend::onCommandFinished()
{
    QString output = m_commandProcess->readAllStandardOutput();
    QString error = m_commandProcess->readAllStandardError();
    
    if (!output.isEmpty()) {
        emit consoleOutputChanged(output);
    }
    
    if (!error.isEmpty()) {
        emit consoleOutputChanged(QString("Error: %1").arg(error));
    }
    
    int exitCode = m_commandProcess->exitCode();
    emit consoleOutputChanged(QString("Command finished with exit code: %1").arg(exitCode));
}

bool SystemDashboardBackend::isDockerService(const QString &serviceName)
{
    return m_dockerServices.contains(serviceName);
}