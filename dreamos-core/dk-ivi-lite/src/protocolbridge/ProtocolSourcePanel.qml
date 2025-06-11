import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    color: "#3a3a3a"
    radius: 8
    border.color: "#555555"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10
        
        Text {
            text: "Protocol Sources"
            color: "#ffffff"
            font.bold: true
            font.pixelSize: 16
        }
        
        // Interface Mode Selection
        GroupBox {
            title: "Interface Mode"
            Layout.fillWidth: true
            
            background: Rectangle {
                color: "#404040"
                radius: 5
                border.color: "#666666"
            }
            
            label: Text {
                text: parent.title
                color: "#ffffff"
                font.bold: true
            }
            
            ColumnLayout {
                anchors.fill: parent
                
                ButtonGroup { id: modeGroup }
                
                RadioButton {
                    text: "🎮 Simulated"
                    ButtonGroup.group: modeGroup
                    checked: true
                    onToggled: if (checked) switchToSimulatedMode()
                    
                    indicator: Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        x: parent.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 8
                        border.color: parent.checked ? "#4CAF50" : "#666666"
                        color: parent.checked ? "#4CAF50" : "transparent"
                        
                        Rectangle {
                            width: 8
                            height: 8
                            x: 4
                            y: 4
                            radius: 4
                            color: parent.parent.checked ? "#ffffff" : "transparent"
                        }
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        leftPadding: parent.indicator.width + parent.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                RadioButton {
                    text: "🔌 Real Hardware"
                    ButtonGroup.group: modeGroup
                    onToggled: if (checked) switchToRealHardware()
                    
                    indicator: Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        x: parent.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 8
                        border.color: parent.checked ? "#4CAF50" : "#666666"
                        color: parent.checked ? "#4CAF50" : "transparent"
                        
                        Rectangle {
                            width: 8
                            height: 8
                            x: 4
                            y: 4
                            radius: 4
                            color: parent.parent.checked ? "#ffffff" : "transparent"
                        }
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        leftPadding: parent.indicator.width + parent.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                RadioButton {
                    text: "📁 Replay File"
                    ButtonGroup.group: modeGroup
                    onToggled: if (checked) switchToReplayMode()
                    
                    indicator: Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        x: parent.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 8
                        border.color: parent.checked ? "#4CAF50" : "#666666"
                        color: parent.checked ? "#4CAF50" : "transparent"
                        
                        Rectangle {
                            width: 8
                            height: 8
                            x: 4
                            y: 4
                            radius: 4
                            color: parent.parent.checked ? "#ffffff" : "transparent"
                        }
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        leftPadding: parent.indicator.width + parent.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        
        // Scenario Selection
        GroupBox {
            title: "Driving Scenarios"
            Layout.fillWidth: true
            
            background: Rectangle {
                color: "#404040"
                radius: 5
                border.color: "#666666"
            }
            
            label: Text {
                text: parent.title
                color: "#ffffff"
                font.bold: true
            }
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 5
                
                Button {
                    text: "🏙️ City Drive"
                    Layout.fillWidth: true
                    onClicked: console.log("Starting city drive scenario")
                    
                    background: Rectangle {
                        color: parent.pressed ? "#5a5a5a" : "#4a4a4a"
                        radius: 4
                        border.color: "#666666"
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                Button {
                    text: "🛣️ Highway"
                    Layout.fillWidth: true
                    onClicked: console.log("Starting highway scenario")
                    
                    background: Rectangle {
                        color: parent.pressed ? "#5a5a5a" : "#4a4a4a"
                        radius: 4
                        border.color: "#666666"
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                Button {
                    text: "🅿️ Parking"
                    Layout.fillWidth: true
                    onClicked: console.log("Starting parking scenario")
                    
                    background: Rectangle {
                        color: parent.pressed ? "#5a5a5a" : "#4a4a4a"
                        radius: 4
                        border.color: "#666666"
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                Button {
                    text: "🔧 Diagnostic"
                    Layout.fillWidth: true
                    onClicked: console.log("Starting diagnostic scenario")
                    
                    background: Rectangle {
                        color: parent.pressed ? "#5a5a5a" : "#4a4a4a"
                        radius: 4
                        border.color: "#666666"
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        
        // CAN Bus Simulator Controls
        GroupBox {
            title: "CAN Bus Simulator"
            Layout.fillWidth: true
            visible: true // Show when simulated mode is active
            
            background: Rectangle {
                color: "#404040"
                radius: 5
                border.color: "#666666"
            }
            
            label: Text {
                text: parent.title
                color: "#ffffff"
                font.bold: true
            }
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                
                Switch {
                    text: "Enable CAN Simulation"
                    checked: false
                    onToggled: console.log("CAN simulation:", checked)
                    
                    indicator: Rectangle {
                        implicitWidth: 48
                        implicitHeight: 26
                        x: parent.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 13
                        color: parent.checked ? "#4CAF50" : "#666666"
                        border.color: parent.checked ? "#4CAF50" : "#999999"
                        
                        Rectangle {
                            x: parent.parent.checked ? parent.width - width - 2 : 2
                            y: 2
                            width: 22
                            height: 22
                            radius: 11
                            color: "#ffffff"
                            
                            Behavior on x {
                                NumberAnimation { duration: 100 }
                            }
                        }
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        leftPadding: parent.indicator.width + parent.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                RowLayout {
                    Text { 
                        text: "Engine RPM:"
                        color: "#cccccc"
                        Layout.preferredWidth: 80
                    }
                    Slider {
                        id: rpmSlider
                        Layout.fillWidth: true
                        from: 800; to: 6000; value: 800
                        onValueChanged: console.log("RPM:", value)
                        
                        background: Rectangle {
                            x: rpmSlider.leftPadding
                            y: rpmSlider.topPadding + rpmSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 4
                            width: rpmSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#666666"
                            
                            Rectangle {
                                width: rpmSlider.visualPosition * parent.width
                                height: parent.height
                                color: "#4CAF50"
                                radius: 2
                            }
                        }
                        
                        handle: Rectangle {
                            x: rpmSlider.leftPadding + rpmSlider.visualPosition * (rpmSlider.availableWidth - width)
                            y: rpmSlider.topPadding + rpmSlider.availableHeight / 2 - height / 2
                            implicitWidth: 16
                            implicitHeight: 16
                            radius: 8
                            color: rpmSlider.pressed ? "#ffffff" : "#f0f0f0"
                            border.color: "#4CAF50"
                        }
                    }
                    Text { 
                        text: Math.round(rpmSlider.value)
                        color: "#4CAF50"
                        font.family: "monospace"
                        Layout.preferredWidth: 50
                    }
                }
                
                RowLayout {
                    Text { 
                        text: "Speed:"
                        color: "#cccccc"
                        Layout.preferredWidth: 80
                    }
                    Slider {
                        id: speedSlider
                        Layout.fillWidth: true
                        from: 0; to: 200; value: 0
                        onValueChanged: console.log("Speed:", value)
                        
                        background: Rectangle {
                            x: speedSlider.leftPadding
                            y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 4
                            width: speedSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#666666"
                            
                            Rectangle {
                                width: speedSlider.visualPosition * parent.width
                                height: parent.height
                                color: "#2196F3"
                                radius: 2
                            }
                        }
                        
                        handle: Rectangle {
                            x: speedSlider.leftPadding + speedSlider.visualPosition * (speedSlider.availableWidth - width)
                            y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                            implicitWidth: 16
                            implicitHeight: 16
                            radius: 8
                            color: speedSlider.pressed ? "#ffffff" : "#f0f0f0"
                            border.color: "#2196F3"
                        }
                    }
                    Text { 
                        text: Math.round(speedSlider.value) + " km/h"
                        color: "#2196F3"
                        font.family: "monospace"
                        Layout.preferredWidth: 80
                    }
                }
            }
        }
        
        // Protocol Interface Cards
        Repeater {
            model: [
                {name: "LIN Bus", icon: "📡", connected: false},
                {name: "FlexRay", icon: "⚡", connected: false},
                {name: "OBD-II", icon: "🔧", connected: false}
            ]
            
            delegate: ProtocolInterfaceCard {
                Layout.fillWidth: true
                protocolName: modelData.name
                protocolIcon: modelData.icon
                isConnected: modelData.connected
            }
        }
        
        Item { Layout.fillHeight: true }
    }
    
    function switchToSimulatedMode() {
        console.log("Switched to simulated mode")
    }
    
    function switchToRealHardware() {
        console.log("Switched to real hardware mode")
        hardwareConfigDialog.open()
    }
    
    function switchToReplayMode() {
        console.log("Switched to replay mode")
        replayFileDialog.open()
    }
    
    // Dialogs would be defined here or in parent
    property alias hardwareConfigDialog: hardwareConfigDialog
    property alias replayFileDialog: replayFileDialog
    
    Dialog {
        id: hardwareConfigDialog
        title: "Hardware Configuration"
        // Implementation would go here
    }
    
    Dialog {
        id: replayFileDialog
        title: "Select Replay File"
        // Implementation would go here
    }
}