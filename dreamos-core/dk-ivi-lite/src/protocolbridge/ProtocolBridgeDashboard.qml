import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    anchors.fill: parent
    color: "#2b2b2b"
    
    // Header
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: "#1e1e1e"
        
        Text {
            anchors.centerIn: parent
            text: "🚗 DreamKIT SDV Protocol Bridge"
            color: "#ffffff"
            font.bold: true
            font.pixelSize: 18
        }
    }
    
    // Main content area
    Rectangle {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        color: "#3a3a3a"
        radius: 8
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20
            
            // KUKSA Connection Status
            Rectangle {
                Layout.fillWidth: true
                height: 80
                color: "#4a4a4a"
                radius: 6
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    
                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: "#00ff00" // Green for connected
                    }
                    
                    Text {
                        text: "KUKSA Data Broker: Connected"
                        color: "#ffffff"
                        font.pixelSize: 14
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Button {
                        text: "Configure"
                        onClicked: console.log("KUKSA configuration requested")
                    }
                }
            }
            
            // Protocol Simulation Controls
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#4a4a4a"
                radius: 6
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    
                    Text {
                        text: "Protocol Simulation"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 16
                    }
                    
                    // CAN Bus simulation
                    GroupBox {
                        title: "CAN Bus Simulation"
                        Layout.fillWidth: true
                        
                        ColumnLayout {
                            anchors.fill: parent
                            
                            RowLayout {
                                Text {
                                    text: "Engine RPM:"
                                    color: "#ffffff"
                                }
                                SpinBox {
                                    from: 600
                                    to: 8000
                                    value: 1800
                                    onValueChanged: console.log("RPM:", value)
                                }
                            }
                            
                            RowLayout {
                                Text {
                                    text: "Vehicle Speed:"
                                    color: "#ffffff"
                                }
                                SpinBox {
                                    from: 0
                                    to: 250
                                    value: 65
                                    suffix: " km/h"
                                    onValueChanged: console.log("Speed:", value)
                                }
                            }
                            
                            RowLayout {
                                Text {
                                    text: "Gear:"
                                    color: "#ffffff"
                                }
                                SpinBox {
                                    from: 0
                                    to: 6
                                    value: 4
                                    onValueChanged: console.log("Gear:", value)
                                }
                            }
                        }
                    }
                    
                    // Playback controls
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Button {
                            text: "▶ Play"
                            onClicked: console.log("Play simulation")
                        }
                        
                        Button {
                            text: "⏸ Pause"
                            onClicked: console.log("Pause simulation")
                        }
                        
                        Button {
                            text: "⏹ Stop"
                            onClicked: console.log("Stop simulation")
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Text {
                            text: "Speed: 1.0x"
                            color: "#ffffff"
                        }
                    }
                }
            }
            
            // VSS Signals Display
            Rectangle {
                Layout.fillWidth: true
                height: 150
                color: "#4a4a4a"
                radius: 6
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    
                    Text {
                        text: "Active VSS Signals"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 16
                    }
                    
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        ListView {
                            model: ListModel {
                                ListElement { signal: "Vehicle.Speed"; value: "65.5 km/h"; source: "CAN" }
                                ListElement { signal: "Vehicle.Powertrain.CombustionEngine.Speed"; value: "1850 RPM"; source: "CAN" }
                                ListElement { signal: "Vehicle.CurrentLocation.Heading"; value: "142.8°"; source: "FlexRay" }
                            }
                            
                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 30
                                color: index % 2 ? "#5a5a5a" : "#6a6a6a"
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    
                                    Text {
                                        text: model.signal
                                        color: "#ffffff"
                                        Layout.preferredWidth: 200
                                    }
                                    
                                    Text {
                                        text: model.value
                                        color: "#00ff88"
                                        Layout.preferredWidth: 100
                                    }
                                    
                                    Text {
                                        text: model.source
                                        color: "#88ccff"
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