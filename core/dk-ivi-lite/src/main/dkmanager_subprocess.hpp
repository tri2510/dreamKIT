#ifndef DKMANAGER_SUBPROCESS_HPP
#define DKMANAGER_SUBPROCESS_HPP

#include <QObject>
#include <QProcess>
#include <QDebug>
#include <QLoggingCategory>
#include <QStandardPaths>
#include <QDir>

Q_DECLARE_LOGGING_CATEGORY(dkManagerLog)

class DkManagerSubprocess : public QObject
{
    Q_OBJECT

public:
    explicit DkManagerSubprocess(QObject *parent = nullptr);
    ~DkManagerSubprocess();

    bool startManager();
    void stopManager();
    bool isRunning() const;
    
    QString getManagerExecutablePath() const;

public slots:
    void onManagerFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onManagerError(QProcess::ProcessError error);
    void onManagerReadyReadStandardOutput();
    void onManagerReadyReadStandardError();

signals:
    void managerStarted();
    void managerStopped();
    void managerError(const QString &errorMessage);

private:
    QProcess *m_managerProcess;
    QString m_executablePath;
    bool m_isEmbedded;
    
    void setupProcess();
    bool findManagerExecutable();
};

#endif // DKMANAGER_SUBPROCESS_HPP