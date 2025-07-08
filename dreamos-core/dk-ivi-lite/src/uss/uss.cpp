#include "uss.hpp"
#include <QDebug>
#include <QTimer>
#include <QThread>
#include <algorithm>
#include <cmath>
#include "library/vapiclient/vapiclient.hpp"

UssAsync::UssAsync() : m_parkingModeActive(false), m_scenarioRunning(false)
{
    qDebug() << __func__ << " - " << __LINE__ << " USS System initializing ===============================";

    // Initialize sensor array with VSS paths and display names
    m_sensors[0] = {VehicleAPI::V_ADAS_ObstacleDetectionFront_Left_Distance, 10.0f, "S1 Front Left"};
    m_sensors[1] = {VehicleAPI::V_ADAS_ObstacleDetectionFront_CornerLeft_Distance, 10.0f, "S2 Front Corner Left"};
    m_sensors[2] = {VehicleAPI::V_ADAS_ObstacleDetectionFront_Center_Distance, 10.0f, "S3 Front Center Left"};
    m_sensors[3] = {VehicleAPI::V_ADAS_ObstacleDetectionFront_CenterRight_Distance, 10.0f, "S4 Front Center Right"};
    m_sensors[4] = {VehicleAPI::V_ADAS_ObstacleDetectionFront_CornerRight_Distance, 10.0f, "S5 Front Corner Right"};
    m_sensors[5] = {VehicleAPI::V_ADAS_ObstacleDetectionFront_Right_Distance, 10.0f, "S6 Front Right"};
    
    m_sensors[6] = {VehicleAPI::V_ADAS_ObstacleDetectionRear_Right_Distance, 10.0f, "S7 Rear Right"};
    m_sensors[7] = {VehicleAPI::V_ADAS_ObstacleDetectionRear_CornerRight_Distance, 10.0f, "S8 Rear Corner Right"};
    m_sensors[8] = {VehicleAPI::V_ADAS_ObstacleDetectionRear_CenterRight_Distance, 10.0f, "S9 Rear Center Right"};
    m_sensors[9] = {VehicleAPI::V_ADAS_ObstacleDetectionRear_Center_Distance, 10.0f, "S10 Rear Center Left"};
    m_sensors[10] = {VehicleAPI::V_ADAS_ObstacleDetectionRear_CornerLeft_Distance, 10.0f, "S11 Rear Corner Left"};
    m_sensors[11] = {VehicleAPI::V_ADAS_ObstacleDetectionRear_Left_Distance, 10.0f, "S12 Rear Left"};

    // Subscribe to all USS sensor signals
    std::vector<std::string> signalPaths;
    for (const auto& sensor : m_sensors) {
        signalPaths.push_back(sensor.vssPath);
    }
    
    VAPI_CLIENT.subscribeTarget(DK_VAPI_DATABROKER, signalPaths,
        [this](const std::string &updatePath, const std::string &updateValue) {
            this->vssSubscribeCallback(updatePath, updateValue);
        }
    );
}

void UssAsync::init()
{
    QThread::msleep(300);
    
    // Initialize sensor values from VSS
    std::string val = "";
    
    for (int i = 0; i < 12; ++i) {
        VAPI_CLIENT.getTargetValue(DK_VAPI_DATABROKER, m_sensors[i].vssPath, val);
        try {
            float distance = std::stof(val);
            m_sensors[i].currentDistance = distance;
            
            // Emit appropriate signal based on sensor index
            switch(i) {
                case 0: emit updateSensor_front_left(distance); break;
                case 1: emit updateSensor_front_cornerLeft(distance); break;
                case 2: emit updateSensor_front_center(distance); break;
                case 3: emit updateSensor_front_centerRight(distance); break;
                case 4: emit updateSensor_front_cornerRight(distance); break;
                case 5: emit updateSensor_front_right(distance); break;
                case 6: emit updateSensor_rear_right(distance); break;
                case 7: emit updateSensor_rear_cornerRight(distance); break;
                case 8: emit updateSensor_rear_centerRight(distance); break;
                case 9: emit updateSensor_rear_center(distance); break;
                case 10: emit updateSensor_rear_cornerLeft(distance); break;
                case 11: emit updateSensor_rear_left(distance); break;
            }
        } catch (const std::exception& e) {
            qDebug() << "Error converting USS sensor value for" << QString::fromStdString(m_sensors[i].vssPath) 
                     << ":" << QString::fromStdString(val);
        }
    }
    
    updateClosestDistance();
}

void UssAsync::vssSubscribeCallback(const std::string &updatePath, const std::string &updateValue)
{
    qDebug() << "USS subscription callback - Path:" << QString::fromStdString(updatePath) 
             << "Value:" << QString::fromStdString(updateValue);
    
    int sensorIndex = getSensorIndexFromPath(updatePath);
    if (sensorIndex < 0) {
        qDebug() << "Unknown sensor path:" << QString::fromStdString(updatePath);
        return;
    }
    
    try {
        float distance = std::stof(updateValue);
        m_sensors[sensorIndex].currentDistance = distance;
        
        // Emit appropriate signal based on sensor index
        switch(sensorIndex) {
            case 0: emit updateSensor_front_left(distance); break;
            case 1: emit updateSensor_front_cornerLeft(distance); break;
            case 2: emit updateSensor_front_center(distance); break;
            case 3: emit updateSensor_front_centerRight(distance); break;
            case 4: emit updateSensor_front_cornerRight(distance); break;
            case 5: emit updateSensor_front_right(distance); break;
            case 6: emit updateSensor_rear_right(distance); break;
            case 7: emit updateSensor_rear_cornerRight(distance); break;
            case 8: emit updateSensor_rear_centerRight(distance); break;
            case 9: emit updateSensor_rear_center(distance); break;
            case 10: emit updateSensor_rear_cornerLeft(distance); break;
            case 11: emit updateSensor_rear_left(distance); break;
        }
        
        updateClosestDistance();
        
        // Check for parking mode activation
        if (!m_parkingModeActive && distance < 2.5f) {
            m_parkingModeActive = true;
            emit updateParkingMode(true);
        } else if (m_parkingModeActive) {
            // Check if all sensors show no close obstacles
            bool allClear = true;
            for (const auto& sensor : m_sensors) {
                if (sensor.currentDistance < 3.0f) {
                    allClear = false;
                    break;
                }
            }
            if (allClear) {
                m_parkingModeActive = false;
                emit updateParkingMode(false);
            }
        }
        
    } catch (const std::exception& e) {
        qDebug() << "Error converting USS value:" << QString::fromStdString(updateValue);
    }
}

void UssAsync::qml_setTestDistance(const QString& sensorId, float distance)
{
    // Parse sensor ID (e.g., "S1", "S2", etc.)
    bool ok;
    int sensorNum = sensorId.mid(1).toInt(&ok);
    if (!ok || sensorNum < 1 || sensorNum > 12) {
        qDebug() << "Invalid sensor ID:" << sensorId;
        return;
    }
    
    int index = sensorNum - 1;
    qDebug() << "Setting test distance for" << sensorId << "to" << distance << "m";
    
    // Clamp distance to valid range
    distance = std::max(0.0f, std::min(10.0f, distance));
    
    // Update VSS
    VAPI_CLIENT.setCurrentValue(DK_VAPI_DATABROKER, m_sensors[index].vssPath, distance);
    VAPI_CLIENT.setTargetValue(DK_VAPI_DATABROKER, m_sensors[index].vssPath, distance);
}

void UssAsync::qml_setAllTestDistances(float distance)
{
    qDebug() << "Setting all sensors to" << distance << "m";
    
    // Clamp distance to valid range
    distance = std::max(0.0f, std::min(10.0f, distance));
    
    for (const auto& sensor : m_sensors) {
        VAPI_CLIENT.setCurrentValue(DK_VAPI_DATABROKER, sensor.vssPath, distance);
        VAPI_CLIENT.setTargetValue(DK_VAPI_DATABROKER, sensor.vssPath, distance);
    }
}

void UssAsync::qml_startParkingScenario()
{
    if (m_scenarioRunning) {
        qDebug() << "Parking scenario already running";
        return;
    }
    
    qDebug() << "Starting parking scenario";
    m_scenarioRunning = true;
    
    // Simulate parallel parking scenario
    QTimer::singleShot(0, [this]() { simulateParkingScenario(); });
}

void UssAsync::qml_stopScenario()
{
    qDebug() << "Stopping scenario";
    m_scenarioRunning = false;
    qml_setAllTestDistances(10.0f); // Reset all to max distance
}

void UssAsync::updateClosestDistance()
{
    float closestFront = 10.0f;
    float closestRear = 10.0f;
    int closestFrontIdx = -1;
    int closestRearIdx = -1;
    
    // Find closest obstacles
    for (int i = 0; i < 6; ++i) {
        if (m_sensors[i].currentDistance < closestFront) {
            closestFront = m_sensors[i].currentDistance;
            closestFrontIdx = i;
        }
    }
    
    for (int i = 6; i < 12; ++i) {
        if (m_sensors[i].currentDistance < closestRear) {
            closestRear = m_sensors[i].currentDistance;
            closestRearIdx = i;
        }
    }
    
    // Emit closest obstacle updates
    if (closestFrontIdx >= 0 && closestFront < 5.0f) {
        emit updateClosestObstacle("Front: " + m_sensors[closestFrontIdx].displayName, closestFront);
    } else if (closestRearIdx >= 0 && closestRear < 5.0f) {
        emit updateClosestObstacle("Rear: " + m_sensors[closestRearIdx].displayName, closestRear);
    } else {
        emit updateClosestObstacle("Clear", 10.0f);
    }
}

void UssAsync::simulateParkingScenario()
{
    if (!m_scenarioRunning) return;
    
    // Simulate approaching a parking space
    static int step = 0;
    
    switch(step % 10) {
        case 0: // Initial approach
            qml_setTestDistance("S8", 2.5f);  // Rear corner right detects car
            qml_setTestDistance("S9", 3.0f);  // Rear center right
            break;
        case 1: // Moving closer
            qml_setTestDistance("S8", 1.8f);
            qml_setTestDistance("S9", 2.2f);
            qml_setTestDistance("S10", 2.8f); // Rear center left starts detecting
            break;
        case 2: // Parallel to car
            qml_setTestDistance("S8", 1.2f);
            qml_setTestDistance("S9", 1.5f);
            qml_setTestDistance("S10", 2.0f);
            qml_setTestDistance("S11", 2.5f); // Rear corner left
            break;
        case 3: // Starting to turn
            qml_setTestDistance("S7", 2.8f);  // Rear right
            qml_setTestDistance("S8", 0.8f);  // Getting close
            qml_setTestDistance("S9", 1.0f);
            qml_setTestDistance("S10", 1.5f);
            break;
        case 4: // Backing into space
            qml_setTestDistance("S7", 2.0f);
            qml_setTestDistance("S8", 0.5f);  // Very close!
            qml_setTestDistance("S9", 0.7f);
            qml_setTestDistance("S10", 1.2f);
            qml_setTestDistance("S11", 1.8f);
            qml_setTestDistance("S12", 2.5f); // Rear left
            break;
        case 5: // Critical distance
            qml_setTestDistance("S8", 0.3f);  // Critical warning
            qml_setTestDistance("S9", 0.4f);
            qml_setTestDistance("S10", 0.8f);
            qml_setTestDistance("S3", 3.5f);  // Front sensors start detecting
            qml_setTestDistance("S4", 3.0f);
            break;
        case 6: // Adjusting position
            qml_setTestDistance("S8", 0.5f);
            qml_setTestDistance("S9", 0.6f);
            qml_setTestDistance("S10", 0.9f);
            qml_setTestDistance("S3", 2.5f);
            qml_setTestDistance("S4", 2.2f);
            break;
        case 7: // Final position
            qml_setTestDistance("S8", 0.8f);
            qml_setTestDistance("S9", 1.0f);
            qml_setTestDistance("S10", 1.2f);
            qml_setTestDistance("S3", 1.5f);
            qml_setTestDistance("S4", 1.3f);
            break;
        case 8: // Parked
            qml_setTestDistance("S8", 1.2f);
            qml_setTestDistance("S9", 1.5f);
            qml_setTestDistance("S3", 1.2f);
            qml_setTestDistance("S4", 1.0f);
            break;
        case 9: // Reset other sensors
            qml_setAllTestDistances(10.0f);
            qml_setTestDistance("S8", 1.5f);
            qml_setTestDistance("S3", 1.5f);
            break;
    }
    
    step++;
    
    // Continue simulation
    if (m_scenarioRunning) {
        QTimer::singleShot(1500, [this]() { simulateParkingScenario(); });
    }
}

int UssAsync::getSensorIndexFromPath(const std::string& path)
{
    for (int i = 0; i < 12; ++i) {
        if (m_sensors[i].vssPath == path) {
            return i;
        }
    }
    return -1;
}

UssAsync::~UssAsync()
{
    qDebug() << __func__ << " - " << __LINE__ << " USS System destroyed ===========================";
    m_scenarioRunning = false;
}