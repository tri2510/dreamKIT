import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    color: "#1a1a1a"
    border.color: "#333333"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 0
        
        // Terminal header
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: "#2a2a2a"
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 5
                
                Text {
                    text: "🖥️ Terminal Console"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 12
                }
                
                Item { Layout.fillWidth: true }
                
                Button {
                    text: "Clear"
                    width: 50
                    height: 20
                    onClicked: clearTerminal()
                    
                    background: Rectangle {
                        color: parent.pressed ? "#555555" : "#404040"
                        radius: 4
                        border.color: "#666666"
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                Button {
                    text: "KUKSA CLI"
                    width: 70
                    height: 20
                    onClicked: connectKuksaCli()
                    
                    background: Rectangle {
                        color: parent.pressed ? "#555555" : "#404040"
                        radius: 4
                        border.color: "#666666"
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        
        // Terminal output area
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            TextArea {
                id: terminalOutput
                readOnly: true
                color: "#00ff00"
                font.family: "monospace"
                font.pixelSize: 11
                selectByMouse: true
                wrapMode: TextArea.Wrap
                
                background: Rectangle {
                    color: "#000000"
                }
                
                text: getInitialTerminalText()
                
                // Auto-scroll to bottom when text changes
                onTextChanged: {
                    cursorPosition = length
                }
            }
        }
        
        // Command input area
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: "#2a2a2a"
            border.color: "#555555"
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 5
                
                Text {
                    text: getCurrentPrompt()
                    color: "#00ff00"
                    font.family: "monospace"
                    font.pixelSize: 11
                }
                
                TextField {
                    id: commandInput
                    Layout.fillWidth: true
                    color: "#ffffff"
                    font.family: "monospace"
                    font.pixelSize: 11
                    placeholderText: "Enter command..."
                    
                    background: Rectangle {
                        color: "transparent"
                        border.color: "transparent"
                    }
                    
                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            executeCurrentCommand()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            showPreviousCommand()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                            showNextCommand()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Tab) {
                            autoCompleteCommand()
                            event.accepted = true
                        }
                    }
                }
                
                Button {
                    text: "▶"
                    width: 25
                    height: 20
                    onClicked: executeCurrentCommand()
                    
                    background: Rectangle {
                        color: parent.pressed ? "#555555" : "#404040"
                        radius: 4
                        border.color: "#666666"
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        
        // Quick command buttons
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "#2a2a2a"
            
            ScrollView {
                anchors.fill: parent
                contentWidth: quickCommandsRow.width
                
                Row {
                    id: quickCommandsRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    
                    Repeater {
                        model: [
                            {text: "ls", command: "ls"},
                            {text: "pwd", command: "pwd"},
                            {text: "docker ps", command: "docker ps"},
                            {text: "kuksa-client", command: "kuksa-client --host 127.0.0.1 --port 55555"},
                            {text: "VSS get", command: "vss-get"},
                            {text: "VSS set", command: "vss-set"},
                            {text: "dk-help", command: "dk-help"}
                        ]
                        
                        delegate: Button {
                            text: modelData.text
                            height: 25
                            onClicked: executeQuickCommand(modelData.command)
                            
                            background: Rectangle {
                                color: parent.pressed ? "#555555" : "#404040"
                                radius: 4
                                border.color: "#666666"
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: "#ffffff"
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Command history
    property var commandHistory: []
    property int historyIndex: -1
    
    function getInitialTerminalText() {
        return `<span style='color: #00ffff'>DreamKIT Terminal Console</span><br>
<span style='color: #ffff00'>Type 'dk-help' for DreamKIT-specific commands</span><br>
<span style='color: #ffff00'>Type 'help' for general help</span><br>
dk@dreamkit:$ `
    }
    
    function getCurrentPrompt() {
        return "dk@dreamkit:$ "
    }
    
    function executeCurrentCommand() {
        if (commandInput.text.trim() !== "") {
            var command = commandInput.text.trim()
            addToHistory(command)
            executeCommand(command)
            commandInput.text = ""
        }
    }
    
    function executeQuickCommand(command) {
        if (command === "vss-get" || command === "vss-set") {
            showVssDialog(command)
        } else {
            addToHistory(command)
            executeCommand(command)
        }
    }
    
    function executeCommand(command) {
        // Add command to output
        appendToTerminal(getCurrentPrompt() + command, "#ffffff")
        
        // Process command
        if (isBuiltinCommand(command)) {
            executeBuiltinCommand(command)
        } else {
            // Simulate system command execution
            executeSystemCommand(command)
        }
    }
    
    function isBuiltinCommand(command) {
        var builtins = ["dk-help", "dk-status", "dk-kuksa-status", "clear", 
                       "kuksa-start", "kuksa-stop", "kuksa-restart", "kuksa-logs",
                       "vss-get", "vss-set", "vss-list"]
        var cmd = command.split(' ')[0]
        return builtins.includes(cmd)
    }
    
    function executeBuiltinCommand(command) {
        var parts = command.split(' ')
        var cmd = parts[0]
        
        switch(cmd) {
            case "dk-help":
                appendToTerminal("DreamKIT Terminal Commands:", "#00ffff")
                appendToTerminal("  dk-help              - Show this help", "#ffffff")
                appendToTerminal("  dk-status            - Show DreamKIT system status", "#ffffff")
                appendToTerminal("  dk-kuksa-status      - Show KUKSA connection status", "#ffffff")
                appendToTerminal("  kuksa-start          - Start KUKSA Docker container", "#ffffff")
                appendToTerminal("  kuksa-stop           - Stop KUKSA Docker container", "#ffffff")
                appendToTerminal("  kuksa-restart        - Restart KUKSA Docker container", "#ffffff")
                appendToTerminal("  kuksa-logs           - Show KUKSA container logs", "#ffffff")
                appendToTerminal("  vss-get <path>       - Get VSS signal value", "#ffffff")
                appendToTerminal("  vss-set <path> <val> - Set VSS signal value", "#ffffff")
                appendToTerminal("  vss-list             - List available VSS signals", "#ffffff")
                appendToTerminal("  clear                - Clear terminal", "#ffffff")
                break
                
            case "dk-status":
                appendToTerminal("DreamKIT System Status:", "#00ffff")
                appendToTerminal("  Terminal Console: Active", "#00ff00")
                appendToTerminal("  Protocol Bridge: Running", "#00ff00")
                appendToTerminal("  VSS Signals: 12 active", "#ffffff")
                appendToTerminal("  Command History: " + commandHistory.length + " entries", "#ffffff")
                break
                
            case "dk-kuksa-status":
                appendToTerminal("KUKSA Connection Status:", "#00ffff")
                appendToTerminal("  Status: Connected", "#00ff00")
                appendToTerminal("  Endpoint: 127.0.0.1:55555", "#ffffff")
                appendToTerminal("  Docker Container: Running", "#00ff00")
                break
                
            case "clear":
                clearTerminal()
                return
                
            case "kuksa-start":
                appendToTerminal("Starting KUKSA Docker container...", "#ffff00")
                setTimeout(function() {
                    appendToTerminal("KUKSA container started successfully", "#00ff00")
                }, 1000)
                break
                
            case "kuksa-stop":
                appendToTerminal("Stopping KUKSA Docker container...", "#ffff00")
                setTimeout(function() {
                    appendToTerminal("KUKSA container stopped", "#00ff00")
                }, 1000)
                break
                
            case "vss-list":
                appendToTerminal("Available VSS Signals:", "#00ffff")
                appendToTerminal("  Vehicle.Speed", "#ffffff")
                appendToTerminal("  Vehicle.Powertrain.CombustionEngine.Speed", "#ffffff")
                appendToTerminal("  Vehicle.Cabin.Door.Row1.DriverSide.IsOpen", "#ffffff")
                appendToTerminal("  Vehicle.Body.Lights.Beam.Low.IsOn", "#ffffff")
                appendToTerminal("  Vehicle.CurrentLocation.Latitude", "#ffffff")
                appendToTerminal("  Vehicle.CurrentLocation.Longitude", "#ffffff")
                break
                
            case "vss-get":
                if (parts.length > 1) {
                    var path = parts[1]
                    appendToTerminal("Getting VSS value for: " + path, "#ffff00")
                    appendToTerminal("  Value: 65.5 km/h", "#00ff00")
                } else {
                    appendToTerminal("Usage: vss-get <VSS.Path>", "#ff0000")
                }
                break
                
            case "vss-set":
                if (parts.length > 2) {
                    var path = parts[1]
                    var value = parts[2]
                    appendToTerminal("Setting VSS value: " + path + " = " + value, "#ffff00")
                    appendToTerminal("  Success", "#00ff00")
                } else {
                    appendToTerminal("Usage: vss-set <VSS.Path> <value>", "#ff0000")
                }
                break
                
            default:
                appendToTerminal("Unknown command: " + cmd, "#ff0000")
        }
        
        appendPrompt()
    }
    
    function executeSystemCommand(command) {
        appendToTerminal("Executing: " + command, "#ffff00")
        
        // Simulate command execution
        setTimeout(function() {
            switch(command.split(' ')[0]) {
                case "ls":
                    appendToTerminal("total 8", "#ffffff")
                    appendToTerminal("drwxr-xr-x  2 dk dk 4096 Dec 21 10:30 .", "#ffffff")
                    appendToTerminal("drwxr-xr-x  3 dk dk 4096 Dec 21 10:29 ..", "#ffffff")
                    appendToTerminal("-rw-r--r--  1 dk dk  220 Dec 21 10:29 .bashrc", "#ffffff")
                    break
                    
                case "pwd":
                    appendToTerminal("/home/dk", "#ffffff")
                    break
                    
                case "docker":
                    if (command.includes("ps")) {
                        appendToTerminal("CONTAINER ID   IMAGE                    COMMAND       CREATED         STATUS         PORTS                    NAMES", "#ffffff")
                        appendToTerminal("abc123def456   kuksa-databroker:latest  \"./kuksa...\"  5 minutes ago   Up 5 minutes   0.0.0.0:55555->55555/tcp kuksa-databroker", "#ffffff")
                    }
                    break
                    
                default:
                    appendToTerminal("Command output would appear here", "#ffffff")
            }
            appendPrompt()
        }, 500)
    }
    
    function appendToTerminal(text, color) {
        var coloredText = "<span style='color: " + color + "'>" + text + "</span><br>"
        terminalOutput.append(coloredText)
    }
    
    function appendPrompt() {
        appendToTerminal(getCurrentPrompt(), "#00ff00")
    }
    
    function clearTerminal() {
        terminalOutput.text = getInitialTerminalText()
    }
    
    function connectKuksaCli() {
        executeCommand("kuksa-client --host 127.0.0.1 --port 55555")
    }
    
    function addToHistory(command) {
        if (command && (commandHistory.length === 0 || commandHistory[commandHistory.length - 1] !== command)) {
            commandHistory.push(command)
            if (commandHistory.length > 100) {
                commandHistory.shift()
            }
        }
        historyIndex = -1
    }
    
    function showPreviousCommand() {
        if (commandHistory.length === 0) return
        
        if (historyIndex === -1) {
            historyIndex = commandHistory.length - 1
        } else if (historyIndex > 0) {
            historyIndex--
        }
        
        if (historyIndex >= 0) {
            commandInput.text = commandHistory[historyIndex]
        }
    }
    
    function showNextCommand() {
        if (commandHistory.length === 0 || historyIndex === -1) return
        
        if (historyIndex < commandHistory.length - 1) {
            historyIndex++
            commandInput.text = commandHistory[historyIndex]
        } else {
            historyIndex = -1
            commandInput.text = ""
        }
    }
    
    function autoCompleteCommand() {
        // Simple auto-completion for common commands
        var text = commandInput.text
        var commands = ["dk-help", "dk-status", "dk-kuksa-status", "docker ps", "kuksa-client"]
        
        for (var i = 0; i < commands.length; i++) {
            if (commands[i].startsWith(text)) {
                commandInput.text = commands[i]
                break
            }
        }
    }
    
    function showVssDialog(command) {
        if (command === "vss-get") {
            vssGetDialog.open()
        } else if (command === "vss-set") {
            vssSetDialog.open()
        }
    }
    
    // VSS Quick dialogs
    Dialog {
        id: vssGetDialog
        title: "Quick VSS Get"
        width: 400
        height: 200
        
        ColumnLayout {
            anchors.fill: parent
            
            TextField {
                id: vssGetPathField
                Layout.fillWidth: true
                placeholderText: "Vehicle.Speed"
            }
            
            RowLayout {
                Button {
                    text: "Get Value"
                    onClicked: {
                        executeCommand("vss-get " + vssGetPathField.text)
                        vssGetDialog.close()
                    }
                }
                Button {
                    text: "Cancel"
                    onClicked: vssGetDialog.close()
                }
            }
        }
    }
    
    Dialog {
        id: vssSetDialog
        title: "Quick VSS Set"
        width: 400
        height: 250
        
        ColumnLayout {
            anchors.fill: parent
            
            TextField {
                id: vssSetPathField
                Layout.fillWidth: true
                placeholderText: "Vehicle.Speed"
            }
            
            TextField {
                id: vssValueField
                Layout.fillWidth: true
                placeholderText: "65.5"
            }
            
            RowLayout {
                Button {
                    text: "Set Value"
                    onClicked: {
                        executeCommand("vss-set " + vssSetPathField.text + " " + vssValueField.text)
                        vssSetDialog.close()
                    }
                }
                Button {
                    text: "Cancel"
                    onClicked: vssSetDialog.close()
                }
            }
        }
    }
}