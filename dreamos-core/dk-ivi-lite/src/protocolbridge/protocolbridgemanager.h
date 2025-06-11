#ifndef PROTOCOLBRIDGEMANAGER_H
#define PROTOCOLBRIDGEMANAGER_H

#include <QObject>
#include <QTimer>
#include <QJsonObject>
#include <QAbstractListModel>
#include <memory>
#include "kuksaconnectionmanager.h"
#include "terminalconsole.h"

// Enums for interface modes
enum class InterfaceMode {
    Simulated,
    RealHardware,
    ReplayFile
};

enum class ProtocolType {
    CAN,
    LIN,
    FlexRay,
    OBD,
    SOME_IP,
    REST,
    MQTT
};

Q_DECLARE_METATYPE(InterfaceMode)
Q_DECLARE_METATYPE(ProtocolType)

// VSS Signal Model for displaying active signals
class VSSSignalModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles {
        SignalPathRole = Qt::UserRole + 1,
        ValueRole,
        UnitRole,
        TimestampRole,
        SourceProtocolRole
    };

    struct VSSSignal {
        QString signalPath;
        QVariant value;
        QString unit;
        qint64 timestamp;
        QString sourceProtocol;
    };

    explicit VSSSignalModel(QObject *parent = nullptr);
    
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    
    void updateSignal(const QString &path, const QVariant &value, const QString &unit, const QString &sourceProtocol = "");
    void clearSignals();

private:
    QList<VSSSignal> m_signals;
};

// Protocol Interface Base Class
class ProtocolInterface : public QObject {
    Q_OBJECT
public:
    explicit ProtocolInterface(ProtocolType type, QObject *parent = nullptr);
    virtual ~ProtocolInterface() = default;
    
    virtual bool initialize() = 0;
    virtual void start() = 0;
    virtual void stop() = 0;
    virtual void sendData(const QByteArray &data) = 0;
    virtual bool isConnected() const = 0;
    
    ProtocolType type() const { return m_type; }
    InterfaceMode mode() const { return m_mode; }
    void setMode(InterfaceMode mode) { m_mode = mode; }

signals:
    void dataReceived(const QByteArray &data);
    void connectionStateChanged(bool connected);
    void errorOccurred(const QString &error);

protected:
    ProtocolType m_type;
    InterfaceMode m_mode = InterfaceMode::Simulated;
};

// CAN Interface Implementation
class CANInterface : public ProtocolInterface {
    Q_OBJECT
public:
    explicit CANInterface(QObject *parent = nullptr);
    
    bool initialize() override;
    void start() override;
    void stop() override;
    void sendData(const QByteArray &data) override;
    bool isConnected() const override;
    
    // CAN-specific methods
    void setCanDevice(const QString &deviceName);
    void setBitRate(int bitRate);
    void setExtendedFrameFormat(bool extended);
    
    // Simulation control methods
    void setEngineRpm(double rpm) { m_simState.engineRpm = rpm; }
    void setVehicleSpeed(double speed) { m_simState.vehicleSpeed = speed; }
    void setFuelLevel(double level) { m_simState.fuelLevel = level; }
    void setGear(int gear) { m_simState.gear = gear; }
    void setHeadlights(bool on) { m_simState.headlights = on; }

private slots:
    void simulateCanData();

private:
    QTimer *m_simulationTimer;
    QString m_deviceName;
    int m_bitRate = 500000;
    bool m_extendedFormat = false;
    bool m_connected = false;
    
    // Simulation state
    struct CanSimState {
        double engineRpm = 800.0;
        double vehicleSpeed = 0.0;
        double fuelLevel = 75.0;
        double engineTemp = 90.0;
        bool headlights = false;
        int gear = 0;
        double odometer = 45230.0;
    } m_simState;
    
    void updateSimulationState();
};

// Professional Protocol Bridge Manager
class ProtocolBridgeManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString timelinePosition READ timelinePosition NOTIFY timelineChanged)
    Q_PROPERTY(QString timelineDuration READ timelineDuration NOTIFY timelineChanged)
    Q_PROPERTY(double playbackSpeed READ playbackSpeed WRITE setPlaybackSpeed NOTIFY playbackSpeedChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playStateChanged)
    Q_PROPERTY(bool isRecording READ isRecording NOTIFY recordStateChanged)
    Q_PROPERTY(VSSSignalModel* vssSignalModel READ vssSignalModel CONSTANT)
    Q_PROPERTY(KuksaConnectionManager* kuksaManager READ kuksaManager CONSTANT)
    Q_PROPERTY(TerminalConsole* terminal READ terminal CONSTANT)
    Q_PROPERTY(QString someipMessages READ someipMessages NOTIFY someipMessagesChanged)
    Q_PROPERTY(QString restApiMessages READ restApiMessages NOTIFY restApiMessagesChanged)
    Q_PROPERTY(QString mobileAppJson READ mobileAppJson NOTIFY mobileAppJsonChanged)

public:
    explicit ProtocolBridgeManager(QObject *parent = nullptr);
    
    // Timeline control
    QString timelinePosition() const;
    QString timelineDuration() const;
    double playbackSpeed() const { return m_playbackSpeed; }
    bool isPlaying() const { return m_isPlaying; }
    bool isRecording() const { return m_isRecording; }
    
    // Models and managers
    VSSSignalModel* vssSignalModel() { return &m_vssModel; }
    KuksaConnectionManager* kuksaManager() { return m_kuksaManager.get(); }
    TerminalConsole* terminal() { return m_terminal.get(); }
    
    // Output messages
    QString someipMessages() const { return m_someipMessages; }
    QString restApiMessages() const { return m_restApiMessages; }
    QString mobileAppJson() const { return m_mobileAppJson; }

public slots:
    // Playback controls
    void play();
    void pause();
    void stop();
    void record();
    void setPlaybackSpeed(double speed);
    void seekToPosition(double position); // 0.0 to 1.0
    
    // Interface mode switching
    void setCanMode(InterfaceMode mode);
    void setLinMode(InterfaceMode mode);
    void setFlexRayMode(InterfaceMode mode);
    void setObdMode(InterfaceMode mode);
    
    // Real hardware configuration
    void configureCan(const QString &device, int bitRate);
    void configureLin(const QString &device);
    void configureObd(const QString &device);
    
    // Simulation scenarios
    void loadScenario(const QString &scenarioFile);
    void startCityDriveScenario();
    void startHighwayScenario();
    void startParkingScenario();
    void startDiagnosticScenario();
    
    // Manual simulation controls
    void updateCanRpm(int rpm);
    void updateCanSpeed(int speed);
    void updateCanGear(int gear);
    void updateCanFuelLevel(double level);
    void enableCanSimulation(bool enabled);
    void enableLinSimulation(bool enabled);

signals:
    void timelineChanged();
    void playbackSpeedChanged();
    void playStateChanged();
    void recordStateChanged();
    void vssSignalUpdated(const QString &path, const QVariant &value);
    void protocolDataReceived(ProtocolType type, const QByteArray &data);
    void interfaceModeChanged(ProtocolType type, InterfaceMode mode);
    void someipMessagesChanged();
    void restApiMessagesChanged();
    void mobileAppJsonChanged();

private slots:
    void processTimelineUpdate();
    void handleProtocolData(const QByteArray &data);
    void processVSSSignals();

private:
    // Protocol interfaces
    std::unique_ptr<CANInterface> m_canInterface;
    std::unique_ptr<ProtocolInterface> m_linInterface;
    std::unique_ptr<ProtocolInterface> m_flexrayInterface;
    std::unique_ptr<ProtocolInterface> m_obdInterface;
    
    // Managers
    std::unique_ptr<KuksaConnectionManager> m_kuksaManager;
    std::unique_ptr<TerminalConsole> m_terminal;
    
    // Models
    VSSSignalModel m_vssModel;
    
    // Timeline management
    QTimer *m_timelineTimer;
    qint64 m_timelineStart;
    qint64 m_currentPosition;
    qint64 m_totalDuration;
    double m_playbackSpeed = 1.0;
    bool m_isPlaying = false;
    bool m_isRecording = false;
    
    // VSS processing
    QTimer *m_vssProcessor;
    
    // Output protocol messages
    QString m_someipMessages;
    QString m_restApiMessages;
    QString m_mobileAppJson;
    
    // Scenario data
    QJsonObject m_currentScenario;
    QList<QJsonObject> m_recordedData;
    
    // Helper methods
    void initializeProtocolInterfaces();
    void setupTimers();
    void publishToOutputProtocols();
    void generateSomeipOutput();
    void generateRestApiOutput();
    void generateMobileAppOutput();
};

#endif // PROTOCOLBRIDGEMANAGER_H