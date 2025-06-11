import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ProtocolBridge 1.0

Rectangle {
    id: root
    anchors.fill: parent
    color: "#2b2b2b"
    
    // Access the backend Protocol Bridge Manager
    property var protocolManager: protocolBridge
    property var kuksaManager: kuksaManager
    property var terminal: terminalConsole
    
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
    
    // Main content
    ScrollView {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        
        ColumnLayout {
            width: root.width - 20
            spacing: 15
            
            // KUKSA Status Card
            Rectangle {
                Layout.fillWidth: true
                height: 100
                color: "#3a3a3a"
                radius: 6
                border.color: "#555555"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 8
                    
                    // Status row
                    RowLayout {
                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: kuksaManager ? getKuksaStatusColor() : "#888888"
                            
                            function getKuksaStatusColor() {
                                if (!kuksaManager) return "#888888"
                                switch(kuksaManager.status) {
                                    case 0: return "#ff4444" // Disconnected
                                    case 1: return "#ffaa00" // Connecting  
                                    case 2: return "#00ff00" // Connected
                                    case 3: return "#ff0088" // Error
                                    default: return "#888888"
                                }
                            }
                        }
                        
                        Text {
                            text: kuksaManager ? getKuksaStatusText() : "KUKSA: Unknown"
                            color: "#ffffff"
                            font.pixelSize: 14
                            
                            function getKuksaStatusText() {
                                switch(kuksaManager.status) {
                                    case 0: return "KUKSA Data Broker: Disconnected"
                                    case 1: return "KUKSA Data Broker: Connecting..."
                                    case 2: return "KUKSA Data Broker: Connected"
                                    case 3: return "KUKSA Data Broker: Error"
                                    default: return "KUKSA Data Broker: Unknown"
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "Configure"
                            background: Rectangle {
                                color: "#0066cc"
                                radius: 4
                            }
                            onClicked: kuksaConfigDialog.open()
                        }
                    }
                    
                    // Connection info row
                    RowLayout {
                        Text {
                            text: kuksaManager ? ("Endpoint: " + kuksaManager.endpoint) : "Endpoint: Not configured"
                            color: "#cccccc"
                            font.pixelSize: 11
                            font.family: "monospace"
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Text {
                            text: kuksaManager ? ("Docker: " + kuksaManager.dockerStatus) : "Docker: Unknown"
                            color: "#cccccc" 
                            font.pixelSize: 11
                            font.family: "monospace"
                        }
                    }
                }
            }
            
            // CAN Bus Control Card
            Rectangle {
                Layout.fillWidth: true
                height: 200
                color: "#3a3a3a"
                radius: 6
                border.color: "#555555"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    Text {
                        text: "CAN Bus Simulation"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 16
                    }
                    
                    RowLayout {
                        Text {
                            text: "Engine RPM:"
                            color: "#cccccc"
                            Layout.preferredWidth: 100
                        }
                        SpinBox {
                            from: 600
                            to: 8000
                            value: 1800
                            onValueChanged: {
                                if (protocolManager) {
                                    protocolManager.updateCanRpm(value)
                                }
                            }
                        }
                        Text {
                            text: "RPM"
                            color: "#888888"
                        }
                    }
                    
                    RowLayout {
                        Text {
                            text: "Speed:"
                            color: "#cccccc"
                            Layout.preferredWidth: 100
                        }
                        SpinBox {
                            from: 0
                            to: 250
                            value: 65
                            onValueChanged: {
                                if (protocolManager) {
                                    protocolManager.updateCanSpeed(value)
                                }
                            }
                        }
                        Text {
                            text: "km/h"
                            color: "#888888"
                        }
                    }
                    
                    RowLayout {
                        Text {
                            text: "Gear:"
                            color: "#cccccc"
                            Layout.preferredWidth: 100
                        }
                        SpinBox {
                            from: 0
                            to: 6
                            value: 4
                            onValueChanged: {
                                if (protocolManager) {
                                    protocolManager.updateCanGear(value)
                                }
                            }
                        }
                    }
                }
            }
            
            // Simulation Controls Card
            Rectangle {
                Layout.fillWidth: true
                height: 80
                color: "#3a3a3a"
                radius: 6
                border.color: "#555555"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    
                    Text {
                        text: "Simulation:"
                        color: "#ffffff"
                        font.bold: true
                    }
                    
                    Button {
                        text: "▶ Play"
                        background: Rectangle {
                            color: "#00aa00"
                            radius: 4
                        }
                        onClicked: {
                            if (protocolManager) {
                                protocolManager.play()
                            }
                        }
                    }
                    
                    Button {
                        text: "⏸ Pause"
                        background: Rectangle {
                            color: "#cc8800"
                            radius: 4
                        }
                        onClicked: {
                            if (protocolManager) {
                                protocolManager.pause()
                            }
                        }
                    }
                    
                    Button {
                        text: "⏹ Stop"
                        background: Rectangle {
                            color: "#cc0000"
                            radius: 4
                        }
                        onClicked: {
                            if (protocolManager) {
                                protocolManager.stop()
                            }
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text {
                        text: protocolManager ? getPlaybackStatus() : "Status: Unknown"
                        color: "#00ff88"
                        font.family: "monospace"
                        
                        function getPlaybackStatus() {
                            if (protocolManager.isPlaying) return "Status: Playing"
                            if (protocolManager.isRecording) return "Status: Recording"
                            return "Status: Ready"
                        }
                    }
                }
            }
            
            // Scenario Controls Card
            Rectangle {
                Layout.fillWidth: true
                height: 120
                color: "#3a3a3a"
                radius: 6
                border.color: "#555555"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    Text {
                        text: "Driving Scenarios"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 16
                    }
                    
                    GridLayout {
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 8
                        Layout.fillWidth: true
                        
                        Button {
                            text: "🏙️ City Drive"
                            Layout.fillWidth: true
                            background: Rectangle {
                                color: "#0066cc"
                                radius: 4
                            }
                            onClicked: {
                                if (protocolManager) {
                                    protocolManager.startCityDriveScenario()
                                }
                            }
                        }
                        
                        Button {
                            text: "🛣️ Highway"
                            Layout.fillWidth: true
                            background: Rectangle {
                                color: "#0066cc"
                                radius: 4
                            }
                            onClicked: {
                                if (protocolManager) {
                                    protocolManager.startHighwayScenario()
                                }
                            }
                        }
                        
                        Button {
                            text: "🅿️ Parking"
                            Layout.fillWidth: true
                            background: Rectangle {
                                color: "#0066cc"
                                radius: 4
                            }
                            onClicked: {
                                if (protocolManager) {
                                    protocolManager.startParkingScenario()
                                }
                            }
                        }
                        
                        Button {
                            text: "🔧 Diagnostic"
                            Layout.fillWidth: true
                            background: Rectangle {
                                color: "#cc6600"
                                radius: 4
                            }
                            onClicked: {
                                if (protocolManager) {
                                    protocolManager.startDiagnosticScenario()
                                }
                            }
                        }
                    }
                }
            }
            
            // Timeline Control Card  
            Rectangle {
                Layout.fillWidth: true
                height: 100
                color: "#3a3a3a"
                radius: 6
                border.color: "#555555"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    RowLayout {
                        Text {
                            text: "Timeline:"
                            color: "#ffffff"
                            font.bold: true
                        }
                        
                        Text {
                            text: protocolManager ? (protocolManager.timelinePosition + " / " + protocolManager.timelineDuration) : "00:00 / 00:00"
                            color: "#cccccc"
                            font.family: "monospace"
                            font.pixelSize: 12
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Text {
                            text: protocolManager ? (protocolManager.playbackSpeed + "x") : "1.0x"
                            color: "#cccccc"
                            font.pixelSize: 12
                        }
                    }
                    
                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: 1
                        value: 0
                        onValueChanged: {
                            if (pressed && protocolManager) {
                                protocolManager.seekToPosition(value)
                            }
                        }
                        
                        background: Rectangle {
                            width: parent.width
                            height: 6
                            color: "#555555"
                            radius: 3
                            
                            Rectangle {
                                width: parent.parent.visualPosition * parent.width
                                height: parent.height
                                color: "#0066cc"
                                radius: 3
                            }
                        }
                        
                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: 16
                            height: 16
                            radius: 8
                            color: "#ffffff"
                            border.color: "#0066cc"
                            border.width: 2
                        }
                    }
                    
                    RowLayout {
                        Button {
                            text: "0.1x"
                            width: 40
                            onClicked: if (protocolManager) protocolManager.setPlaybackSpeed(0.1)
                        }
                        Button {
                            text: "0.5x"
                            width: 40
                            onClicked: if (protocolManager) protocolManager.setPlaybackSpeed(0.5)
                        }
                        Button {
                            text: "1x"
                            width: 40
                            onClicked: if (protocolManager) protocolManager.setPlaybackSpeed(1.0)
                        }
                        Button {
                            text: "2x"
                            width: 40
                            onClicked: if (protocolManager) protocolManager.setPlaybackSpeed(2.0)
                        }
                        Button {
                            text: "5x"
                            width: 40
                            onClicked: if (protocolManager) protocolManager.setPlaybackSpeed(5.0)
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "🔴 Record"
                            background: Rectangle {
                                color: protocolManager && protocolManager.isRecording ? "#ff4444" : "#cc0000"
                                radius: 4
                            }
                            onClicked: {
                                if (protocolManager) {
                                    protocolManager.record()
                                }
                            }
                        }
                    }
                }
            }
            
            // VSS Signals Card
            Rectangle {
                Layout.fillWidth: true
                height: 180
                color: "#3a3a3a"
                radius: 6
                border.color: "#555555"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    Text {
                        text: "Active VSS Signals"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 16
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#2a2a2a"
                        radius: 4
                        
                        ListView {
                            anchors.fill: parent
                            anchors.margins: 5
                            
                            model: protocolManager ? protocolManager.vssSignalModel : null
                            
                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 25
                                color: index % 2 ? "#3a3a3a" : "#4a4a4a"
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    
                                    Text {
                                        text: model.signalPath || "Unknown Signal"
                                        color: "#ffffff"
                                        font.pixelSize: 11
                                        Layout.preferredWidth: 200
                                        elide: Text.ElideRight
                                    }
                                    
                                    Text {
                                        text: (model.value || "N/A") + " " + (model.unit || "")
                                        color: "#00ff88"
                                        font.pixelSize: 11
                                        font.family: "monospace"
                                        Layout.preferredWidth: 80
                                    }
                                    
                                    Text {
                                        text: model.sourceProtocol || "Unknown"
                                        color: "#88ccff"
                                        font.pixelSize: 10
                                        Layout.preferredWidth: 50
                                    }
                                    
                                    Text {
                                        text: model.timestamp ? new Date(model.timestamp).toLocaleTimeString() : "--:--:--"
                                        color: "#cccccc"
                                        font.pixelSize: 10
                                        font.family: "monospace"
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Terminal Console Card
            Rectangle {
                Layout.fillWidth: true
                height: 200
                color: "#3a3a3a"
                radius: 6
                border.color: "#555555"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    RowLayout {
                        Text {
                            text: "Terminal Console"
                            color: "#ffffff"
                            font.bold: true
                            font.pixelSize: 16
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "Clear"
                            background: Rectangle {
                                color: "#666666"
                                radius: 4
                            }
                            onClicked: {
                                if (terminal) {
                                    terminal.clear()
                                }
                            }
                        }
                        
                        Button {
                            text: "KUKSA CLI"
                            background: Rectangle {
                                color: "#0066cc"
                                radius: 4
                            }
                            onClicked: {
                                if (terminal) {
                                    terminal.connectKuksaCli()
                                }
                            }
                        }
                    }
                    
                    // Terminal output area
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#1a1a1a"
                        radius: 4
                        border.color: "#444444"
                        
                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 5
                            
                            Text {
                                width: parent.width - 10
                                text: terminal ? terminal.output : "Terminal not available"
                                color: "#00ff00"
                                font.family: "monospace"
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                                textFormat: Text.RichText
                            }
                        }
                    }
                    
                    // Command input
                    RowLayout {
                        Text {
                            text: "$ "
                            color: "#00ff00"
                            font.family: "monospace"
                            font.bold: true
                        }
                        
                        TextField {
                            id: commandInput
                            Layout.fillWidth: true
                            placeholderText: "Enter command (try: dk-help, vss-get Vehicle.Speed, docker ps)"
                            background: Rectangle {
                                color: "#2a2a2a"
                                border.color: "#555555"
                                radius: 4
                            }
                            color: "#ffffff"
                            font.family: "monospace"
                            
                            onAccepted: {
                                if (terminal && text.length > 0) {
                                    terminal.executeCommand(text)
                                    text = ""
                                }
                            }
                        }
                        
                        Button {
                            text: "Execute"
                            background: Rectangle {
                                color: "#00aa00"
                                radius: 4
                            }
                            onClicked: {
                                if (terminal && commandInput.text.length > 0) {
                                    terminal.executeCommand(commandInput.text)
                                    commandInput.text = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // KUKSA Configuration Dialog
    KuksaConfigurationDialog {
        id: kuksaConfigDialog
        kuksaManager: root.kuksaManager
    }
}