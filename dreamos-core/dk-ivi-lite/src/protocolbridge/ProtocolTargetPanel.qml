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
            text: "Target Protocols"
            color: "#ffffff"
            font.bold: true
            font.pixelSize: 16
        }
        
        // SOME/IP Output
        GroupBox {
            title: "📤 SOME/IP Service Output"
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            
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
                
                RowLayout {
                    Text { 
                        text: "Service ID:"
                        color: "#cccccc"
                        font.pixelSize: 10
                    }
                    Text { 
                        text: "0x1234"
                        color: "#4CAF50"
                        font.family: "monospace"
                        font.pixelSize: 10
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: "#4CAF50"
                        
                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 800 }
                            NumberAnimation { to: 1.0; duration: 800 }
                        }
                    }
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    TextArea {
                        id: someipOutput
                        readOnly: true
                        color: "#00ff00"
                        font.family: "monospace"
                        font.pixelSize: 10
                        selectByMouse: true
                        wrapMode: TextArea.Wrap
                        
                        text: `{"service_id":"0x1234","method_id":"0x8001","timestamp":1703123456789,"data":{"engine_rpm":1850,"vehicle_speed":65.5,"gear":4,"headlights":false}}`
                        
                        background: Rectangle {
                            color: "#000000"
                            radius: 4
                            border.color: "#333333"
                        }
                    }
                }
            }
        }
        
        // REST API Output
        GroupBox {
            title: "🌐 REST API Output"
            Layout.fillWidth: true
            Layout.preferredHeight: 250
            
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
                
                RowLayout {
                    Text { 
                        text: "Endpoint:"
                        color: "#cccccc"
                        font.pixelSize: 10
                    }
                    Text { 
                        text: "/api/vehicle/telemetry"
                        color: "#2196F3"
                        font.family: "monospace"
                        font.pixelSize: 10
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: "#2196F3"
                        
                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 1200 }
                            NumberAnimation { to: 1.0; duration: 1200 }
                        }
                    }
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    TextArea {
                        id: restApiOutput
                        readOnly: true
                        color: "#00ff00"
                        font.family: "monospace"
                        font.pixelSize: 9
                        selectByMouse: true
                        wrapMode: TextArea.Wrap
                        
                        text: `{
  "method": "POST",
  "endpoint": "/api/vehicle/telemetry",
  "timestamp": "2023-12-21T10:30:56Z",
  "payload": {
    "Vehicle.Speed": 65.5,
    "Vehicle.Powertrain.CombustionEngine.Speed": 1850,
    "Vehicle.Powertrain.Transmission.CurrentGear": 4,
    "Vehicle.Body.Lights.Beam.Low.IsOn": false
  }
}`
                        
                        background: Rectangle {
                            color: "#000000"
                            radius: 4
                            border.color: "#333333"
                        }
                    }
                }
            }
        }
        
        // Mobile App JSON Output
        GroupBox {
            title: "📱 Mobile App JSON"
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
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 5
                
                RowLayout {
                    Text { 
                        text: "Format:"
                        color: "#cccccc"
                        font.pixelSize: 10
                    }
                    Text { 
                        text: "Mobile Dashboard JSON"
                        color: "#FF9800"
                        font.family: "monospace"
                        font.pixelSize: 10
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: "#FF9800"
                        
                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 1000 }
                            NumberAnimation { to: 1.0; duration: 1000 }
                        }
                    }
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    TextArea {
                        id: mobileOutput
                        readOnly: true
                        color: "#00ff00"
                        font.family: "monospace"
                        font.pixelSize: 9
                        selectByMouse: true
                        wrapMode: TextArea.Wrap
                        
                        text: `{
  "dashboard": {
    "speed": "65.5 km/h",
    "rpm": "1850 RPM", 
    "gear": "D4",
    "fuel": "75%",
    "engine_temp": "90°C"
  },
  "status": {
    "headlights": false,
    "doors_locked": true,
    "parking_brake": false
  },
  "last_update": "2023-12-21T10:30:56Z"
}`
                        
                        background: Rectangle {
                            color: "#000000"
                            radius: 4
                            border.color: "#333333"
                        }
                    }
                }
            }
        }
        
        // Protocol Statistics
        GroupBox {
            title: "📊 Protocol Statistics"
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            
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
            
            GridLayout {
                anchors.fill: parent
                columns: 2
                columnSpacing: 20
                rowSpacing: 5
                
                Text {
                    text: "SOME/IP Messages:"
                    color: "#cccccc"
                    font.pixelSize: 10
                }
                Text {
                    text: "1,247 sent"
                    color: "#4CAF50"
                    font.family: "monospace"
                    font.pixelSize: 10
                }
                
                Text {
                    text: "REST API Calls:"
                    color: "#cccccc"
                    font.pixelSize: 10
                }
                Text {
                    text: "523 requests"
                    color: "#2196F3"
                    font.family: "monospace"
                    font.pixelSize: 10
                }
                
                Text {
                    text: "Mobile Updates:"
                    color: "#cccccc"
                    font.pixelSize: 10
                }
                Text {
                    text: "89 pushes"
                    color: "#FF9800"
                    font.family: "monospace"
                    font.pixelSize: 10
                }
                
                Text {
                    text: "Data Rate:"
                    color: "#cccccc"
                    font.pixelSize: 10
                }
                Text {
                    text: "15.2 KB/s"
                    color: "#9C27B0"
                    font.family: "monospace"
                    font.pixelSize: 10
                }
                
                Text {
                    text: "VSS Signals:"
                    color: "#cccccc"
                    font.pixelSize: 10
                }
                Text {
                    text: "12 active"
                    color: "#00BCD4"
                    font.family: "monospace"
                    font.pixelSize: 10
                }
                
                Text {
                    text: "Errors:"
                    color: "#cccccc"
                    font.pixelSize: 10
                }
                Text {
                    text: "0 errors"
                    color: "#4CAF50"
                    font.family: "monospace"
                    font.pixelSize: 10
                }
            }
        }
    }
    
    // Update timer for realistic data changes
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: updateOutputs()
    }
    
    function updateOutputs() {
        // In a real implementation, this would be connected to the backend
        // For demo purposes, we'll just trigger some visual updates
        
        // Update timestamps and some values
        var currentTime = new Date().toISOString()
        var speed = (Math.random() * 40 + 50).toFixed(1)
        var rpm = Math.floor(Math.random() * 1000 + 1500)
        
        // This would update the actual output text areas
        // someipOutput.text = ... (updated JSON)
        // restApiOutput.text = ... (updated JSON)
        // mobileOutput.text = ... (updated JSON)
    }
}