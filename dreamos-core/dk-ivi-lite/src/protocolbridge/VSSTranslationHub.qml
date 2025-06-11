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
            text: "VSS Translation Hub"
            color: "#ffffff"
            font.bold: true
            font.pixelSize: 16
        }
        
        // Active VSS Signals
        GroupBox {
            title: "Active VSS Signals"
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            
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
            
            ScrollView {
                anchors.fill: parent
                clip: true
                
                ListView {
                    id: vssSignalsList
                    model: vssSignalsModel
                    
                    delegate: Rectangle {
                        width: vssSignalsList.width
                        height: 60
                        color: index % 2 ? "#4a4a4a" : "#555555"
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10
                            
                            // Protocol source indicator
                            Rectangle {
                                width: 8
                                height: 40
                                radius: 4
                                color: getProtocolColor(model.sourceProtocol || "")
                            }
                            
                            // Signal information
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Text {
                                    text: model.signalPath || "Vehicle.Signal.Path"
                                    font.bold: true
                                    color: "#2196F3"
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                
                                RowLayout {
                                    Text {
                                        text: (model.value || "0") + " " + (model.unit || "")
                                        color: "#4CAF50"
                                        font.family: "monospace"
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                    
                                    Item { Layout.fillWidth: true }
                                    
                                    Text {
                                        text: model.sourceProtocol || "SIM"
                                        color: "#FF9800"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }
                            
                            // Signal activity indicator
                            Rectangle {
                                width: 12
                                height: 12
                                radius: 6
                                color: "#4CAF50"
                                
                                SequentialAnimation on opacity {
                                    running: true
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.3; duration: 500 }
                                    NumberAnimation { to: 1.0; duration: 500 }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Translation Rules Visualization
        GroupBox {
            title: "Translation Rules"
            Layout.fillWidth: true
            Layout.fillHeight: true
            
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
            
            ScrollView {
                anchors.fill: parent
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    spacing: 8
                    
                    // Translation rule examples
                    Repeater {
                        model: [
                            {
                                source: "CAN ID 0x123",
                                vss: "Vehicle.Powertrain.CombustionEngine.Speed",
                                transform: "Raw value → RPM",
                                active: true
                            },
                            {
                                source: "CAN ID 0x124", 
                                vss: "Vehicle.Speed",
                                transform: "Raw × 0.01 → km/h",
                                active: true
                            },
                            {
                                source: "LIN ID 0x31",
                                vss: "Vehicle.Cabin.Door.Row1.DriverSide.Window.Position",
                                transform: "Position % → VSS %",
                                active: false
                            },
                            {
                                source: "OBD PID 0x0C",
                                vss: "Vehicle.Powertrain.CombustionEngine.Speed", 
                                transform: "((A*256)+B)/4 → RPM",
                                active: false
                            }
                        ]
                        
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 80
                            color: "#4a4a4a"
                            radius: 6
                            border.color: modelData.active ? "#4CAF50" : "#666666"
                            opacity: modelData.active ? 1.0 : 0.6
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 15
                                
                                // Source protocol
                                Rectangle {
                                    width: 100
                                    height: 50
                                    color: "#555555"
                                    radius: 4
                                    border.color: "#777777"
                                    
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        
                                        Text {
                                            text: getProtocolIcon(modelData.source)
                                            font.pixelSize: 16
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        
                                        Text {
                                            text: modelData.source
                                            color: "#ffffff"
                                            font.pixelSize: 9
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                }
                                
                                // Arrow with transformation
                                Column {
                                    spacing: 2
                                    
                                    Text {
                                        text: "→"
                                        color: "#2196F3"
                                        font.pixelSize: 20
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    
                                    Text {
                                        text: modelData.transform
                                        color: "#FF9800"
                                        font.pixelSize: 8
                                        horizontalAlignment: Text.AlignHCenter
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                                
                                // VSS signal
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 50
                                    color: "#555555"
                                    radius: 4
                                    border.color: "#777777"
                                    
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        
                                        Text {
                                            text: "📊"
                                            font.pixelSize: 16
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        
                                        Text {
                                            text: modelData.vss
                                            color: "#2196F3"
                                            font.pixelSize: 9
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            wrapMode: Text.WordWrap
                                            width: parent.parent.width - 20
                                        }
                                    }
                                }
                                
                                // Activity indicator
                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: modelData.active ? "#4CAF50" : "#666666"
                                    
                                    SequentialAnimation on scale {
                                        running: modelData.active
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.8; duration: 300 }
                                        NumberAnimation { to: 1.0; duration: 300 }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Mock VSS signals model
    ListModel {
        id: vssSignalsModel
        
        ListElement {
            signalPath: "Vehicle.Powertrain.CombustionEngine.Speed"
            value: "1850"
            unit: "rpm"
            sourceProtocol: "CAN"
        }
        
        ListElement {
            signalPath: "Vehicle.Speed"
            value: "65.5"
            unit: "km/h"
            sourceProtocol: "CAN"
        }
        
        ListElement {
            signalPath: "Vehicle.Body.Lights.Beam.Low.IsOn"
            value: "false"
            unit: ""
            sourceProtocol: "CAN"
        }
        
        ListElement {
            signalPath: "Vehicle.CurrentLocation.Latitude"
            value: "37.7749"
            unit: "deg"
            sourceProtocol: "GPS"
        }
    }
    
    function getProtocolColor(protocol) {
        switch(protocol) {
            case "CAN": return "#4CAF50"
            case "LIN": return "#2196F3"
            case "FlexRay": return "#FF9800"
            case "OBD": return "#9C27B0"
            case "GPS": return "#00BCD4"
            default: return "#666666"
        }
    }
    
    function getProtocolIcon(source) {
        if (source.includes("CAN")) return "🚌"
        if (source.includes("LIN")) return "📡"
        if (source.includes("OBD")) return "🔧"
        if (source.includes("FlexRay")) return "⚡"
        return "📊"
    }
}