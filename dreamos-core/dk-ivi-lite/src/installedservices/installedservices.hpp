#ifndef INSTALLEDSERVICES_H
#define INSTALLEDSERVICES_H

#include <QObject>
#include <QTextStream>
#include <QFile>
#include "QString"
#include <QThread>
#include <QList>
#include <QFileSystemWatcher>
#include <QTimer>

typedef struct {
    QString id;
    QString category;
    QString name;
    QString author;
    QString rating;
    QString noofdownload;
    QString iconPath;
    QString foldername;
    QString packagelink;
    QString deploytarget;
    bool isInstalled;
    bool isSubscribed;
} ServicesListStruct;

void readServicesList(const QString searchName, QList<ServicesListStruct> &ServicesListInfo);


class ServicesAsync;

class CheckAppRunningThread : public QThread
{
    Q_OBJECT

public:
    CheckAppRunningThread(ServicesAsync *parent);
    void run();
    void checkRunningAppSts();
    bool isVipReachable();

private:
    ServicesAsync *m_serviceAsync = nullptr;
};

class InstalledServicesCheckThread : public QThread
{
    Q_OBJECT

public:
    InstalledServicesCheckThread(ServicesAsync *parent);
    void run();
    void triggerCheckAppStart(QString id, QString name);

Q_SIGNALS:
    void resultReady(QString appId, bool isStarted, QString msg);

private:
    QString m_appId;
    QString m_appName;
    bool m_istriggeredAppStart = false;
    ServicesAsync *m_serviceAsync = nullptr;
    QFileSystemWatcher *m_filewatcher = nullptr;
};

class ServicesAsync: public QObject
{
    Q_OBJECT
public:
    ServicesAsync();

    void parseSystemCfg();

    Q_INVOKABLE void initInstalledServicesFromDB();

    Q_INVOKABLE void executeServices(int appIdx, const QString name, const QString appId, bool isSubscribed);

    Q_INVOKABLE void removeServices(const int index);

    Q_INVOKABLE void openAppEditor(int idx);

Q_SIGNALS:
    void appendServicesInfoToServicesList(QString name, QString author, QString rating, QString noofdownload, QString icon, bool isInstalled, QString appId, bool isSubscribed);
    void appendLastRowToServicesList(const int noOfServicess);
    void clearServicesListView();
    void updateStartAppMsg(QString appId, bool isStarted, QString msg);
    void updateServicesRunningSts(QString appId, bool isStarted, int idx);

public Q_SLOTS:
    void handleResults(QString appId, bool isStarted, QString msg);
    void fileChanged(const QString& path);

public:
    QList<ServicesListStruct> installedServicesList;
    bool m_is_vip_connected = false;
    bool m_is_vip_service_installed = false;
    
private:
    InstalledServicesCheckThread *m_workerThread;
    CheckAppRunningThread *m_checkAppRunningThread;

    void removeObjectById(const QString &filePath, const QString &idToRemove);
};

#endif //INSTALLEDSERVICES_H
