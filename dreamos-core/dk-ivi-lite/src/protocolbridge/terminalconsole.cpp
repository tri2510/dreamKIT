#include "terminalconsole.h"
#include <QDebug>
#include <QDir>
#include <QStandardPaths>
#include <QDateTime>
#include <QRegularExpression>

TerminalConsole::TerminalConsole(QObject *parent)
    : QObject(parent)
    , m_process(new QProcess(this))
    , m_queueTimer(new QTimer(this))
    , m_timeoutTimer(new QTimer(this))
{
    // Setup process connections
    connect(m_process, &QProcess::readyReadStandardOutput, 
            this, &TerminalConsole::handleProcessOutput);
    connect(m_process, &QProcess::readyReadStandardError, 
            this, &TerminalConsole::handleProcessError);
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &TerminalConsole::handleProcessFinished);
    
    // Setup timers
    m_queueTimer->setSingleShot(true);
    m_queueTimer->setInterval(100);
    connect(m_queueTimer, &QTimer::timeout, this, &TerminalConsole::processCommandQueue);
    
    m_timeoutTimer->setSingleShot(true);
    m_timeoutTimer->setInterval(30000); // 30 second timeout
    connect(m_timeoutTimer, &QTimer::timeout, this, &TerminalConsole::interruptCommand);
    
    // Initialize
    setupBuiltinCommands();
    m_currentDirectory = QDir::homePath();
    updatePrompt();
    
    // Welcome message
    appendOutput("DreamKIT Terminal Console", "#00ffff");
    appendOutput("Type 'dk-help' for DreamKIT-specific commands", "#ffff00");
    appendOutput("Type 'help' for general help", "#ffff00");
    updatePrompt();
}

TerminalConsole::~TerminalConsole() {
    if (m_process && m_process->state() != QProcess::NotRunning) {
        m_process->kill();
        m_process->waitForFinished(3000);
    }
}

void TerminalConsole::executeCommand(const QString &command) {
    if (command.trimmed().isEmpty()) {
        updatePrompt();
        return;
    }
    
    // Add command to history
    addToHistory(command);
    
    // Show command in output
    appendOutput(m_prompt + command, "#ffffff");
    
    // Check if it's a builtin command
    if (isBuiltinCommand(command.split(' ').first())) {
        executeBuiltinCommand(command);
    } else {
        // Queue system command for execution
        m_commandQueue.enqueue(command);
        if (!m_isRunning) {
            processCommandQueue();
        }
    }
}

void TerminalConsole::interruptCommand() {
    if (m_process && m_process->state() != QProcess::NotRunning) {
        appendOutput("^C", "#ff0000");
        m_process->kill();
        setRunningState(false);
        updatePrompt();
    }
}

void TerminalConsole::sendInput(const QString &input) {
    if (m_process && m_process->state() == QProcess::Running) {
        m_process->write(input.toUtf8() + "\n");
    }
}

void TerminalConsole::clear() {
    m_output.clear();
    m_outputLines.clear();
    emit outputChanged();
    updatePrompt();
}

void TerminalConsole::changeDirectory(const QString &path) {
    QDir dir(path);
    if (dir.exists()) {
        m_currentDirectory = dir.absolutePath();
        QDir::setCurrent(m_currentDirectory);
        emit currentDirectoryChanged();
        updatePrompt();
        appendOutput("Changed directory to: " + m_currentDirectory, "#00ff00");
    } else {
        appendOutput("Directory not found: " + path, "#ff0000");
    }
}

void TerminalConsole::showCurrentDirectory() {
    appendOutput(m_currentDirectory, "#00ff00");
    updatePrompt();
}

void TerminalConsole::listFiles() {
    executeCommand("ls -la");
}

void TerminalConsole::showHelp() {
    executeBuiltinCommand("dk-help");
}

void TerminalConsole::showKuksaStatus() {
    executeBuiltinCommand("dk-kuksa-status");
}

void TerminalConsole::showDockerContainers() {
    executeCommand("docker ps -a");
}

void TerminalConsole::showDockerImages() {
    executeCommand("docker images");
}

void TerminalConsole::connectKuksaCli() {
    executeCommand("kuksa-client --host 127.0.0.1 --port 55555");
}

void TerminalConsole::listVssSignals() {
    executeBuiltinCommand("vss-list");
}

void TerminalConsole::getVssValue(const QString &path) {
    executeBuiltinCommand(QString("vss-get %1").arg(path));
}

void TerminalConsole::setVssValue(const QString &path, const QString &value) {
    executeBuiltinCommand(QString("vss-set %1 %2").arg(path).arg(value));
}

void TerminalConsole::dockerPs() {
    executeCommand("docker ps");
}

void TerminalConsole::dockerImages() {
    executeCommand("docker images");
}

void TerminalConsole::dockerLogs(const QString &container) {
    executeCommand(QString("docker logs %1 --tail 50").arg(container));
}

void TerminalConsole::dockerInspect(const QString &container) {
    executeCommand(QString("docker inspect %1").arg(container));
}

QString TerminalConsole::getPreviousCommand() {
    if (m_history.isEmpty()) return QString();
    
    if (m_historyIndex == -1) {
        m_historyIndex = m_history.size() - 1;
    } else if (m_historyIndex > 0) {
        m_historyIndex--;
    }
    
    return m_historyIndex >= 0 ? m_history.at(m_historyIndex) : QString();
}

QString TerminalConsole::getNextCommand() {
    if (m_history.isEmpty() || m_historyIndex == -1) return QString();
    
    if (m_historyIndex < m_history.size() - 1) {
        m_historyIndex++;
        return m_history.at(m_historyIndex);
    } else {
        m_historyIndex = -1;
        return QString();
    }
}

void TerminalConsole::resetHistoryIndex() {
    m_historyIndex = -1;
}

void TerminalConsole::handleProcessOutput() {
    QByteArray data = m_process->readAllStandardOutput();
    QString output = QString::fromUtf8(data);
    
    // Process output line by line
    QStringList lines = output.split('\n', Qt::KeepEmptyParts);
    for (int i = 0; i < lines.size(); ++i) {
        if (i == lines.size() - 1 && lines[i].isEmpty()) {
            // Skip empty last line (from split)
            continue;
        }
        appendOutput(lines[i], "#00ff00");
    }
}

void TerminalConsole::handleProcessError() {
    QByteArray data = m_process->readAllStandardError();
    QString error = QString::fromUtf8(data);
    
    QStringList lines = error.split('\n', Qt::KeepEmptyParts);
    for (int i = 0; i < lines.size(); ++i) {
        if (i == lines.size() - 1 && lines[i].isEmpty()) {
            continue;
        }
        appendOutput(lines[i], "#ff4444");
    }
}

void TerminalConsole::handleProcessFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    setRunningState(false);
    m_timeoutTimer->stop();
    
    if (exitCode != 0) {
        appendOutput(QString("Process finished with exit code: %1").arg(exitCode), "#ff4444");
    }
    
    emit commandCompleted(m_currentCommand, exitCode);
    m_currentCommand.clear();
    
    updatePrompt();
    
    // Process next command in queue
    if (!m_commandQueue.isEmpty()) {
        m_queueTimer->start();
    }
}

void TerminalConsole::updatePrompt() {
    m_prompt = formatPrompt();
    emit promptChanged();
}

void TerminalConsole::processCommandQueue() {
    if (m_commandQueue.isEmpty() || m_isRunning) {
        return;
    }
    
    QString command = m_commandQueue.dequeue();
    executeSystemCommand(command);
}

void TerminalConsole::appendOutput(const QString &text, const QString &color) {
    // Create output line
    OutputLine line;
    line.text = text;
    line.color = color;
    line.timestamp = QDateTime::currentMSecsSinceEpoch();
    
    m_outputLines.append(line);
    
    // Limit output lines
    while (m_outputLines.size() > m_maxOutputLines) {
        m_outputLines.removeFirst();
    }
    
    // Update output string with color formatting
    QString coloredText = QString("<span style='color: %1'>%2</span>")
                         .arg(color)
                         .arg(text.toHtmlEscaped());
    
    if (!m_output.isEmpty()) {
        m_output += "<br>";
    }
    m_output += coloredText;
    
    emit outputChanged();
}

void TerminalConsole::addToHistory(const QString &command) {
    QString trimmed = command.trimmed();
    if (!trimmed.isEmpty() && (m_history.isEmpty() || m_history.last() != trimmed)) {
        m_history.append(trimmed);
        
        // Limit history size
        while (m_history.size() > 100) {
            m_history.removeFirst();
        }
        
        // Update model
        m_historyModel.setStringList(m_history);
    }
    resetHistoryIndex();
}

void TerminalConsole::executeBuiltinCommand(const QString &command) {
    QStringList parts = command.split(' ', Qt::SkipEmptyParts);
    if (parts.isEmpty()) return;
    
    QString cmd = parts.first().toLower();
    
    if (cmd == "dk-help") {
        appendOutput("DreamKIT Terminal Commands:", "#00ffff");
        appendOutput("  dk-help              - Show this help", "#ffffff");
        appendOutput("  dk-status            - Show DreamKIT system status", "#ffffff");
        appendOutput("  dk-kuksa-status      - Show KUKSA connection status", "#ffffff");
        appendOutput("  kuksa-start          - Start KUKSA Docker container", "#ffffff");
        appendOutput("  kuksa-stop           - Stop KUKSA Docker container", "#ffffff");
        appendOutput("  kuksa-restart        - Restart KUKSA Docker container", "#ffffff");
        appendOutput("  kuksa-logs           - Show KUKSA container logs", "#ffffff");
        appendOutput("  vss-get <path>       - Get VSS signal value", "#ffffff");
        appendOutput("  vss-set <path> <val> - Set VSS signal value", "#ffffff");
        appendOutput("  vss-list             - List available VSS signals", "#ffffff");
        appendOutput("  cd <path>            - Change directory", "#ffffff");
        appendOutput("  pwd                  - Show current directory", "#ffffff");
        appendOutput("  clear                - Clear terminal", "#ffffff");
        
    } else if (cmd == "dk-status") {
        appendOutput("DreamKIT System Status:", "#00ffff");
        appendOutput("  Terminal Console: Active", "#00ff00");
        appendOutput("  Current Directory: " + m_currentDirectory, "#ffffff");
        appendOutput("  Command History: " + QString::number(m_history.size()) + " entries", "#ffffff");
        
    } else if (cmd == "dk-kuksa-status") {
        appendOutput("KUKSA Connection Status:", "#00ffff");
        // This would need to be connected to the KuksaConnectionManager
        appendOutput("  Status: Checking...", "#ffff00");
        appendOutput("  Endpoint: 127.0.0.1:55555", "#ffffff");
        
    } else if (cmd == "kuksa-start") {
        appendOutput("Starting KUKSA Docker container...", "#ffff00");
        executeSystemCommand("docker run -d --name kuksa-databroker --network host -p 55555:55555 ghcr.io/eclipse/kuksa.val/kuksa-databroker:latest");
        
    } else if (cmd == "kuksa-stop") {
        appendOutput("Stopping KUKSA Docker container...", "#ffff00");
        executeSystemCommand("docker stop kuksa-databroker && docker rm kuksa-databroker");
        
    } else if (cmd == "kuksa-restart") {
        appendOutput("Restarting KUKSA Docker container...", "#ffff00");
        executeSystemCommand("docker restart kuksa-databroker");
        
    } else if (cmd == "kuksa-logs") {
        appendOutput("Showing KUKSA Docker logs...", "#ffff00");
        executeSystemCommand("docker logs kuksa-databroker --tail 50");
        
    } else if (cmd == "vss-get") {
        if (parts.size() > 1) {
            QString path = parts[1];
            appendOutput("Getting VSS value for: " + path, "#ffff00");
            // This would need to be connected to KUKSA client
            appendOutput("  Value: (simulation mode)", "#00ff00");
        } else {
            appendOutput("Usage: vss-get <VSS.Path>", "#ff0000");
        }
        
    } else if (cmd == "vss-set") {
        if (parts.size() > 2) {
            QString path = parts[1];
            QString value = parts[2];
            appendOutput("Setting VSS value: " + path + " = " + value, "#ffff00");
            // This would need to be connected to KUKSA client
            appendOutput("  Success (simulation mode)", "#00ff00");
        } else {
            appendOutput("Usage: vss-set <VSS.Path> <value>", "#ff0000");
        }
        
    } else if (cmd == "vss-list") {
        appendOutput("Available VSS Signals:", "#00ffff");
        appendOutput("  Vehicle.Speed", "#ffffff");
        appendOutput("  Vehicle.Powertrain.CombustionEngine.Speed", "#ffffff");
        appendOutput("  Vehicle.Cabin.Door.Row1.DriverSide.IsOpen", "#ffffff");
        appendOutput("  Vehicle.Body.Lights.Beam.Low.IsOn", "#ffffff");
        appendOutput("  Vehicle.CurrentLocation.Latitude", "#ffffff");
        appendOutput("  Vehicle.CurrentLocation.Longitude", "#ffffff");
        
    } else if (cmd == "cd") {
        if (parts.size() > 1) {
            QString path = parts[1];
            if (path == "~") {
                path = QDir::homePath();
            } else if (path.startsWith("~/")) {
                path = QDir::homePath() + "/" + path.mid(2);
            } else if (!path.startsWith("/")) {
                path = m_currentDirectory + "/" + path;
            }
            changeDirectory(path);
        } else {
            changeDirectory(QDir::homePath());
        }
        return; // Don't call updatePrompt again
        
    } else if (cmd == "pwd") {
        showCurrentDirectory();
        return;
        
    } else if (cmd == "clear") {
        clear();
        return;
        
    } else {
        appendOutput("Unknown builtin command: " + cmd, "#ff0000");
        appendOutput("Type 'dk-help' for available commands", "#ffff00");
    }
    
    updatePrompt();
}

bool TerminalConsole::isBuiltinCommand(const QString &command) const {
    return m_builtinCommands.contains(command.toLower());
}

QString TerminalConsole::formatPrompt() const {
    QString user = qgetenv("USER");
    if (user.isEmpty()) user = "dk";
    
    QString dirName = m_currentDirectory;
    if (dirName == QDir::homePath()) {
        dirName = "~";
    } else {
        dirName = QDir(dirName).dirName();
    }
    
    return QString("%1@%2:$ ").arg(user).arg(dirName);
}

void TerminalConsole::setRunningState(bool running) {
    if (m_isRunning != running) {
        m_isRunning = running;
        emit runningStateChanged();
    }
}

void TerminalConsole::executeSystemCommand(const QString &command) {
    if (m_isRunning) {
        m_commandQueue.enqueue(command);
        return;
    }
    
    m_currentCommand = command;
    setRunningState(true);
    
    // Set working directory
    m_process->setWorkingDirectory(m_currentDirectory);
    
    // Start process with bash
    m_process->start("bash", QStringList() << "-c" << command);
    
    if (m_process->waitForStarted(3000)) {
        m_timeoutTimer->start();
    } else {
        appendOutput("Failed to start command: " + command, "#ff0000");
        setRunningState(false);
        updatePrompt();
    }
}

void TerminalConsole::setupBuiltinCommands() {
    m_builtinCommands << "dk-help" << "dk-status" << "dk-kuksa-status"
                     << "kuksa-start" << "kuksa-stop" << "kuksa-restart" << "kuksa-logs"
                     << "vss-get" << "vss-set" << "vss-list"
                     << "cd" << "pwd" << "clear";
}