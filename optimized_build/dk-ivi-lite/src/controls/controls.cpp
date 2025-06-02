#include "controls.hpp"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QThread>
#include <QDebug>
#include <QMutex>

#include "library/vapiclient/vapiclient.hpp"

ControlsAsync::ControlsAsync()
{
    qDebug() << __func__ << " - " << __LINE__ << " ===============================";

    std::vector<std::string> signalPaths;
    signalPaths.push_back(VehicleAPI::V_Bo_Lights_Beam_Low_IsOn);
    signalPaths.push_back(VehicleAPI::V_Bo_Lights_Beam_High_IsOn);
    signalPaths.push_back(VehicleAPI::V_Bo_Lights_Hazard_IsSignaling);
    signalPaths.push_back(VehicleAPI::V_Ca_Seat_R1_DriverSide_Position);
    signalPaths.push_back(VehicleAPI::V_Ca_HVAC_Station_R1_Driver_FanSpeed);
    signalPaths.push_back(VehicleAPI::V_Ca_HVAC_Station_R1_Passenger_FanSpeed);
    
    VAPI_CLIENT.subscribeTarget(DK_VAPI_DATABROKER, signalPaths,
        [this](const std::string &updatePath, const std::string &updateValue) {
            this->vssSubsribeCallback(updatePath, updateValue);
        }
    );
}

void ControlsAsync::init()
{
    QThread::msleep(300);

    bool bool_val = false;
    std::string val = "";

    // Initialize lighting controls
    VAPI_CLIENT.getTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Bo_Lights_Beam_Low_IsOn, val);
    if (val == "true") bool_val = true;
    else bool_val = false;
    updateWidget_lightCtr_lowBeam(bool_val);
    
    VAPI_CLIENT.getTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Bo_Lights_Beam_High_IsOn, val);
    if (val == "true") bool_val = true;
    else bool_val = false;
    updateWidget_lightCtr_highBeam(bool_val);
    
    VAPI_CLIENT.getTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Bo_Lights_Hazard_IsSignaling, val);
    if (val == "true") bool_val = true;
    else bool_val = false;
    updateWidget_lightCtr_Hazard(bool_val);

    // Initialize seat position
    VAPI_CLIENT.getTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Ca_Seat_R1_DriverSide_Position, val);
    try {
        int position = std::stoi(val);
        updateWidget_seat_driverSide_position(position);
    } catch (const std::exception& e) {
        qDebug() << "Error converting seat position value:" << QString::fromStdString(val);
    }

    // Initialize HVAC fan speeds
    VAPI_CLIENT.getTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Ca_HVAC_Station_R1_Driver_FanSpeed, val);
    try {
        int speed = std::stoi(val)/10;
        updateWidget_hvac_driverSide_FanSpeed(speed);
    } catch (const std::exception& e) {
        qDebug() << "Error converting driver fan speed value:" << QString::fromStdString(val);
    }
    
    VAPI_CLIENT.getTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Ca_HVAC_Station_R1_Passenger_FanSpeed, val);
    try {
        int speed = std::stoi(val)/10;
        updateWidget_hvac_passengerSide_FanSpeed(speed);
    } catch (const std::exception& e) {
        qDebug() << "Error converting passenger fan speed value:" << QString::fromStdString(val);
    }
}

void ControlsAsync::vssSubsribeCallback(const std::string &updatePath, const std::string &updateValue) 
{
    qDebug() << "Subscription callback received - Path:" << QString::fromStdString(updatePath) 
             << "Value:" << QString::fromStdString(updateValue);
    
    bool bool_val = false;
    if (updateValue == "true") bool_val = true;
    else if (updateValue == "false") bool_val = false;
    
    if (updatePath == VehicleAPI::V_Bo_Lights_Beam_Low_IsOn) {
        qDebug() << "Updating low beam widget to:" << bool_val;
        updateWidget_lightCtr_lowBeam(bool_val);
    }
    else if (updatePath == VehicleAPI::V_Bo_Lights_Beam_High_IsOn) {
        updateWidget_lightCtr_highBeam(bool_val);
    }
    else if (updatePath == VehicleAPI::V_Bo_Lights_Hazard_IsSignaling) {
        updateWidget_lightCtr_Hazard(bool_val);
    }
    else if (updatePath == VehicleAPI::V_Ca_Seat_R1_DriverSide_Position) {
        try {
            int position = std::stoi(updateValue);
            updateWidget_seat_driverSide_position(position);
        } catch (const std::exception& e) {
            qDebug() << "Error converting seat position value:" << QString::fromStdString(updateValue);
        }
    }
    else if (updatePath == VehicleAPI::V_Ca_HVAC_Station_R1_Driver_FanSpeed) {
        try {
            int speed = std::stoi(updateValue)/10;
            updateWidget_hvac_driverSide_FanSpeed(speed);
        } catch (const std::exception& e) {
            qDebug() << "Error converting driver fan speed value:" << QString::fromStdString(updateValue);
        }
    }
    else if (updatePath == VehicleAPI::V_Ca_HVAC_Station_R1_Passenger_FanSpeed) {
        try {
            int speed = std::stoi(updateValue)/10;
            updateWidget_hvac_passengerSide_FanSpeed(speed);
        } catch (const std::exception& e) {
            qDebug() << "Error converting passenger fan speed value:" << QString::fromStdString(updateValue);
        }
    }
}

void ControlsAsync::qml_setApi_lightCtr_LowBeam(bool sts)
{
    qDebug() << "Setting low beam to:" << sts;
    VAPI_CLIENT.setCurrentValue(DK_VAPI_DATABROKER, VehicleAPI::V_Bo_Lights_Beam_Low_IsOn, sts);
    VAPI_CLIENT.setTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Bo_Lights_Beam_Low_IsOn, sts);
    
    std::string currentValue;
    VAPI_CLIENT.getTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Bo_Lights_Beam_Low_IsOn, currentValue);
    qDebug() << "Value verified after setting:" << QString::fromStdString(currentValue);
}

void ControlsAsync::qml_setApi_lightCtr_HighBeam(bool sts)
{
    qDebug() << "Setting high beam to:" << sts;
    VAPI_CLIENT.setCurrentValue(DK_VAPI_DATABROKER, VehicleAPI::V_Bo_Lights_Beam_High_IsOn, sts);
    VAPI_CLIENT.setTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Bo_Lights_Beam_High_IsOn, sts);
    
    std::string currentValue;
    VAPI_CLIENT.getTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Bo_Lights_Beam_High_IsOn, currentValue);
    qDebug() << "Value verified after setting:" << QString::fromStdString(currentValue);
}

void ControlsAsync::qml_setApi_lightCtr_Hazard(bool sts)
{
    qDebug() << "Setting hazard to:" << sts;
    VAPI_CLIENT.setCurrentValue(DK_VAPI_DATABROKER, VehicleAPI::V_Bo_Lights_Hazard_IsSignaling, sts);
    VAPI_CLIENT.setTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Bo_Lights_Hazard_IsSignaling, sts);
    
    std::string currentValue;
    VAPI_CLIENT.getTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Bo_Lights_Hazard_IsSignaling, currentValue);
    qDebug() << "Value verified after setting:" << QString::fromStdString(currentValue);
}

void ControlsAsync::qml_setApi_seat_driverSide_position(int position)
{
    // Validate position value (1=front, 2=middle, 3=back)
    if (position < 1 || position > 3) {
        qDebug() << "Invalid seat position:" << position << "- must be 1, 2, or 3";
        return;
    }

    QString positionDesc;
    switch (position) {
        case 1: positionDesc = "front"; break;
        case 2: positionDesc = "middle"; break;
        case 3: positionDesc = "back"; break;
    }

    qDebug() << "Setting driver seat position to:" << position << "(" << positionDesc << ")";
    
    // Convert to uint8_t to match the VSS datatype
    uint8_t posValue = static_cast<uint8_t>(position);
    
    // Use the specific uint8_t overload
    VAPI_CLIENT.setCurrentValue(DK_VAPI_DATABROKER, 
                               VehicleAPI::V_Ca_Seat_R1_DriverSide_Position, 
                               posValue);

    // Subscribe to verify changes
    VAPI_CLIENT.subscribe(DK_VAPI_DATABROKER,
                         {VehicleAPI::V_Ca_Seat_R1_DriverSide_Position},
                         [](const std::string& path, const std::string& value) {
                             qDebug() << "Position subscription update for path:" 
                                     << QString::fromStdString(path)
                                     << "value:" << QString::fromStdString(value);
                         });
}

void ControlsAsync::qml_setApi_hvac_driverSide_FanSpeed(uint8_t speed)
{
    uint8_t scaledSpeed = speed * 10;
    qDebug() << "Setting driver fan speed to:" << speed << "(scaled:" << scaledSpeed << ")";
    VAPI_CLIENT.setCurrentValue(DK_VAPI_DATABROKER, VehicleAPI::V_Ca_HVAC_Station_R1_Driver_FanSpeed, scaledSpeed);
    VAPI_CLIENT.setTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Ca_HVAC_Station_R1_Driver_FanSpeed, scaledSpeed);
    
    std::string currentValue;
    VAPI_CLIENT.getTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Ca_HVAC_Station_R1_Driver_FanSpeed, currentValue);
    qDebug() << "Value verified after setting:" << QString::fromStdString(currentValue);
}

void ControlsAsync::qml_setApi_hvac_passengerSide_FanSpeed(uint8_t speed)
{
    uint8_t scaledSpeed = speed * 10;
    qDebug() << "Setting passenger fan speed to:" << speed << "(scaled:" << scaledSpeed << ")";
    VAPI_CLIENT.setCurrentValue(DK_VAPI_DATABROKER, VehicleAPI::V_Ca_HVAC_Station_R1_Passenger_FanSpeed, scaledSpeed);
    VAPI_CLIENT.setTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Ca_HVAC_Station_R1_Passenger_FanSpeed, scaledSpeed);
    
    std::string currentValue;
    VAPI_CLIENT.getTargetValue(DK_VAPI_DATABROKER, VehicleAPI::V_Ca_HVAC_Station_R1_Passenger_FanSpeed, currentValue);
    qDebug() << "Value verified after setting:" << QString::fromStdString(currentValue);
}

ControlsAsync::~ControlsAsync()
{
    qDebug() << __func__ << " - " << __LINE__ << " ControlsAsync instance is destroyed  ===========================";
}