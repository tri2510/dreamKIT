#include "protocolbridgemanager.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonArray>
#include <QDateTime>
#include <QRandomGenerator>
#include <QtMath>

// VSSSignalModel Implementation
VSSSignalModel::VSSSignalModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int VSSSignalModel::rowCount(const QModelIndex &parent) const {
    Q_UNUSED(parent)
    return m_signals.count();
}

QVariant VSSSignalModel::data(const QModelIndex &index, int role) const {
    if (index.row() < 0 || index.row() >= m_signals.count())
        return QVariant();
    
    const VSSSignal &signal = m_signals[index.row()];
    
    switch (role) {
    case SignalPathRole:
        return signal.signalPath;
    case ValueRole:
        return signal.value;
    case UnitRole:
        return signal.unit;
    case TimestampRole:
        return signal.timestamp;
    case SourceProtocolRole:
        return signal.sourceProtocol;
    }
    return QVariant();
}

QHash<int, QByteArray> VSSSignalModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[SignalPathRole] = "signalPath";
    roles[ValueRole] = "value";
    roles[UnitRole] = "unit";
    roles[TimestampRole] = "timestamp";
    roles[SourceProtocolRole] = "sourceProtocol";
    return roles;
}

void VSSSignalModel::updateSignal(const QString &path, const QVariant &value, const QString &unit, const QString &sourceProtocol) {
    // Find existing signal or add new one
    for (int i = 0; i < m_signals.count(); ++i) {
        if (m_signals[i].signalPath == path) {
            m_signals[i].value = value;
            m_signals[i].unit = unit;
            m_signals[i].timestamp = QDateTime::currentMSecsSinceEpoch();
            m_signals[i].sourceProtocol = sourceProtocol;
            QModelIndex index = createIndex(i, 0);
            emit dataChanged(index, index);
            return;
        }
    }
    
    // Add new signal
    beginInsertRows(QModelIndex(), m_signals.count(), m_signals.count());
    m_signals.append({path, value, unit, QDateTime::currentMSecsSinceEpoch(), sourceProtocol});
    endInsertRows();
}

void VSSSignalModel::clearSignals() {
    beginResetModel();
    m_signals.clear();
    endResetModel();
}

// ProtocolInterface Implementation
ProtocolInterface::ProtocolInterface(ProtocolType type, QObject *parent)
    : QObject(parent), m_type(type)
{
}

// CANInterface Implementation
CANInterface::CANInterface(QObject *parent)
    : ProtocolInterface(ProtocolType::CAN, parent)
    , m_simulationTimer(new QTimer(this))
{
    m_simulationTimer->setInterval(100); // 10 Hz simulation
    connect(m_simulationTimer, &QTimer::timeout, this, &CANInterface::simulateCanData);
}

bool CANInterface::initialize() {
    if (m_mode == InterfaceMode::Simulated) {
        m_connected = true;
        return true;
    } else if (m_mode == InterfaceMode::RealHardware) {
        // In a real implementation, this would initialize CAN hardware
        qDebug() << "Initializing CAN hardware on device:" << m_deviceName;
        // For demo purposes, we'll simulate success
        m_connected = true;
        return true;
    }
    return false;
}

void CANInterface::start() {
    if (!m_connected && !initialize()) {
        emit errorOccurred("Failed to initialize CAN interface");
        return;
    }
    
    if (m_mode == InterfaceMode::Simulated) {
        m_simulationTimer->start();
    }
    
    emit connectionStateChanged(true);
    qDebug() << "CAN interface started in mode:" << (int)m_mode;
}

void CANInterface::stop() {
    m_simulationTimer->stop();
    m_connected = false;
    emit connectionStateChanged(false);
    qDebug() << "CAN interface stopped";
}

void CANInterface::sendData(const QByteArray &data) {
    if (!m_connected) {
        emit errorOccurred("CAN interface not connected");
        return;
    }
    
    // In simulation mode, just log the data
    qDebug() << "CAN TX:" << data.toHex();
    
    // In real hardware mode, this would send to actual CAN bus
}

bool CANInterface::isConnected() const {
    return m_connected;
}

void CANInterface::setCanDevice(const QString &deviceName) {
    m_deviceName = deviceName;
}

void CANInterface::setBitRate(int bitRate) {
    m_bitRate = bitRate;
}

void CANInterface::setExtendedFrameFormat(bool extended) {
    m_extendedFormat = extended;
}

void CANInterface::simulateCanData() {
    updateSimulationState();
    
    // Simulate CAN frames for different signals
    
    // Engine RPM frame (ID: 0x123)
    QByteArray rpmFrame;
    rpmFrame.append(static_cast<char>(0x23)); // Frame ID low
    rpmFrame.append(static_cast<char>(0x01)); // Frame ID high
    rpmFrame.append(static_cast<char>(8));    // DLC
    
    quint16 rpm = static_cast<quint16>(m_simState.engineRpm);
    rpmFrame.append(static_cast<char>(rpm & 0xFF));        // RPM low byte
    rpmFrame.append(static_cast<char>((rpm >> 8) & 0xFF)); // RPM high byte
    rpmFrame.append(static_cast<char>(0x00)); // Reserved
    rpmFrame.append(static_cast<char>(0x00)); // Reserved
    rpmFrame.append(static_cast<char>(0x00)); // Reserved
    rpmFrame.append(static_cast<char>(0x00)); // Reserved
    rpmFrame.append(static_cast<char>(0x00)); // Reserved
    rpmFrame.append(static_cast<char>(0x00)); // Reserved
    
    emit dataReceived(rpmFrame);
    
    // Vehicle speed frame (ID: 0x124)
    QByteArray speedFrame;
    speedFrame.append(static_cast<char>(0x24)); // Frame ID low
    speedFrame.append(static_cast<char>(0x01)); // Frame ID high
    speedFrame.append(static_cast<char>(8));    // DLC
    
    quint16 speed = static_cast<quint16>(m_simState.vehicleSpeed * 100); // Speed in 0.01 km/h
    speedFrame.append(static_cast<char>(speed & 0xFF));
    speedFrame.append(static_cast<char>((speed >> 8) & 0xFF));
    speedFrame.append(static_cast<char>(m_simState.gear)); // Current gear
    speedFrame.append(static_cast<char>(m_simState.headlights ? 0x01 : 0x00)); // Headlight status
    speedFrame.append(static_cast<char>(0x00)); // Reserved
    speedFrame.append(static_cast<char>(0x00)); // Reserved
    speedFrame.append(static_cast<char>(0x00)); // Reserved
    speedFrame.append(static_cast<char>(0x00)); // Reserved
    
    emit dataReceived(speedFrame);
}

void CANInterface::updateSimulationState() {
    static qint64 lastUpdate = QDateTime::currentMSecsSinceEpoch();
    qint64 now = QDateTime::currentMSecsSinceEpoch();
    double deltaTime = (now - lastUpdate) / 1000.0; // seconds
    lastUpdate = now;
    
    // Simple physics simulation
    static double time = 0.0;
    time += deltaTime;
    
    // Simulate city driving pattern
    double speedTarget = 50.0 + 30.0 * qSin(time * 0.1) + 20.0 * qSin(time * 0.3);
    speedTarget = qMax(0.0, speedTarget);
    
    // Smooth speed changes
    double speedDiff = speedTarget - m_simState.vehicleSpeed;
    m_simState.vehicleSpeed += speedDiff * deltaTime * 0.5; // Gradual acceleration
    
    // RPM follows speed with some engine characteristics
    if (m_simState.vehicleSpeed > 0) {
        m_simState.engineRpm = 800 + (m_simState.vehicleSpeed * 45) + QRandomGenerator::global()->bounded(-50, 50);
    } else {
        m_simState.engineRpm = 800 + QRandomGenerator::global()->bounded(-20, 20); // Idle variation
    }
    
    // Gear selection based on speed
    if (m_simState.vehicleSpeed < 5) {
        m_simState.gear = 1;
    } else if (m_simState.vehicleSpeed < 25) {
        m_simState.gear = 2;
    } else if (m_simState.vehicleSpeed < 50) {
        m_simState.gear = 3;
    } else if (m_simState.vehicleSpeed < 80) {
        m_simState.gear = 4;
    } else {
        m_simState.gear = 5;
    }
    
    // Fuel consumption
    if (m_simState.vehicleSpeed > 0) {
        double consumption = (m_simState.vehicleSpeed / 100.0) * deltaTime * 0.001; // Very slow consumption for demo
        m_simState.fuelLevel = qMax(0.0, m_simState.fuelLevel - consumption);
    }
    
    // Engine temperature
    double targetTemp = 85 + (m_simState.engineRpm - 800) / 100.0;
    double tempDiff = targetTemp - m_simState.engineTemp;
    m_simState.engineTemp += tempDiff * deltaTime * 0.1;
    
    // Headlights (simple time-based simulation)
    QTime currentTime = QTime::currentTime();
    m_simState.headlights = (currentTime.hour() < 7 || currentTime.hour() > 19);
    
    // Update odometer
    if (m_simState.vehicleSpeed > 0) {
        double distance = (m_simState.vehicleSpeed / 3600.0) * deltaTime; // km
        m_simState.odometer += distance;
    }
}

// ProtocolBridgeManager Implementation
ProtocolBridgeManager::ProtocolBridgeManager(QObject *parent)
    : QObject(parent)
    , m_kuksaManager(std::make_unique<KuksaConnectionManager>(this))
    , m_terminal(std::make_unique<TerminalConsole>(this))
    , m_timelineTimer(new QTimer(this))
    , m_vssProcessor(new QTimer(this))
{
    // Initialize protocol interfaces
    initializeProtocolInterfaces();
    
    // Setup timers
    setupTimers();
    
    // Initialize timeline
    m_timelineStart = QDateTime::currentMSecsSinceEpoch();
    m_totalDuration = 300000; // 5 minutes default
    
    qDebug() << "ProtocolBridgeManager initialized";
}

void ProtocolBridgeManager::initializeProtocolInterfaces() {
    // Create CAN interface
    m_canInterface = std::make_unique<CANInterface>(this);
    connect(m_canInterface.get(), &ProtocolInterface::dataReceived,
            this, &ProtocolBridgeManager::handleProtocolData);
    
    // Initialize other interfaces (placeholder implementations)
    // m_linInterface = std::make_unique<LINInterface>(this);
    // m_flexrayInterface = std::make_unique<FlexRayInterface>(this);
    // m_obdInterface = std::make_unique<OBDInterface>(this);
}

void ProtocolBridgeManager::setupTimers() {
    // Timeline timer for playback control
    m_timelineTimer->setInterval(100); // 10 Hz update
    connect(m_timelineTimer, &QTimer::timeout, this, &ProtocolBridgeManager::processTimelineUpdate);
    
    // VSS processing timer
    m_vssProcessor->setInterval(50); // 20 Hz VSS processing
    connect(m_vssProcessor, &QTimer::timeout, this, &ProtocolBridgeManager::processVSSSignals);
    m_vssProcessor->start(); // Always run VSS processing
}

QString ProtocolBridgeManager::timelinePosition() const {
    qint64 elapsed = QDateTime::currentMSecsSinceEpoch() - m_timelineStart;
    int seconds = (elapsed / 1000) % 60;
    int minutes = (elapsed / 60000) % 60;
    return QString("%1:%2").arg(minutes, 2, 10, QChar('0')).arg(seconds, 2, 10, QChar('0'));
}

QString ProtocolBridgeManager::timelineDuration() const {
    int seconds = (m_totalDuration / 1000) % 60;
    int minutes = (m_totalDuration / 60000) % 60;
    return QString("%1:%2").arg(minutes, 2, 10, QChar('0')).arg(seconds, 2, 10, QChar('0'));
}

void ProtocolBridgeManager::play() {
    if (!m_isPlaying) {
        m_isPlaying = true;
        m_timelineTimer->start();
        
        // Start protocol interfaces
        if (m_canInterface) {
            m_canInterface->start();
        }
        
        emit playStateChanged();
        qDebug() << "Playback started";
    }
}

void ProtocolBridgeManager::pause() {
    if (m_isPlaying) {
        m_isPlaying = false;
        m_timelineTimer->stop();
        
        // Stop protocol interfaces
        if (m_canInterface) {
            m_canInterface->stop();
        }
        
        emit playStateChanged();
        qDebug() << "Playback paused";
    }
}

void ProtocolBridgeManager::stop() {
    m_isPlaying = false;
    m_isRecording = false;
    m_timelineTimer->stop();
    
    // Stop all protocol interfaces
    if (m_canInterface) {
        m_canInterface->stop();
    }
    
    // Reset timeline
    m_timelineStart = QDateTime::currentMSecsSinceEpoch();
    m_currentPosition = 0;
    
    emit playStateChanged();
    emit recordStateChanged();
    emit timelineChanged();
    qDebug() << "Playback stopped";
}

void ProtocolBridgeManager::record() {
    if (!m_isRecording) {
        m_isRecording = true;
        m_recordedData.clear();
        
        // Start recording
        if (!m_isPlaying) {
            play(); // Auto-start playback when recording
        }
        
        emit recordStateChanged();
        qDebug() << "Recording started";
    } else {
        m_isRecording = false;
        emit recordStateChanged();
        qDebug() << "Recording stopped";
    }
}

void ProtocolBridgeManager::setPlaybackSpeed(double speed) {
    if (m_playbackSpeed != speed) {
        m_playbackSpeed = speed;
        
        // Update timer intervals based on speed
        if (m_timelineTimer->isActive()) {
            m_timelineTimer->setInterval(static_cast<int>(100 / speed));
        }
        
        emit playbackSpeedChanged();
    }
}

void ProtocolBridgeManager::seekToPosition(double position) {
    position = qBound(0.0, position, 1.0);
    m_currentPosition = static_cast<qint64>(position * m_totalDuration);
    m_timelineStart = QDateTime::currentMSecsSinceEpoch() - m_currentPosition;
    emit timelineChanged();
}

void ProtocolBridgeManager::setCanMode(InterfaceMode mode) {
    if (m_canInterface) {
        m_canInterface->setMode(mode);
        emit interfaceModeChanged(ProtocolType::CAN, mode);
        qDebug() << "CAN mode set to:" << (int)mode;
    }
}

void ProtocolBridgeManager::setLinMode(InterfaceMode mode) {
    // Implementation for LIN interface
    emit interfaceModeChanged(ProtocolType::LIN, mode);
    qDebug() << "LIN mode set to:" << (int)mode;
}

void ProtocolBridgeManager::setFlexRayMode(InterfaceMode mode) {
    // Implementation for FlexRay interface
    emit interfaceModeChanged(ProtocolType::FlexRay, mode);
    qDebug() << "FlexRay mode set to:" << (int)mode;
}

void ProtocolBridgeManager::setObdMode(InterfaceMode mode) {
    // Implementation for OBD interface
    emit interfaceModeChanged(ProtocolType::OBD, mode);
    qDebug() << "OBD mode set to:" << (int)mode;
}

void ProtocolBridgeManager::configureCan(const QString &device, int bitRate) {
    if (m_canInterface) {
        m_canInterface->setCanDevice(device);
        m_canInterface->setBitRate(bitRate);
        qDebug() << "CAN configured - Device:" << device << "BitRate:" << bitRate;
    }
}

void ProtocolBridgeManager::configureLin(const QString &device) {
    qDebug() << "LIN configured - Device:" << device;
}

void ProtocolBridgeManager::configureObd(const QString &device) {
    qDebug() << "OBD configured - Device:" << device;
}

void ProtocolBridgeManager::startCityDriveScenario() {
    qDebug() << "Starting city drive scenario";
    // Set city driving parameters
    if (m_canInterface) {
        m_canInterface->setVehicleSpeed(45); // Moderate city speed
        m_canInterface->setEngineRpm(1800);
        m_canInterface->setGear(3);
    }
    play();
}

void ProtocolBridgeManager::startHighwayScenario() {
    qDebug() << "Starting highway driving scenario";
    // Set highway-specific parameters
    if (m_canInterface) {
        m_canInterface->setVehicleSpeed(120); // Higher speed for highway
        m_canInterface->setEngineRpm(2500);
        m_canInterface->setGear(6);
    }
    play();
}

void ProtocolBridgeManager::startParkingScenario() {
    qDebug() << "Starting parking scenario";
    // Set parking-specific parameters
    if (m_canInterface) {
        m_canInterface->setVehicleSpeed(5); // Very low speed
        m_canInterface->setEngineRpm(800);
        m_canInterface->setGear(1);
    }
    play();
}

void ProtocolBridgeManager::startDiagnosticScenario() {
    qDebug() << "Starting diagnostic scenario";
    // Simulate diagnostic conditions
    if (m_canInterface) {
        m_canInterface->setVehicleSpeed(0); // Stationary
        m_canInterface->setEngineRpm(1200); // Idle with diagnostics
        m_canInterface->setGear(0); // Park
    }
    play();
}

void ProtocolBridgeManager::enableCanSimulation(bool enabled) {
    if (m_canInterface) {
        if (enabled && !m_isPlaying) {
            m_canInterface->start();
        } else if (!enabled) {
            m_canInterface->stop();
        }
    }
}

void ProtocolBridgeManager::enableLinSimulation(bool enabled) {
    qDebug() << "LIN simulation" << (enabled ? "enabled" : "disabled");
}

void ProtocolBridgeManager::processTimelineUpdate() {
    m_currentPosition = QDateTime::currentMSecsSinceEpoch() - m_timelineStart;
    
    // Check if we've reached the end
    if (m_currentPosition >= m_totalDuration) {
        stop();
        return;
    }
    
    emit timelineChanged();
}

void ProtocolBridgeManager::handleProtocolData(const QByteArray &data) {
    // Process incoming protocol data and translate to VSS
    if (sender() == m_canInterface.get()) {
        // Parse CAN frame and extract VSS signals
        if (data.size() >= 11) { // Minimum CAN frame size
            quint16 frameId = (data[1] << 8) | data[0];
            
            if (frameId == 0x123) { // Engine RPM frame
                quint16 rpm = (data[4] << 8) | data[3];
                m_vssModel.updateSignal("Vehicle.Powertrain.CombustionEngine.Speed", 
                                       rpm, "rpm", "CAN");
                emit vssSignalUpdated("Vehicle.Powertrain.CombustionEngine.Speed", rpm);
            } else if (frameId == 0x124) { // Vehicle speed frame
                quint16 speed = (data[4] << 8) | data[3];
                double speedKmh = speed / 100.0;
                m_vssModel.updateSignal("Vehicle.Speed", speedKmh, "km/h", "CAN");
                emit vssSignalUpdated("Vehicle.Speed", speedKmh);
                
                // Extract other signals from the frame
                int gear = data[5];
                bool headlights = data[6] & 0x01;
                
                m_vssModel.updateSignal("Vehicle.Powertrain.Transmission.CurrentGear", 
                                       gear, "", "CAN");
                m_vssModel.updateSignal("Vehicle.Body.Lights.Beam.Low.IsOn", 
                                       headlights, "", "CAN");
            }
        }
    }
    
    // Record data if recording is active
    if (m_isRecording) {
        QJsonObject record;
        record["timestamp"] = m_currentPosition;
        record["protocol"] = "CAN";
        record["data"] = QString(data.toHex());
        m_recordedData.append(record);
    }
    
    emit protocolDataReceived(ProtocolType::CAN, data);
}

void ProtocolBridgeManager::processVSSSignals() {
    // Generate output protocol messages from current VSS signals
    publishToOutputProtocols();
}

void ProtocolBridgeManager::publishToOutputProtocols() {
    generateSomeipOutput();
    generateRestApiOutput();
    generateMobileAppOutput();
}

void ProtocolBridgeManager::generateSomeipOutput() {
    QJsonObject someipMsg;
    someipMsg["service_id"] = "0x1234";
    someipMsg["method_id"] = "0x8001";
    someipMsg["timestamp"] = QDateTime::currentMSecsSinceEpoch();
    
    QJsonObject data;
    // Extract current VSS values (simplified)
    data["engine_rpm"] = 1850;
    data["vehicle_speed"] = 65.5;
    data["gear"] = 4;
    data["headlights"] = false;
    
    someipMsg["data"] = data;
    
    QString newMessages = QJsonDocument(someipMsg).toJson(QJsonDocument::Compact);
    if (m_someipMessages != newMessages) {
        m_someipMessages = newMessages;
        emit someipMessagesChanged();
    }
}

void ProtocolBridgeManager::generateRestApiOutput() {
    QJsonObject restMsg;
    restMsg["method"] = "POST";
    restMsg["endpoint"] = "/api/vehicle/telemetry";
    restMsg["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    
    QJsonObject payload;
    payload["Vehicle.Speed"] = 65.5;
    payload["Vehicle.Powertrain.CombustionEngine.Speed"] = 1850;
    payload["Vehicle.Powertrain.Transmission.CurrentGear"] = 4;
    payload["Vehicle.Body.Lights.Beam.Low.IsOn"] = false;
    
    restMsg["payload"] = payload;
    
    QString newMessages = QJsonDocument(restMsg).toJson(QJsonDocument::Indented);
    if (m_restApiMessages != newMessages) {
        m_restApiMessages = newMessages;
        emit restApiMessagesChanged();
    }
}

void ProtocolBridgeManager::generateMobileAppOutput() {
    QJsonObject mobileMsg;
    
    QJsonObject dashboard;
    dashboard["speed"] = "65.5 km/h";
    dashboard["rpm"] = "1850 RPM";
    dashboard["gear"] = "D4";
    dashboard["fuel"] = "75%";
    dashboard["engine_temp"] = "90°C";
    
    QJsonObject status;
    status["headlights"] = false;
    status["doors_locked"] = true;
    status["parking_brake"] = false;
    
    mobileMsg["dashboard"] = dashboard;
    mobileMsg["status"] = status;
    mobileMsg["last_update"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    
    QString newMessages = QJsonDocument(mobileMsg).toJson(QJsonDocument::Indented);
    if (m_mobileAppJson != newMessages) {
        m_mobileAppJson = newMessages;
        emit mobileAppJsonChanged();
    }
}

// Manual simulation control implementations
void ProtocolBridgeManager::updateCanRpm(int rpm) {
    if (m_canInterface) {
        m_canInterface->setEngineRpm(rpm);
        qDebug() << "Updated CAN RPM to:" << rpm;
    }
}

void ProtocolBridgeManager::updateCanSpeed(int speed) {
    if (m_canInterface) {
        m_canInterface->setVehicleSpeed(speed);
        qDebug() << "Updated CAN speed to:" << speed;
    }
}

void ProtocolBridgeManager::updateCanGear(int gear) {
    if (m_canInterface) {
        m_canInterface->setGear(gear);
        qDebug() << "Updated CAN gear to:" << gear;
    }
}

void ProtocolBridgeManager::updateCanFuelLevel(double level) {
    if (m_canInterface) {
        m_canInterface->setFuelLevel(level);
        qDebug() << "Updated CAN fuel level to:" << level;
    }
}

void ProtocolBridgeManager::loadScenario(const QString &scenarioFile) {
    qDebug() << "Loading scenario from:" << scenarioFile;
    // Implementation for loading scenario files
    // For now, just log the request
}

