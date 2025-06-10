#include "dkmanager_subprocess.hpp"
#include <QCoreApplication>
#include <QFileInfo>

Q_LOGGING_CATEGORY(dkManagerLog, "dk.ivi.manager")

DkManagerSubprocess::DkManagerSubprocess(QObject *parent)
    : QObject(parent)
    , m_managerProcess(nullptr)
    , m_isEmbedded(true)
{
    setupProcess();
}

DkManagerSubprocess::~DkManagerSubprocess()
{
    stopManager();
}

void DkManagerSubprocess::setupProcess()
{
    if (m_managerProcess) {
        delete m_managerProcess;
    }
    
    m_managerProcess = new QProcess(this);
    
    // Connect signals
    connect(m_managerProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &DkManagerSubprocess::onManagerFinished);
    connect(m_managerProcess, &QProcess::errorOccurred,
            this, &DkManagerSubprocess::onManagerError);
    connect(m_managerProcess, &QProcess::readyReadStandardOutput,
            this, &DkManagerSubprocess::onManagerReadyReadStandardOutput);
    connect(m_managerProcess, &QProcess::readyReadStandardError,
            this, &DkManagerSubprocess::onManagerReadyReadStandardError);
}

bool DkManagerSubprocess::findManagerExecutable()
{
    // Look for dk_manager executable in common locations
    QStringList searchPaths = {
        // Current application directory
        QCoreApplication::applicationDirPath() + "/dk_manager",
        // Relative to dk_ivi executable
        QCoreApplication::applicationDirPath() + "/../dk-manager/dk_manager",
        // In the same container/output directory
        "/app/exec/dk_manager",
        // Local build output
        QDir::currentPath() + "/output/dk-manager/dk_manager",
        // Standard system paths
        "/usr/local/bin/dk_manager",
        "/usr/bin/dk_manager"
    };
    
    for (const QString &path : searchPaths) {
        QFileInfo fileInfo(path);
        if (fileInfo.exists() && fileInfo.isExecutable()) {
            m_executablePath = path;
            qCInfo(dkManagerLog) << "Found dk_manager executable at:" << path;
            return true;
        }
    }
    
    qCWarning(dkManagerLog) << "dk_manager executable not found in any of the search paths:";
    for (const QString &path : searchPaths) {
        qCDebug(dkManagerLog) << "  -" << path;
    }
    
    return false;
}

QString DkManagerSubprocess::getManagerExecutablePath() const
{
    return m_executablePath;
}

bool DkManagerSubprocess::startManager()
{
    if (isRunning()) {
        qCWarning(dkManagerLog) << "dk_manager is already running";
        return true;
    }
    
    if (!findManagerExecutable()) {
        QString error = "dk_manager executable not found";
        qCCritical(dkManagerLog) << error;
        emit managerError(error);
        return false;
    }
    
    // Prepare arguments for embedded mode
    QStringList arguments;
    if (m_isEmbedded) {
        arguments << "--embedded" << "--no-remote";
    }
    
    qCInfo(dkManagerLog) << "Starting dk_manager subprocess:" << m_executablePath << arguments;
    
    // Set up environment
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert("DK_EMBEDDED_MODE", "1");
    env.insert("DK_MOCK_MODE", "1");  // Disable Docker operations
    env.insert("PATH", "/bin:/usr/bin"); // Limited PATH to prevent Docker access
    m_managerProcess->setProcessEnvironment(env);
    
    // Start the process
    m_managerProcess->start(m_executablePath, arguments);
    
    if (!m_managerProcess->waitForStarted(5000)) {
        QString error = QString("Failed to start dk_manager: %1").arg(m_managerProcess->errorString());
        qCCritical(dkManagerLog) << error;
        emit managerError(error);
        return false;
    }
    
    qCInfo(dkManagerLog) << "dk_manager subprocess started successfully with PID:" << m_managerProcess->processId();
    emit managerStarted();
    return true;
}

void DkManagerSubprocess::stopManager()
{
    if (!isRunning()) {
        return;
    }
    
    qCInfo(dkManagerLog) << "Stopping dk_manager subprocess...";
    
    // Try graceful termination first
    m_managerProcess->terminate();
    
    if (!m_managerProcess->waitForFinished(5000)) {
        qCWarning(dkManagerLog) << "dk_manager did not terminate gracefully, killing...";
        m_managerProcess->kill();
        m_managerProcess->waitForFinished(2000);
    }
    
    qCInfo(dkManagerLog) << "dk_manager subprocess stopped";
    emit managerStopped();
}

bool DkManagerSubprocess::isRunning() const
{
    return m_managerProcess && (m_managerProcess->state() == QProcess::Running);
}

void DkManagerSubprocess::onManagerFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    QString statusStr = (exitStatus == QProcess::NormalExit) ? "normal" : "crashed";
    qCInfo(dkManagerLog) << "dk_manager subprocess finished with exit code:" << exitCode << "status:" << statusStr;
    
    if (exitStatus == QProcess::CrashExit) {
        emit managerError(QString("dk_manager crashed with exit code: %1").arg(exitCode));
    }
    
    emit managerStopped();
}

void DkManagerSubprocess::onManagerError(QProcess::ProcessError error)
{
    QString errorStr;
    switch (error) {
        case QProcess::FailedToStart:
            errorStr = "Failed to start dk_manager";
            break;
        case QProcess::Crashed:
            errorStr = "dk_manager crashed";
            break;
        case QProcess::Timedout:
            errorStr = "dk_manager timed out";
            break;
        case QProcess::WriteError:
            errorStr = "Write error to dk_manager";
            break;
        case QProcess::ReadError:
            errorStr = "Read error from dk_manager";
            break;
        default:
            errorStr = "Unknown error with dk_manager";
            break;
    }
    
    qCCritical(dkManagerLog) << "dk_manager process error:" << errorStr;
    emit managerError(errorStr);
}

void DkManagerSubprocess::onManagerReadyReadStandardOutput()
{
    QByteArray data = m_managerProcess->readAllStandardOutput();
    QString output = QString::fromUtf8(data).trimmed();
    
    if (!output.isEmpty()) {
        qCDebug(dkManagerLog) << "[dk_manager stdout]" << output;
    }
}

void DkManagerSubprocess::onManagerReadyReadStandardError()
{
    QByteArray data = m_managerProcess->readAllStandardError();
    QString output = QString::fromUtf8(data).trimmed();
    
    if (!output.isEmpty()) {
        qCInfo(dkManagerLog) << "[dk_manager stderr]" << output;
    }
}