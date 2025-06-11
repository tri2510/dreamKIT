import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    height: 100
    color: "#4a4a4a"
    radius: 8
    border.color: isConnected ? "#4CAF50" : "#666666"
    border.width: 2
    
    property string protocolName: ""
    property string protocolIcon: "📊"
    property bool isConnected: false
    property alias interfaceMode: modeCombo.currentText
    
    signal modeChanged(string mode)
    signal configRequested()
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        // Protocol icon and status
        Column {
            spacing: 5
            
            Text {
                text: protocolIcon
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: protocolName
                color: "#ffffff"
                font.bold: true
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Rectangle {
                width: 8; height: 8
                radius: 4
                color: isConnected ? "#4CAF50" : "#f44336"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        
        // Interface controls
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            
            ComboBox {
                id: modeCombo
                Layout.fillWidth: true
                model: ["Simulated", "Real HW", "Replay"]
                onCurrentTextChanged: root.modeChanged(currentText)
                
                background: Rectangle {
                    color: "#555555"
                    border.color: "#777777"
                    radius: 4
                }
                
                contentItem: Text {
                    text: modeCombo.displayText
                    color: "#ffffff"
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                }
                
                popup: Popup {
                    y: modeCombo.height - 1
                    width: modeCombo.width
                    implicitHeight: contentItem.implicitHeight
                    padding: 1
                    
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: modeCombo.popup.visible ? modeCombo.delegateModel : null
                        currentIndex: modeCombo.highlightedIndex
                        
                        ScrollIndicator.vertical: ScrollIndicator { }
                    }
                    
                    background: Rectangle {
                        color: "#555555"
                        border.color: "#777777"
                        radius: 4
                    }
                }
                
                delegate: ItemDelegate {
                    width: modeCombo.width
                    contentItem: Text {
                        text: modelData
                        color: "#ffffff"
                        verticalAlignment: Text.AlignVCenter
                    }
                    highlighted: modeCombo.highlightedIndex === index
                    
                    background: Rectangle {
                        color: highlighted ? "#666666" : "transparent"
                    }
                }
            }
            
            RowLayout {
                Button {
                    text: "Config"
                    Layout.fillWidth: true
                    enabled: modeCombo.currentText === "Real HW"
                    onClicked: root.configRequested()
                    
                    background: Rectangle {
                        color: parent.enabled ? (parent.pressed ? "#5a5a5a" : "#4a4a4a") : "#333333"
                        radius: 4
                        border.color: "#666666"
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "#ffffff" : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 10
                    }
                }
                
                Button {
                    text: isConnected ? "Disconnect" : "Connect"
                    Layout.fillWidth: true
                    onClicked: toggleConnection()
                    
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
        
        // Real-time data preview
        Rectangle {
            width: 60
            Layout.fillHeight: true
            color: "#555555"
            radius: 4
            
            Column {
                anchors.centerIn: parent
                spacing: 2
                
                Text {
                    text: "Live"
                    color: "#cccccc"
                    font.pixelSize: 8
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Text {
                    text: getLiveDataPreview()
                    color: isConnected ? "#4CAF50" : "#888888"
                    font.family: "monospace"
                    font.pixelSize: 7
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
    
    function getLiveDataPreview() {
        if (!isConnected) return "No Data"
        
        switch(protocolName) {
            case "LIN Bus": return "Win: 25%\\nMir: +5°"
            case "FlexRay": return "ABS: OK\\nESC: OK"
            case "OBD-II": return "P0000\\nReady"
            default: return "Active"
        }
    }
    
    function toggleConnection() {
        isConnected = !isConnected
        console.log(protocolName, "connection:", isConnected)
    }
}