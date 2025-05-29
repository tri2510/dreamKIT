import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "."  // Import local ToggleButton.qml and ModeControl.qml
import ControlsAsync 1.0

Rectangle {
    id: rectangle
    anchors.fill: parent
    color: "#0F0F0F"  // Deep dark background
    
    property int buttonSpacing: 16

    ControlsAsync {
        id: controlPageAsync

        onUpdateWidget_lightCtr_lowBeam: (sts) => {
            lowbeamBtn.checked = sts
        }
        onUpdateWidget_lightCtr_highBeam: (sts) => {
            highbeamBtn.checked = sts
        }
        onUpdateWidget_lightCtr_Hazard: (sts) => {
            hazardBtn.checked = sts
        }
        onUpdateWidget_lightCtr_ambient_mode: (mode) => {
            ambientControl.mode = mode
        }
        onUpdateWidget_lightCtr_ambient_intensity: (intensity) => {
            intensitySlider.value = intensity
        }
        onUpdateWidget_gear_mode: (mode) => {
            gearButtons.selectGear(mode) 
        }
        onUpdateWidget_door_driverSide_isOpen: (sts) => {
            doorLeftBtn.checked = sts
        }
        onUpdateWidget_door_passengerSide_isOpen: (sts) => {
            doorRightBtn.checked = sts
        }
        onUpdateWidget_trunk_rear_isOpen: (sts) => {
            trunkBtn.checked = sts
        }
        onUpdateWidget_hvac_driverSide_FanSpeed: (speed) => {
            fanSpeedLeft.mode = speed
        }
        onUpdateWidget_hvac_passengerSide_FanSpeed: (speed) => {
            fanSpeedRight.mode = speed
        }
    }

    Component.onCompleted: {
        controlPageAsync.init()
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 24
        clip: true

        Item {
            width: rectangle.width - 48
            height: Math.max(rectangle.height - 48, 800)

            // Header
            Text {
                id: headerText
                text: "Vehicle Control Center"
                font.pixelSize: 28
                font.family: "Segoe UI"
                font.weight: Font.Bold
                color: "#00D4AA"
                anchors.horizontalCenter: parent.horizontalCenter
                y: 20
            }

            // Main car illustration and controls container
            Rectangle {
                id: carContainer
                width: parent.width
                height: 600
                y: 80
                color: "transparent"

                // Car SVG illustration (simplified top-down view)
                Item {
                    id: carIllustration
                    width: 300
                    height: 500
                    anchors.centerIn: parent

                    // Car body
                    Rectangle {
                        id: carBody
                        width: 200
                        height: 400
                        radius: 60
                        color: "#1A1A1A"
                        border.color: "#00D4AA"
                        border.width: 3
                        anchors.centerIn: parent

                        // Windshield
                        Rectangle {
                            width: 140
                            height: 60
                            radius: 30
                            color: "#2A2A2A"
                            border.color: "#404040"
                            border.width: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 30
                        }

                        // Rear window
                        Rectangle {
                            width: 120
                            height: 40
                            radius: 20
                            color: "#2A2A2A"
                            border.color: "#404040"
                            border.width: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 320
                        }

                        // Driver seat
                        Rectangle {
                            width: 40
                            height: 60
                            radius: 15
                            color: "#333333"
                            x: 30
                            y: 150
                        }

                        // Passenger seat
                        Rectangle {
                            width: 40
                            height: 60
                            radius: 15
                            color: "#333333"
                            x: 130
                            y: 150
                        }

                        // Headlights indicators
                        Rectangle {
                            id: leftHeadlight
                            width: 20
                            height: 15
                            radius: 8
                            color: lowbeamBtn.checked || highbeamBtn.checked ? "#FFD700" : "#404040"
                            x: 20
                            y: 10
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        Rectangle {
                            id: rightHeadlight
                            width: 20
                            height: 15
                            radius: 8
                            color: lowbeamBtn.checked || highbeamBtn.checked ? "#FFD700" : "#404040"
                            x: 160
                            y: 10
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        // Hazard indicators
                        Rectangle {
                            width: 15
                            height: 10
                            radius: 5
                            color: hazardBtn.checked ? "#FF4444" : "#404040"
                            x: 10
                            y: 100
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                            
                            SequentialAnimation on opacity {
                                running: hazardBtn.checked
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 500 }
                                NumberAnimation { to: 1.0; duration: 500 }
                            }
                        }

                        Rectangle {
                            width: 15
                            height: 10
                            radius: 5
                            color: hazardBtn.checked ? "#FF4444" : "#404040"
                            x: 175
                            y: 100
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                            
                            SequentialAnimation on opacity {
                                running: hazardBtn.checked
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 500 }
                                NumberAnimation { to: 1.0; duration: 500 }
                            }
                        }

                        // Ambient lighting strip
                        Rectangle {
                            width: parent.width - 20
                            height: 4
                            radius: 2
                            color: ambientControl.mode > 0 ? Qt.hsva(ambientControl.mode / 7.0, 0.8, intensitySlider.value / 255.0, 1.0) : "#404040"
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height - 20
                            
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }

                        // Door status indicators
                        Rectangle {
                            id: leftDoorIndicator
                            width: 8
                            height: 40
                            radius: 4
                            color: doorLeftBtn.checked ? "#FF4444" : "#404040"
                            x: -12
                            y: 180
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        Rectangle {
                            id: rightDoorIndicator
                            width: 8
                            height: 40
                            radius: 4
                            color: doorRightBtn.checked ? "#FF4444" : "#404040"
                            x: 204
                            y: 180
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        // Trunk indicator
                        Rectangle {
                            id: trunkIndicator
                            width: 60
                            height: 8
                            radius: 4
                            color: trunkBtn.checked ? "#FF4444" : "#404040"
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 408
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    // Gear indicator in center
                    Rectangle {
                        width: 60
                        height: 60
                        radius: 30
                        color: "#1A1A1A"
                        border.color: "#00D4AA"
                        border.width: 2
                        anchors.centerIn: parent

                        Text {
                            anchors.centerIn: parent
                            text: gearP.checked ? "P" : gearR.checked ? "R" : gearN.checked ? "N" : gearD.checked ? "D" : "P"
                            font.pixelSize: 24
                            font.bold: true
                            color: "#00D4AA"
                            font.family: "Segoe UI"
                        }
                    }
                }

                // Left control panel
                Rectangle {
                    id: leftPanel
                    width: 280
                    height: carIllustration.height
                    x: 0
                    y: 0
                    color: "#1A1A1A"
                    radius: 16
                    border.color: "#2A2A2A"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 24

                        // Lighting Controls
                        Column {
                            width: parent.width
                            spacing: 12

                            Text {
                                text: "Lighting"
                                font.pixelSize: 18
                                font.family: "Segoe UI"
                                font.weight: Font.Medium
                                color: "#00D4AA"
                            }

                            Column {
                                width: parent.width
                                spacing: 8

                                ToggleButton { 
                                    id: lowbeamBtn
                                    text: "Low Beam"
                                    width: parent.width
                                    onToggledChanged: {
                                        controlPageAsync.qml_setApi_lightCtr_LowBeam(checked)
                                    }
                                }
                                ToggleButton { 
                                    id: highbeamBtn
                                    text: "High Beam"
                                    width: parent.width
                                    onToggledChanged: {
                                        controlPageAsync.qml_setApi_lightCtr_HighBeam(checked)
                                    }
                                }
                                ToggleButton { 
                                    id: hazardBtn
                                    text: "Hazard Lights"
                                    width: parent.width
                                    onToggledChanged: {
                                        controlPageAsync.qml_setApi_lightCtr_Hazard(checked)
                                    }
                                }
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: "#2A2A2A" }

                        // Ambient Lighting
                        Column {
                            width: parent.width
                            spacing: 12

                            Text {
                                text: "Ambient Lighting"
                                font.pixelSize: 18
                                font.family: "Segoe UI"
                                font.weight: Font.Medium
                                color: "#00D4AA"
                            }

                            Column {
                                width: parent.width
                                spacing: 12

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Text {
                                        text: "Mode:"
                                        font.pixelSize: 14
                                        color: "#B0B0B0"
                                        font.family: "Segoe UI"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    ModeControl {
                                        id: ambientControl
                                        maxMode: 7
                                        onModeChangedOnPressedChanged: {
                                            controlPageAsync.qml_setApi_ambient_mode(mode)
                                        }
                                    }
                                }

                                Column {
                                    width: parent.width
                                    spacing: 4

                                    Text {
                                        text: "Brightness: " + Math.round((intensitySlider.value / 255) * 100) + "%"
                                        font.pixelSize: 14
                                        color: "#B0B0B0"
                                        font.family: "Segoe UI"
                                    }

                                    Slider {
                                        id: intensitySlider
                                        width: parent.width
                                        from: 0
                                        stepSize: 1
                                        to: 255
                                        value: 0

                                        onValueChanged: {
                                            if (pressed) {
                                                controlPageAsync.qml_setApi_ambient_intensity(value)
                                            }
                                        }

                                        background: Rectangle {
                                            x: intensitySlider.leftPadding
                                            y: intensitySlider.topPadding + intensitySlider.availableHeight / 2 - height / 2
                                            implicitWidth: 200
                                            implicitHeight: 6
                                            width: intensitySlider.availableWidth
                                            height: implicitHeight
                                            radius: 3
                                            color: "#2A2A2A"

                                            Rectangle {
                                                width: intensitySlider.visualPosition * parent.width
                                                height: parent.height
                                                color: "#00D4AA"
                                                radius: 3
                                            }
                                        }

                                        handle: Rectangle {
                                            x: intensitySlider.leftPadding + intensitySlider.visualPosition * (intensitySlider.availableWidth - width)
                                            y: intensitySlider.topPadding + intensitySlider.availableHeight / 2 - height / 2
                                            implicitWidth: 20
                                            implicitHeight: 20
                                            radius: 10
                                            color: intensitySlider.pressed ? "#FFFFFF" : "#F0F0F0"
                                            border.color: "#00D4AA"
                                            border.width: 2
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: "#2A2A2A" }

                        // HVAC Controls
                        Column {
                            width: parent.width
                            spacing: 12

                            Text {
                                text: "Climate Control"
                                font.pixelSize: 18
                                font.family: "Segoe UI"
                                font.weight: Font.Medium
                                color: "#00D4AA"
                            }

                            Column {
                                width: parent.width
                                spacing: 8

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Text {
                                        text: "Driver:"
                                        font.pixelSize: 14
                                        color: "#B0B0B0"
                                        font.family: "Segoe UI"
                                        width: 60
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    ModeControl {
                                        id: fanSpeedLeft
                                        maxMode: 10
                                        onModeChangedOnPressedChanged: {
                                            controlPageAsync.qml_setApi_hvac_driverSide_FanSpeed(mode)
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Text {
                                        text: "Passenger:"
                                        font.pixelSize: 14
                                        color: "#B0B0B0"
                                        font.family: "Segoe UI"
                                        width: 60
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    ModeControl {
                                        id: fanSpeedRight
                                        maxMode: 10
                                        onModeChangedOnPressedChanged: {
                                            controlPageAsync.qml_setApi_hvac_passengerSide_FanSpeed(mode)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Right control panel
                Rectangle {
                    id: rightPanel
                    width: 280
                    height: carIllustration.height
                    x: parent.width - width
                    y: 0
                    color: "#1A1A1A"
                    radius: 16
                    border.color: "#2A2A2A"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 24

                        // Gear Control
                        Column {
                            width: parent.width
                            spacing: 12

                            Text {
                                text: "Transmission"
                                font.pixelSize: 18
                                font.family: "Segoe UI"
                                font.weight: Font.Medium
                                color: "#00D4AA"
                            }

                            Grid {
                                id: gearButtons
                                columns: 2
                                spacing: 8
                                anchors.horizontalCenter: parent.horizontalCenter

                                property var buttons: []

                                function deselectOthers(selected) {
                                    for (let i = 0; i < buttons.length; i++) {
                                        if (buttons[i] !== selected) {
                                            buttons[i].checked = false
                                        } else {
                                            controlPageAsync.qml_setApi_gear(i)
                                        }
                                    }
                                }

                                function selectGear(mode) {
                                    for (let i = 0; i < buttons.length; i++) {
                                        if (i === mode) {
                                            buttons[i].checked = true
                                        } else {
                                            buttons[i].checked = false
                                        }
                                    }
                                }

                                ToggleButton {
                                    id: gearP
                                    text: "P"
                                    width: 60
                                    height: 60
                                    checked: true

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (!gearP.checked) {
                                                gearP.checked = true
                                                gearButtons.deselectOthers(gearP)
                                            }
                                        }
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                    Component.onCompleted: gearButtons.buttons.push(gearP)
                                }

                                ToggleButton {
                                    id: gearR
                                    text: "R"
                                    width: 60
                                    height: 60

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (!gearR.checked) {
                                                gearR.checked = true
                                                gearButtons.deselectOthers(gearR)
                                            }
                                        }
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                    Component.onCompleted: gearButtons.buttons.push(gearR)
                                }

                                ToggleButton {
                                    id: gearN
                                    text: "N"
                                    width: 60
                                    height: 60

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (!gearN.checked) {
                                                gearN.checked = true
                                                gearButtons.deselectOthers(gearN)
                                            }
                                        }
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                    Component.onCompleted: gearButtons.buttons.push(gearN)
                                }

                                ToggleButton {
                                    id: gearD
                                    text: "D"
                                    width: 60
                                    height: 60

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (!gearD.checked) {
                                                gearD.checked = true
                                                gearButtons.deselectOthers(gearD)
                                            }
                                        }
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                    Component.onCompleted: gearButtons.buttons.push(gearD)
                                }
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: "#2A2A2A" }

                        // Door and Access Controls
                        Column {
                            width: parent.width
                            spacing: 12

                            Text {
                                text: "Access Control"
                                font.pixelSize: 18
                                font.family: "Segoe UI"
                                font.weight: Font.Medium
                                color: "#00D4AA"
                            }

                            Column {
                                width: parent.width
                                spacing: 8

                                ToggleButton { 
                                    id: doorLeftBtn
                                    text: "Driver Door"
                                    width: parent.width
                                    onToggledChanged: {
                                        controlPageAsync.qml_setApi_door_driverSide_isOpen(checked)
                                    }
                                }

                                ToggleButton { 
                                    id: doorRightBtn
                                    text: "Passenger Door"
                                    width: parent.width
                                    onToggledChanged: {
                                        controlPageAsync.qml_setApi_door_passengerSide_isOpen(checked)
                                    }
                                }

                                ToggleButton { 
                                    id: trunkBtn
                                    text: "Trunk"
                                    width: parent.width
                                    onToggledChanged: {
                                        controlPageAsync.qml_setApi_trunk_rear_isOpen(checked)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}