#ifndef USS_H
#define USS_H

#include <QObject>
#include <QString>
#include <QVariant>
#include <QMap>
#include <array>
#include <string>

class UssAsync : public QObject
{
    Q_OBJECT
public:
    UssAsync();
    ~UssAsync();

    Q_INVOKABLE void init();
    
    // Test control methods for simulation
    Q_INVOKABLE void qml_setTestDistance(const QString& sensorId, float distance);
    Q_INVOKABLE void qml_setAllTestDistances(float distance);
    Q_INVOKABLE void qml_startParkingScenario();
    Q_INVOKABLE void qml_stopScenario();
    
    void vssSubscribeCallback(const std::string &updatePath, const std::string &updateValue);

Q_SIGNALS:
    // Front sensors (S1-S6)
    void updateSensor_front_left(float distance);
    void updateSensor_front_cornerLeft(float distance);
    void updateSensor_front_center(float distance);
    void updateSensor_front_centerRight(float distance);
    void updateSensor_front_cornerRight(float distance);
    void updateSensor_front_right(float distance);
    
    // Rear sensors (S7-S12)
    void updateSensor_rear_right(float distance);
    void updateSensor_rear_cornerRight(float distance);
    void updateSensor_rear_centerRight(float distance);
    void updateSensor_rear_center(float distance);
    void updateSensor_rear_cornerLeft(float distance);
    void updateSensor_rear_left(float distance);
    
    // Aggregated status
    void updateClosestObstacle(const QString& location, float distance);
    void updateParkingMode(bool active);

private:
    void updateClosestDistance();
    void simulateParkingScenario();
    
    struct SensorData {
        std::string vssPath;
        float currentDistance;
        QString displayName;
    };
    
    std::array<SensorData, 12> m_sensors;
    bool m_parkingModeActive;
    bool m_scenarioRunning;
    
    // Helper method to get sensor index from VSS path
    int getSensorIndexFromPath(const std::string& path);
};

#endif // USS_H