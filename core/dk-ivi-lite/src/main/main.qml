import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: mainWindow
    visible: true
    width: Screen.width
    height: Screen.height
    visibility: "FullScreen"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "#0F0F0F"

    // Smooth fade-in animation when app starts
    opacity: 0
    
    Component.onCompleted: {
        fadeInAnimation.start()
    }

    NumberAnimation {
        id: fadeInAnimation
        target: mainWindow
        property: "opacity"
        from: 0
        to: 1
        duration: 800
        easing.type: Easing.OutCubic
    }

    // Background gradient for depth
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0F0F0F" }
            GradientStop { position: 1.0; color: "#1A1A1A" }
        }
    }

    // Subtle animated background pattern
    Item {
        id: backgroundPattern
        anchors.fill: parent
        opacity: 0.03

        Repeater {
            model: 20
            Rectangle {
                width: 2
                height: parent.height
                color: "#00D4AA"
                x: index * (parent.width / 20)
                opacity: 0.1
                
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { 
                        to: 0.3
                        duration: 2000 + (index * 100)
                    }
                    NumberAnimation { 
                        to: 0.1
                        duration: 2000 + (index * 100)
                    }
                }
            }
        }
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        interactive: false // Disable swiping to prevent accidental navigation

        // Smooth page transitions
        Behavior on currentIndex {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        Loader {
            id: settingsLoader
            source: "settings.qml"
            
            // Loading animation
            Rectangle {
                anchors.centerIn: parent
                width: 100
                height: 100
                radius: 50
                color: "#00D4AA20"
                border.color: "#00D4AA"
                border.width: 2
                visible: settingsLoader.status === Loader.Loading

                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 2000
                }

                Text {
                    anchors.centerIn: parent
                    text: "dreamKIT"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: "#00D4AA"
                }
            }
        }
    }

    // Subtle corner accent
    Rectangle {
        width: 100
        height: 100
        color: "transparent"
        anchors.top: parent.top
        anchors.right: parent.right

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "#00D4AA"
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.moveTo(width - 50, 0)
                ctx.lineTo(width, 0)
                ctx.lineTo(width, 50)
                ctx.stroke()
            }
        }
    }

    Rectangle {
        width: 100
        height: 100
        color: "transparent"
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "#00D4AA"
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.moveTo(0, height - 50)
                ctx.lineTo(0, height)
                ctx.lineTo(50, height)
                ctx.stroke()
            }
        }
    }
}