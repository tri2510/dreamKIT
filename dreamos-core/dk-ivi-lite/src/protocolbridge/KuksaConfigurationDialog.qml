import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

Dialog {
    id: kuksaDialog
    title: "KUKSA Data Broker Configuration"
    width: 600
    height: 500
    modal: true
    
    background: Rectangle {
        color: "#3a3a3a"
        radius: 8
        border.color: "#555555"
    }
    
    header: Rectangle {
        height: 40
        color: "#2a2a2a"
        radius: 8
        
        Text {
            anchors.centerIn: parent
            text: kuksaDialog.title
            color: "#ffffff"
            font.bold: true
            font.pixelSize: 14
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15
        
        // Connection Mode Selection
        GroupBox {
            title: "Connection Mode"
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
                
                ButtonGroup { id: connectionModeGroup }
                
                RadioButton {
                    id: dockerModeRadio
                    text: "🐳 Default Docker Container"
                    ButtonGroup.group: connectionModeGroup
                    checked: true
                    onToggled: if (checked) setDockerMode()
                    
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
                    id: customModeRadio
                    text: "🌐 Custom Endpoint"
                    ButtonGroup.group: connectionModeGroup
                    onToggled: if (checked) setCustomMode()
                    
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
                    id: localModeRadio
                    text: "💻 Local Binary"
                    ButtonGroup.group: connectionModeGroup
                    onToggled: if (checked) setLocalMode()
                    
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
        
        // Docker Configuration
        GroupBox {
            id: dockerConfig
            title: "Docker Configuration"
            Layout.fillWidth: true
            visible: true
            
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
                columnSpacing: 10
                rowSpacing: 8
                
                Text { 
                    text: "Docker Image:"
                    color: "#cccccc"
                }
                RowLayout {
                    Layout.fillWidth: true
                    
                    TextField {
                        id: dockerImageField
                        Layout.fillWidth: true
                        text: "ghcr.io/eclipse/kuksa.val/kuksa-databroker:latest"
                        placeholderText: "Docker image URL"
                        color: "#ffffff"
                        
                        background: Rectangle {
                            color: "#555555"
                            border.color: "#777777"
                            radius: 4
                        }
                    }
                    Button {
                        text: "Pull Latest"
                        onClicked: pullLatestImage()
                        
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
                            font.pixelSize: 10
                        }
                    }
                }
                
                Text { 
                    text: "Container Port:"
                    color: "#cccccc"
                }
                SpinBox {
                    id: dockerPortSpin
                    from: 1000
                    to: 65535
                    value: 55555
                    
                    background: Rectangle {
                        color: "#555555"
                        border.color: "#777777"
                        radius: 4
                    }
                    
                    contentItem: TextInput {
                        text: dockerPortSpin.textFromValue(dockerPortSpin.value, dockerPortSpin.locale)
                        font: dockerPortSpin.font
                        color: "#ffffff"
                        selectionColor: "#4CAF50"
                        selectedTextColor: "#ffffff"
                        horizontalAlignment: Qt.AlignHCenter
                        verticalAlignment: Qt.AlignVCenter
                        readOnly: !dockerPortSpin.editable
                        validator: dockerPortSpin.validator
                        inputMethodHints: dockerPortSpin.inputMethodHints
                    }
                }
                
                Text { 
                    text: "Additional Args:"
                    color: "#cccccc"
                }
                TextField {
                    id: dockerArgsField
                    Layout.fillWidth: true
                    placeholderText: "--log-level debug --address 0.0.0.0"
                    color: "#ffffff"
                    
                    background: Rectangle {
                        color: "#555555"
                        border.color: "#777777"
                        radius: 4
                    }
                }
                
                CheckBox {
                    id: autoStartCheck
                    text: "Auto-start on connection"
                    checked: true
                    Layout.columnSpan: 2
                    
                    indicator: Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        x: parent.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 3
                        border.color: parent.checked ? "#4CAF50" : "#666666"
                        color: parent.checked ? "#4CAF50" : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: "#ffffff"
                            font.pixelSize: 10
                            visible: parent.parent.checked
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
        
        // Custom Endpoint Configuration
        GroupBox {
            id: customConfig
            title: "Custom Endpoint"
            Layout.fillWidth: true
            visible: false
            
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
                columnSpacing: 10
                rowSpacing: 8
                
                Text { 
                    text: "Host:"
                    color: "#cccccc"
                }
                TextField {
                    id: customHostField
                    Layout.fillWidth: true
                    text: "127.0.0.1"
                    placeholderText: "IP address or hostname"
                    color: "#ffffff"
                    
                    background: Rectangle {
                        color: "#555555"
                        border.color: "#777777"
                        radius: 4
                    }
                }
                
                Text { 
                    text: "Port:"
                    color: "#cccccc"
                }
                SpinBox {
                    id: customPortSpin
                    from: 1000
                    to: 65535
                    value: 55555
                    
                    background: Rectangle {
                        color: "#555555"
                        border.color: "#777777"
                        radius: 4
                    }
                    
                    contentItem: TextInput {
                        text: customPortSpin.textFromValue(customPortSpin.value, customPortSpin.locale)
                        font: customPortSpin.font
                        color: "#ffffff"
                        selectionColor: "#4CAF50"
                        selectedTextColor: "#ffffff"
                        horizontalAlignment: Qt.AlignHCenter
                        verticalAlignment: Qt.AlignVCenter
                        readOnly: !customPortSpin.editable
                        validator: customPortSpin.validator
                        inputMethodHints: customPortSpin.inputMethodHints
                    }
                }
                
                Text { 
                    text: "TLS Enabled:"
                    color: "#cccccc"
                }
                CheckBox {
                    id: tlsEnabledCheck
                    
                    indicator: Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        x: parent.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 3
                        border.color: parent.checked ? "#4CAF50" : "#666666"
                        color: parent.checked ? "#4CAF50" : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: "#ffffff"
                            font.pixelSize: 10
                            visible: parent.parent.checked
                        }
                    }
                }
                
                Text { 
                    text: "Certificate:"
                    color: "#cccccc"
                }
                RowLayout {
                    Layout.fillWidth: true
                    
                    TextField {
                        id: certPathField
                        Layout.fillWidth: true
                        placeholderText: "Path to certificate file (optional)"
                        color: "#ffffff"
                        
                        background: Rectangle {
                            color: "#555555"
                            border.color: "#777777"
                            radius: 4
                        }
                    }
                    Button {
                        text: "Browse"
                        onClicked: certFileDialog.open()
                        
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
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
        
        // Connection Status
        GroupBox {
            title: "Connection Status"
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
                spacing: 8
                
                RowLayout {
                    Text { 
                        text: "Status:"
                        color: "#cccccc"
                    }
                    Text {
                        text: getStatusText()
                        color: getStatusColor()
                        font.bold: true
                    }
                }
                
                RowLayout {
                    Text { 
                        text: "Endpoint:"
                        color: "#cccccc"
                    }
                    Text {
                        text: getCurrentEndpoint()
                        font.family: "monospace"
                        color: "#ffffff"
                    }
                }
                
                RowLayout {
                    Text { 
                        text: "Docker Status:"
                        color: "#cccccc"
                    }
                    Text {
                        text: getDockerStatus()
                        font.family: "monospace"
                        color: "#ffffff"
                    }
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    clip: true
                    
                    TextArea {
                        id: connectionInfoArea
                        readOnly: true
                        text: getConnectionInfo()
                        selectByMouse: true
                        font.family: "monospace"
                        font.pixelSize: 10
                        color: "#cccccc"
                        wrapMode: TextArea.Wrap
                        
                        background: Rectangle {
                            color: "#333333"
                            radius: 4
                            border.color: "#555555"
                        }
                    }
                }
            }
        }
        
        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Button {
                text: "Test Connection"
                Layout.fillWidth: true
                onClicked: testConnection()
                
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
                text: "Docker Logs"
                Layout.fillWidth: true
                onClicked: showDockerLogs()
                
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
                text: "Apply & Connect"
                Layout.fillWidth: true
                onClicked: applyAndConnect()
                
                background: Rectangle {
                    color: parent.pressed ? "#357a32" : "#4CAF50"
                    radius: 4
                    border.color: "#66BB6A"
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
            }
            
            Button {
                text: "Close"
                Layout.fillWidth: true
                onClicked: kuksaDialog.close()
                
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
    
    FileDialog {
        id: certFileDialog
        title: "Select Certificate File"
        onAccepted: certPathField.text = fileUrl
    }
    
    // Mock status properties
    property int connectionStatus: 2 // 0=Disconnected, 1=Connecting, 2=Connected, 3=Error
    property string dockerContainerStatus: "Running (ID: abc123...)"
    
    function setDockerMode() {
        dockerConfig.visible = true
        customConfig.visible = false
    }
    
    function setCustomMode() {
        dockerConfig.visible = false
        customConfig.visible = true
    }
    
    function setLocalMode() {
        dockerConfig.visible = false
        customConfig.visible = false
    }
    
    Timer {
        id: connectionTestTimer
        interval: 2000
        repeat: false
        onTriggered: {
            connectionStatus = 2 // Connected
        }
    }
    
    function testConnection() {
        console.log("Testing KUKSA connection...")
        // In real implementation, this would call the backend
        connectionStatus = 1 // Connecting
        
        // Start connection test timer
        connectionTestTimer.start()
    }
    
    function showDockerLogs() {
        console.log("Showing Docker logs...")
        // In real implementation, this would open terminal with docker logs
    }
    
    function applyAndConnect() {
        console.log("Applying configuration and connecting...")
        
        if (dockerConfig.visible) {
            console.log("Docker mode - Image:", dockerImageField.text)
            console.log("Auto-start:", autoStartCheck.checked)
        } else if (customConfig.visible) {
            console.log("Custom endpoint:", customHostField.text + ":" + customPortSpin.value)
            console.log("TLS enabled:", tlsEnabledCheck.checked)
        }
        
        // In real implementation, this would call the backend to apply settings
        testConnection()
        kuksaDialog.close()
    }
    
    function pullLatestImage() {
        console.log("Pulling latest KUKSA image...")
        // In real implementation, this would trigger docker pull
    }
    
    function getStatusText() {
        switch(connectionStatus) {
            case 2: return "Connected"
            case 1: return "Connecting..."
            case 3: return "Error"
            default: return "Disconnected"
        }
    }
    
    function getStatusColor() {
        switch(connectionStatus) {
            case 2: return "#4CAF50" // Connected
            case 1: return "#FF9800" // Connecting
            case 3: return "#f44336" // Error
            default: return "#9E9E9E" // Disconnected
        }
    }
    
    function getCurrentEndpoint() {
        if (customConfig.visible) {
            return customHostField.text + ":" + customPortSpin.value
        } else {
            return "127.0.0.1:" + dockerPortSpin.value
        }
    }
    
    function getDockerStatus() {
        return dockerContainerStatus
    }
    
    function getConnectionInfo() {
        var info = "Mode: " + (dockerConfig.visible ? "Docker Container" : customConfig.visible ? "Custom Endpoint" : "Local Binary") + "\n"
        
        if (dockerConfig.visible) {
            info += "Image: " + dockerImageField.text + "\n"
            info += "Port: " + dockerPortSpin.value + "\n"
            info += "Auto-start: " + (autoStartCheck.checked ? "Yes" : "No") + "\n"
            info += "Status: " + dockerContainerStatus
        } else if (customConfig.visible) {
            info += "Host: " + customHostField.text + "\n"
            info += "Port: " + customPortSpin.value + "\n"
            info += "TLS: " + (tlsEnabledCheck.checked ? "Enabled" : "Disabled")
        }
        
        return info
    }
}