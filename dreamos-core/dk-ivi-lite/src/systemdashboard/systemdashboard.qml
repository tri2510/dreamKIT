import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import SystemDashboard 1.0

Rectangle {
    id: systemDashboard
    width: parent.width
    height: parent.height
    color: "#0F0F0F"

    SystemDashboardBackend {
        id: dashboardBackend
        onServiceStatusChanged: servicesList.model = services
        onSystemStatsChanged: updateSystemStats()
        onConsoleOutputChanged: consoleOutput.text += output + "\n"
    }

    Component.onCompleted: {
        dashboardBackend.startMonitoring()
    }

    Component.onDestruction: {
        dashboardBackend.stopMonitoring()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 80
            color: "#1A1A1A"
            radius: 12
            border.color: "#2A2A2A"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                Rectangle {
                    width: 48
                    height: 48
                    radius: 8
                    color: "#00D4AA15"
                    border.color: "#00D4AA"
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "⚙"
                        font.pixelSize: 24
                        color: "#00D4AA"
                    }
                }

                Text {
                    text: "System Dashboard"
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 120
                    height: 40
                    radius: 6
                    color: dashboardBackend.systemHealthy ? "#00D4AA20" : "#FF453A20"
                    border.color: dashboardBackend.systemHealthy ? "#00D4AA" : "#FF453A"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: dashboardBackend.systemHealthy ? "● HEALTHY" : "● CRITICAL"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: dashboardBackend.systemHealthy ? "#00D4AA" : "#FF453A"
                    }
                }
            }
        }

        // Main content
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            // Left panel - System Status
            Rectangle {
                Layout.preferredWidth: parent.width * 0.6
                Layout.fillHeight: true
                color: "#1A1A1A"
                radius: 12
                border.color: "#2A2A2A"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    // System Stats Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 15

                        // CPU Usage
                        Rectangle {
                            Layout.fillWidth: true
                            height: 100
                            color: "#0F0F0F"
                            radius: 8
                            border.color: "#2A2A2A"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 8

                                Text {
                                    text: "CPU Usage"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: "#C0C0C0"
                                }

                                Text {
                                    id: cpuUsageText
                                    text: "0%"
                                    font.pixelSize: 24
                                    font.weight: Font.Bold
                                    color: "#00D4AA"
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    color: "#2A2A2A"
                                    radius: 3

                                    Rectangle {
                                        id: cpuProgressBar
                                        width: parent.width * (dashboardBackend.cpuUsage / 100)
                                        height: parent.height
                                        color: "#00D4AA"
                                        radius: 3

                                        Behavior on width {
                                            NumberAnimation { duration: 300 }
                                        }
                                    }
                                }
                            }
                        }

                        // Memory Usage
                        Rectangle {
                            Layout.fillWidth: true
                            height: 100
                            color: "#0F0F0F"
                            radius: 8
                            border.color: "#2A2A2A"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 8

                                Text {
                                    text: "Memory"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: "#C0C0C0"
                                }

                                Text {
                                    id: memoryUsageText
                                    text: "0 GB"
                                    font.pixelSize: 24
                                    font.weight: Font.Bold
                                    color: "#00D4AA"
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    color: "#2A2A2A"
                                    radius: 3

                                    Rectangle {
                                        id: memoryProgressBar
                                        width: parent.width * (dashboardBackend.memoryUsage / 100)
                                        height: parent.height
                                        color: "#00D4AA"
                                        radius: 3

                                        Behavior on width {
                                            NumberAnimation { duration: 300 }
                                        }
                                    }
                                }
                            }
                        }

                        // Disk Usage
                        Rectangle {
                            Layout.fillWidth: true
                            height: 100
                            color: "#0F0F0F"
                            radius: 8
                            border.color: "#2A2A2A"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 8

                                Text {
                                    text: "Disk Usage"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: "#C0C0C0"
                                }

                                Text {
                                    id: diskUsageText
                                    text: "0 GB"
                                    font.pixelSize: 24
                                    font.weight: Font.Bold
                                    color: "#00D4AA"
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    color: "#2A2A2A"
                                    radius: 3

                                    Rectangle {
                                        id: diskProgressBar
                                        width: parent.width * (dashboardBackend.diskUsage / 100)
                                        height: parent.height
                                        color: "#00D4AA"
                                        radius: 3

                                        Behavior on width {
                                            NumberAnimation { duration: 300 }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Services List
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#0F0F0F"
                        radius: 8
                        border.color: "#2A2A2A"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "SDV Services Status"
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: "#FFFFFF"
                                    Layout.fillWidth: true
                                }

                                Button {
                                    text: "Refresh"
                                    font.pixelSize: 12
                                    implicitHeight: 32
                                    implicitWidth: 80

                                    background: Rectangle {
                                        color: parent.pressed ? "#00D4AA40" : "#00D4AA20"
                                        border.color: "#00D4AA"
                                        border.width: 1
                                        radius: 6
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "#00D4AA"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: dashboardBackend.refreshServices()
                                }
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                ListView {
                                    id: servicesList
                                    spacing: 8
                                    model: dashboardBackend.services

                                    delegate: Rectangle {
                                        width: servicesList.width
                                        height: 60
                                        color: "#1A1A1A"
                                        radius: 8
                                        border.color: "#2A2A2A"
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 15
                                            spacing: 15

                                            Rectangle {
                                                width: 12
                                                height: 12
                                                radius: 6
                                                color: modelData.status === "running" ? "#00D4AA" : 
                                                       modelData.status === "stopped" ? "#FF453A" : "#FFD60A"

                                                SequentialAnimation on opacity {
                                                    running: modelData.status === "running"
                                                    loops: Animation.Infinite
                                                    NumberAnimation { to: 0.3; duration: 1000 }
                                                    NumberAnimation { to: 1.0; duration: 1000 }
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                Text {
                                                    text: modelData.name
                                                    font.pixelSize: 14
                                                    font.weight: Font.Medium
                                                    color: "#FFFFFF"
                                                }

                                                Text {
                                                    text: modelData.description
                                                    font.pixelSize: 12
                                                    color: "#C0C0C0"
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            Text {
                                                text: modelData.status.toUpperCase()
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                                color: modelData.status === "running" ? "#00D4AA" :
                                                       modelData.status === "stopped" ? "#FF453A" : "#FFD60A"
                                            }

                                            Button {
                                                text: modelData.status === "running" ? "Stop" : "Start"
                                                font.pixelSize: 10
                                                implicitHeight: 28
                                                implicitWidth: 60

                                                background: Rectangle {
                                                    color: parent.pressed ? "#2A2A2A" : "#1A1A1A"
                                                    border.color: "#404040"
                                                    border.width: 1
                                                    radius: 4
                                                }

                                                contentItem: Text {
                                                    text: parent.text
                                                    font: parent.font
                                                    color: "#C0C0C0"
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                onClicked: {
                                                    if (modelData.status === "running") {
                                                        dashboardBackend.stopService(modelData.name)
                                                    } else {
                                                        dashboardBackend.startService(modelData.name)
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
            }

            // Right panel - Console
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#1A1A1A"
                radius: 12
                border.color: "#2A2A2A"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    Text {
                        text: "System Console"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        TextArea {
                            id: consoleOutput
                            readOnly: true
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            font.family: "Consolas, Monaco, monospace"
                            font.pixelSize: 12
                            color: "#00D4AA"
                            background: Rectangle {
                                color: "#0F0F0F"
                                radius: 8
                                border.color: "#2A2A2A"
                                border.width: 1
                            }
                            text: "System Dashboard initialized...\n"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        TextField {
                            id: consoleInput
                            Layout.fillWidth: true
                            placeholderText: "Enter command..."
                            font.family: "Consolas, Monaco, monospace"
                            font.pixelSize: 12
                            color: "#FFFFFF"

                            background: Rectangle {
                                color: "#0F0F0F"
                                radius: 6
                                border.color: "#404040"
                                border.width: 1
                            }

                            onAccepted: {
                                if (text.trim() !== "") {
                                    dashboardBackend.executeCommand(text)
                                    text = ""
                                }
                            }
                        }

                        Button {
                            text: "Execute"
                            implicitHeight: 36
                            implicitWidth: 80

                            background: Rectangle {
                                color: parent.pressed ? "#00D4AA40" : "#00D4AA20"
                                border.color: "#00D4AA"
                                border.width: 1
                                radius: 6
                            }

                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: "#00D4AA"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                if (consoleInput.text.trim() !== "") {
                                    dashboardBackend.executeCommand(consoleInput.text)
                                    consoleInput.text = ""
                                }
                            }
                        }

                        Button {
                            text: "Clear"
                            implicitHeight: 36
                            implicitWidth: 60

                            background: Rectangle {
                                color: parent.pressed ? "#2A2A2A" : "#1A1A1A"
                                border.color: "#404040"
                                border.width: 1
                                radius: 6
                            }

                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: "#C0C0C0"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                consoleOutput.text = "Console cleared.\n"
                            }
                        }
                    }
                }
            }
        }
    }

    function updateSystemStats() {
        cpuUsageText.text = dashboardBackend.cpuUsage.toFixed(1) + "%"
        memoryUsageText.text = (dashboardBackend.memoryUsedGB).toFixed(1) + " GB"
        diskUsageText.text = (dashboardBackend.diskUsedGB).toFixed(1) + " GB"
    }
}