#ifndef TERMINALCONSOLE_H
#define TERMINALCONSOLE_H

#include <QObject>
#include <QProcess>
#include <QTextDocument>
#include <QStringListModel>
#include <QTimer>
#include <QQueue>

class TerminalConsole : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString output READ output NOTIFY outputChanged)
    Q_PROPERTY(QString currentDirectory READ currentDirectory NOTIFY currentDirectoryChanged)
    Q_PROPERTY(QStringListModel* commandHistory READ commandHistory CONSTANT)
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY runningStateChanged)
    Q_PROPERTY(QString prompt READ prompt NOTIFY promptChanged)

public:
    explicit TerminalConsole(QObject *parent = nullptr);
    ~TerminalConsole();
    
    QString output() const { return m_output; }
    QString currentDirectory() const { return m_currentDirectory; }
    QStringListModel* commandHistory() { return &m_historyModel; }
    bool isRunning() const { return m_isRunning; }
    QString prompt() const { return m_prompt; }

public slots:
    // Command execution
    void executeCommand(const QString &command);
    void interruptCommand();
    void sendInput(const QString &input);
    void clear();
    
    // Directory operations
    void changeDirectory(const QString &path);
    void showCurrentDirectory();
    
    // Utility commands
    void listFiles();
    void showHelp();
    void showKuksaStatus();
    void showDockerContainers();
    void showDockerImages();
    
    // KUKSA specific commands
    void connectKuksaCli();
    void listVssSignals();
    void getVssValue(const QString &path);
    void setVssValue(const QString &path, const QString &value);
    
    // Docker management commands
    void dockerPs();
    void dockerImages();
    void dockerLogs(const QString &container);
    void dockerInspect(const QString &container);
    
    // History navigation
    QString getPreviousCommand();
    QString getNextCommand();
    void resetHistoryIndex();

signals:
    void outputChanged();
    void currentDirectoryChanged();
    void runningStateChanged();
    void promptChanged();
    void commandCompleted(const QString &command, int exitCode);

private slots:
    void handleProcessOutput();
    void handleProcessError();
    void handleProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void updatePrompt();
    void processCommandQueue();

private:
    void appendOutput(const QString &text, const QString &color = "#00ff00");
    void addToHistory(const QString &command);
    void executeBuiltinCommand(const QString &command);
    bool isBuiltinCommand(const QString &command) const;
    QString formatPrompt() const;
    void setRunningState(bool running);
    void executeSystemCommand(const QString &command);
    void setupBuiltinCommands();
    
    QProcess *m_process;
    QString m_output;
    QString m_currentDirectory;
    QString m_prompt;
    QStringListModel m_historyModel;
    QStringList m_history;
    bool m_isRunning = false;
    int m_historyIndex = -1;
    
    // Built-in commands
    QStringList m_builtinCommands;
    
    // Command queue for sequential execution
    QQueue<QString> m_commandQueue;
    QTimer *m_queueTimer;
    
    // Output formatting
    struct OutputLine {
        QString text;
        QString color;
        qint64 timestamp;
    };
    QList<OutputLine> m_outputLines;
    int m_maxOutputLines = 1000;
    
    // Current process state
    QString m_currentCommand;
    QTimer *m_timeoutTimer;
};

#endif // TERMINALCONSOLE_H