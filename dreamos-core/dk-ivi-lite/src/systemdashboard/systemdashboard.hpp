#ifndef SYSTEMDASHBOARD_HPP
#define SYSTEMDASHBOARD_HPP

#include <QObject>
#include <QVariantList>
#include <QTimer>
#include <QProcess>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QString>

struct ServiceInfo {
    QString name;
    QString description;
    QString status;
    QString type; // "docker" or "native"
    QString image;
    QString uptime;
    QString port;
    double cpuUsage;
    double memoryUsage;
};

Q_DECLARE_METATYPE(ServiceInfo)

class SystemDashboardBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList services READ services NOTIFY serviceStatusChanged)
    Q_PROPERTY(bool systemHealthy READ systemHealthy NOTIFY systemHealthChanged)
    Q_PROPERTY(double cpuUsage READ cpuUsage NOTIFY systemStatsChanged)
    Q_PROPERTY(double memoryUsage READ memoryUsage NOTIFY systemStatsChanged)
    Q_PROPERTY(double diskUsage READ diskUsage NOTIFY systemStatsChanged)
    Q_PROPERTY(double memoryUsedGB READ memoryUsedGB NOTIFY systemStatsChanged)
    Q_PROPERTY(double diskUsedGB READ diskUsedGB NOTIFY systemStatsChanged)

public:
    explicit SystemDashboardBackend(QObject *parent = nullptr);
    
    QVariantList services() const;
    bool systemHealthy() const;
    double cpuUsage() const;
    double memoryUsage() const;
    double diskUsage() const;
    double memoryUsedGB() const;
    double diskUsedGB() const;

public slots:
    void startMonitoring();
    void stopMonitoring();
    void refreshServices();
    void startService(const QString &serviceName);
    void stopService(const QString &serviceName);
    void executeCommand(const QString &command);

signals:
    void serviceStatusChanged();
    void systemHealthChanged();
    void systemStatsChanged();
    void consoleOutputChanged(const QString &output);

private slots:
    void updateSystemStats();
    void updateDockerServices();
    void updateNativeServices();
    void onCommandFinished();

private:
    void initializeServices();
    void updateServiceInfo(const QString &name, const QString &status, const QString &uptime = "");
    void updateSystemHealth();
    void parseDockerStats(const QString &output);
    void parseSystemStats(const QString &output);
    QString formatUptime(const QString &createdTime);
    bool isDockerService(const QString &serviceName);
    
    QVariantList m_services;
    QTimer *m_monitoringTimer;
    QTimer *m_statsTimer;
    QProcess *m_dockerProcess;
    QProcess *m_systemProcess;
    QProcess *m_commandProcess;
    
    bool m_systemHealthy;
    double m_cpuUsage;
    double m_memoryUsage;
    double m_diskUsage;
    double m_memoryUsedGB;
    double m_diskUsedGB;
    double m_memoryTotalGB;
    double m_diskTotalGB;
    
    // SDV service definitions
    QStringList m_dockerServices;
    QStringList m_nativeServices;
    QMap<QString, QString> m_serviceDescriptions;
};

#endif // SYSTEMDASHBOARD_HPP