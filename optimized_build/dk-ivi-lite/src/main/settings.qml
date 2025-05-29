import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: settings_page
    width: Screen.width
    height: Screen.height
    color: "#0F0F0F"

    Component.onCompleted: {
        headerAnimation.start()
        menuAnimation.start()
        backgroundAnimation.start()
    }

    // Enhanced animated background system
    Item {
        id: backgroundAnimationSystem
        anchors.fill: parent
        z: -3
        
        // Professional gradient mesh background
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#0A0A0A" }
                GradientStop { position: 0.3; color: "#0F0F0F" }
                GradientStop { position: 0.7; color: "#0F0F0F" }
                GradientStop { position: 1.0; color: "#1A1A1A" }
            }
        }
        
        // Dynamic floating geometric elements with dramatic animations
        Repeater {
            model: 12
            
            Rectangle {
                id: geometricElement
                width: 8 + Math.random() * 20
                height: width
                radius: index % 3 === 0 ? 0 : width / 2  // Mix of circles and squares
                color: "#00D4AA"
                opacity: 0.1 + Math.random() * 0.2
                x: Math.random() * parent.width
                y: Math.random() * parent.height
                rotation: Math.random() * 360
                
                property real driftSpeed: 8 + Math.random() * 12
                
                // Dramatic orbital movement
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: geometricElement.x + 400 + Math.random() * 300
                        duration: geometricElement.driftSpeed * 1000
                        easing.type: Easing.InOutBack
                    }
                    NumberAnimation {
                        to: geometricElement.x - 400 - Math.random() * 300
                        duration: geometricElement.driftSpeed * 1000
                        easing.type: Easing.InOutBack
                    }
                }
                
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: geometricElement.y + 300 + Math.random() * 200
                        duration: (geometricElement.driftSpeed + 3) * 1000
                        easing.type: Easing.InOutBack
                    }
                    NumberAnimation {
                        to: geometricElement.y - 300 - Math.random() * 200
                        duration: (geometricElement.driftSpeed + 3) * 1000
                        easing.type: Easing.InOutBack
                    }
                }
                
                // Fast rotation animation
                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 3000 + Math.random() * 4000
                    easing.type: Easing.Linear
                }
                
                // Dramatic pulsing with scaling
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.4
                        duration: 1500 + Math.random() * 1000
                        easing.type: Easing.InOutElastic
                    }
                    NumberAnimation {
                        to: 0.05
                        duration: 1500 + Math.random() * 1000
                        easing.type: Easing.InOutElastic
                    }
                }
                
                // Scale pulsing effect
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 1.5
                        duration: 2000 + Math.random() * 1500
                        easing.type: Easing.InOutBounce
                    }
                    NumberAnimation {
                        to: 0.5
                        duration: 2000 + Math.random() * 1500
                        easing.type: Easing.InOutBounce
                    }
                }
            }
        }
        
        // Professional grid pattern overlay
        Canvas {
            id: gridPattern
            anchors.fill: parent
            opacity: 0.02
            
            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = "#00D4AA"
                ctx.lineWidth = 0.5
                
                var spacing = 80
                
                // Vertical lines
                for (var x = 0; x < width; x += spacing) {
                    ctx.beginPath()
                    ctx.moveTo(x, 0)
                    ctx.lineTo(x, height)
                    ctx.stroke()
                }
                
                // Horizontal lines
                for (var y = 0; y < height; y += spacing) {
                    ctx.beginPath()
                    ctx.moveTo(0, y)
                    ctx.lineTo(width, y)
                    ctx.stroke()
                }
            }
            
            // Dynamic grid animation with scaling
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.15; duration: 2000; easing.type: Easing.InOutElastic }
                NumberAnimation { to: 0.02; duration: 2000; easing.type: Easing.InOutElastic }
            }
            
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { to: 1.05; duration: 3000; easing.type: Easing.InOutBounce }
                NumberAnimation { to: 0.95; duration: 3000; easing.type: Easing.InOutBounce }
            }
        }
    }

    // Enhanced corner particle animation
    Item {
        id: cornerParticles
        anchors.top: parent.top
        anchors.right: parent.right
        width: parent.width * 0.3
        height: parent.height * 0.4
        opacity: 0.2
        z: -2

        // Dramatic floating particles
        Repeater {
            model: 25
            Rectangle {
                id: particle
                width: Math.random() * 8 + 3
                height: width
                radius: width / 2
                color: "#00D4AA"
                opacity: Math.random() * 0.3 + 0.1
                x: Math.random() * parent.width
                y: Math.random() * parent.height

                // Dramatic floating movement
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: particle.y - 150 - Math.random() * 200
                        duration: 2000 + Math.random() * 2000
                        easing.type: Easing.InOutElastic
                    }
                    NumberAnimation {
                        to: particle.y + 150 + Math.random() * 200
                        duration: 2000 + Math.random() * 2000
                        easing.type: Easing.InOutElastic
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: particle.x - 100 - Math.random() * 150
                        duration: 2500 + Math.random() * 2500
                        easing.type: Easing.InOutElastic
                    }
                    NumberAnimation {
                        to: particle.x + 100 + Math.random() * 150
                        duration: 2500 + Math.random() * 2500
                        easing.type: Easing.InOutElastic
                    }
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.6
                        duration: 1500 + Math.random() * 1000
                        easing.type: Easing.InOutBounce
                    }
                    NumberAnimation {
                        to: 0.1
                        duration: 1500 + Math.random() * 1000
                        easing.type: Easing.InOutBounce
                    }
                }
                
                // Scale pulsing
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 2.0
                        duration: 1800 + Math.random() * 1200
                        easing.type: Easing.InOutBack
                    }
                    NumberAnimation {
                        to: 0.3
                        duration: 1800 + Math.random() * 1200
                        easing.type: Easing.InOutBack
                    }
                }
            }
        }

        NumberAnimation {
            id: backgroundAnimation
            target: cornerParticles
            property: "opacity"
            from: 0
            to: 0.6
            duration: 1500
            easing.type: Easing.OutElastic
        }
    }

    // Enhanced header area with premium styling
    Rectangle {
        id: headerBackground
        x: 0
        y: 0
        width: parent.width
        height: 100
        z: 1
        
        // Modern gradient background
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#1A1A1A" }
            GradientStop { position: 0.3; color: "#0F0F0F" }
            GradientStop { position: 0.7; color: "#0F0F0F" }
            GradientStop { position: 1.0; color: "#1A1A1A" }
        }
        
        // Animated accent line
        Rectangle {
            id: headerAccentLine
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            width: 0
            height: 3
            color: "#00D4AA"
            radius: 1.5
            x: 32
            
            NumberAnimation {
                id: headerAccentAnimation
                target: headerAccentLine
                property: "width"
                from: 0
                to: 200
                duration: 1500
                easing.type: Easing.OutCubic
            }
        }
        
        // Animated bottom border
        Rectangle {
            id: headerBorder
            anchors.bottom: parent.bottom
            width: 0
            height: 1
            color: "#2A2A2A"
            
            NumberAnimation {
                id: headerBorderAnimation
                target: headerBorder
                property: "width"
                from: 0
                to: settings_page.width
                duration: 1200
                easing.type: Easing.OutCubic
            }
        }
    }

    // Premium dreamKIT text with enhanced styling
    Item {
        id: dreamKitContainer
        x: 32
        y: 20
        width: 300
        height: 60
        z: 2

        // Animated background glow
        Rectangle {
            id: textGlow
            anchors.centerIn: parent
            width: parent.width + 40
            height: parent.height + 20
            radius: 15
            color: "#00D4AA"
            opacity: 0
            scale: 1.2
            
            SequentialAnimation on opacity {
                id: glowAnimation
                loops: Animation.Infinite
                NumberAnimation { to: 0.12; duration: 3500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.06; duration: 3500; easing.type: Easing.InOutSine }
            }
        }

        // Premium "dreamKIT" text
        Text {
            id: settings_page_header_text
            text: "dreamKIT v1.0"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            font.bold: true
            font.pixelSize: 36
            font.weight: Font.Bold
            color: "#00D4AA"
            font.family: "Segoe UI"
            font.letterSpacing: 2
            opacity: 0

            // Animated text shadow effect using multiple text layers
            Text {
                anchors.fill: parent
                text: parent.text
                font: parent.font
                color: "#004D3D"
                opacity: 0.3
                x: 2
                y: 2
                z: -1
            }

            Text {
                anchors.fill: parent
                text: parent.text
                font: parent.font
                color: "#00D4AA"
                opacity: 0.2
                scale: 1.02
                z: -2
            }

            // Header slide-in animation
            NumberAnimation {
                id: headerAnimation
                target: settings_page_header_text
                property: "opacity"
                from: 0
                to: 1
                duration: 1000
                easing.type: Easing.OutCubic
                
                onFinished: {
                    headerBorderAnimation.start()
                    headerAccentAnimation.start()
                    glowPulse.start()
                    breathingOpacity.start()
                    glowAnimation.start()
                    letterAnimation.start()
                }
            }

            // Professional breathing effect - scale animation
            SequentialAnimation {
                id: glowPulse
                loops: Animation.Infinite
                NumberAnimation {
                    target: settings_page_header_text
                    property: "scale"
                    from: 1.0
                    to: 1.03
                    duration: 2500
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: settings_page_header_text
                    property: "scale"
                    from: 1.03
                    to: 1.0
                    duration: 2500
                    easing.type: Easing.InOutSine
                }
            }

            // Professional breathing effect - opacity animation
            SequentialAnimation {
                id: breathingOpacity
                loops: Animation.Infinite
                NumberAnimation {
                    target: settings_page_header_text
                    property: "opacity"
                    from: 1.0
                    to: 0.85
                    duration: 2500
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: settings_page_header_text
                    property: "opacity"
                    from: 0.85
                    to: 1.0
                    duration: 2500
                    easing.type: Easing.InOutSine
                }
            }

            // Subtle letter spacing breathing
            SequentialAnimation {
                id: letterAnimation
                loops: Animation.Infinite
                NumberAnimation {
                    target: settings_page_header_text
                    property: "font.letterSpacing"
                    from: 2
                    to: 2.8
                    duration: 2500
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: settings_page_header_text
                    property: "font.letterSpacing"
                    from: 2.8
                    to: 2
                    duration: 2500
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    ColumnLayout {
        spacing: 0
        y: 100
        width: parent.width
        height: parent.height - 100

        RowLayout {
            id: mainLayout
            Layout.fillWidth: true
            height: Screen.height - 100
            spacing: 0

            Rectangle {
                id: menuPanel
                Layout.preferredWidth: settings_page.width * 0.2
                Layout.fillHeight: true
                color: "#1A1A1A"
                
                // Right border
                Rectangle {
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: "#2A2A2A"
                }

                // Menu slide-in animation
                x: -width
                NumberAnimation {
                    id: menuAnimation
                    target: menuPanel
                    property: "x"
                    from: -menuPanel.width
                    to: 0
                    duration: 600
                    easing.type: Easing.OutCubic
                }

                ListView {
                    id: settingsList
                    anchors.fill: parent
                    anchors.margins: 8
                    model: settingsModel
                    spacing: 6
                    
                    delegate: Item {
                        id: menuItem
                        width: settingsList.width
                        height: 64
                        
                        // Staggered entrance animation
                        opacity: 0
                        
                        Component.onCompleted: {
                            // Delay based on index for staggered effect
                            var delay = index * 100
                            itemEntranceTimer.interval = delay
                            itemEntranceTimer.start()
                        }

                        Timer {
                            id: itemEntranceTimer
                            interval: 0
                            onTriggered: {
                                itemEntranceAnimation.start()
                            }
                        }

                        NumberAnimation {
                            id: itemEntranceAnimation
                            target: menuItem
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 400
                            easing.type: Easing.OutCubic
                        }

                        Rectangle {
                            id: backgroundRect
                            anchors.fill: parent
                            radius: 12
                            color: settingsList.currentIndex === index ? "#00D4AA15" : "transparent"
                            border.color: settingsList.currentIndex === index ? "#00D4AA40" : "transparent"
                            border.width: 1

                            // Smooth color transitions
                            Behavior on color {
                                ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
                            }
                            
                            Behavior on border.color {
                                ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 16
                                spacing: 16

                                // Enhanced professional icon
                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 8
                                    color: settingsList.currentIndex === index ? "#00D4AA15" : "#2A2A2A"
                                    border.color: settingsList.currentIndex === index ? "#00D4AA" : "#404040"
                                    border.width: 1
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: 300 }
                                    }
                                    
                                    Behavior on border.color {
                                        ColorAnimation { duration: 300 }
                                    }
                                    
                                    // Professional SVG-style icons using Text
                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            switch(index) {
                                                case 0: return "●"  // Market Place - solid circle
                                                case 1: return "◐"  // Control - half circle
                                                case 2: return "◆"  // App Test Deployment - diamond
                                                case 3: return "▲"  // Vehicle App - triangle
                                                case 4: return "■"  // Vehicle Service - square
                                                default: return "●"
                                            }
                                        }
                                        font.pixelSize: 18
                                        font.family: "Arial"
                                        color: settingsList.currentIndex === index ? "#00D4AA" : "#B0B0B0"
                                        
                                        Behavior on color {
                                            ColorAnimation { duration: 300 }
                                        }
                                    }
                                    
                                    // Dynamic pulse animation when selected
                                    SequentialAnimation on scale {
                                        running: settingsList.currentIndex === index
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 1.3; duration: 500; easing.type: Easing.InOutElastic }
                                        NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutElastic }
                                    }
                                    
                                    // Rotation animation when active
                                    RotationAnimation on rotation {
                                        running: settingsList.currentIndex === index
                                        loops: Animation.Infinite
                                        from: 0
                                        to: 360
                                        duration: 3000
                                        easing.type: Easing.Linear
                                    }
                                }

                                // Enhanced text styling
                                Text {
                                    id: itemText
                                    text: title
                                    font.pixelSize: 16
                                    font.family: "Segoe UI"
                                    font.weight: settingsList.currentIndex === index ? Font.DemiBold : Font.Medium
                                    color: settingsList.currentIndex === index ? "#FFFFFF" : "#C0C0C0"
                                    verticalAlignment: Text.AlignVCenter
                                    Layout.fillWidth: true
                                    
                                    // Letter spacing for premium feel
                                    font.letterSpacing: settingsList.currentIndex === index ? 0.5 : 0
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: 300 }
                                    }
                                    
                                    Behavior on font.letterSpacing {
                                        NumberAnimation { duration: 300 }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onEntered: {
                                if (settingsList.currentIndex !== index) {
                                    backgroundRect.color = "#00D4AA25"
                                    backgroundRect.scale = 1.05
                                    // Add bounce effect on hover
                                    hoverBounce.start()
                                }
                            }
                            
                            onExited: {
                                if (settingsList.currentIndex !== index) {
                                    backgroundRect.color = "transparent"
                                    backgroundRect.scale = 1.0
                                }
                            }
                            
                            onClicked: {
                                if (settingsList.currentIndex !== index) {
                                    settingsList.currentIndex = index
                                    stackLayout.currentIndex = index
                                    
                                    // Page transition animation
                                    contentTransition.start()
                                }
                            }
                        }
                        
                        // Dramatic hover bounce animation
                        SequentialAnimation {
                            id: hoverBounce
                            NumberAnimation {
                                target: menuItem
                                property: "scale"
                                to: 1.1
                                duration: 150
                                easing.type: Easing.OutBack
                            }
                            NumberAnimation {
                                target: menuItem
                                property: "scale"
                                to: 1.0
                                duration: 150
                                easing.type: Easing.InBack
                            }
                        }
                        
                        // Enhanced scale animation
                        Behavior on scale {
                            NumberAnimation { duration: 300; easing.type: Easing.OutElastic }
                        }
                    }
                    
                    highlight: Rectangle { color: "transparent" }
                }
            }

            Rectangle {
                id: contentPanel
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#0F0F0F"
                
                // Content fade animation
                opacity: 1
                
                NumberAnimation {
                    id: contentTransition
                    target: contentPanel
                    property: "opacity"
                    from: 0.7
                    to: 1.0
                    duration: 300
                    easing.type: Easing.OutCubic
                }

                StackLayout {
                    id: stackLayout
                    anchors.fill: parent
                    currentIndex: settingsList.currentIndex

                    Loader { source: "../marketplace/marketplace.qml" }
                    Loader { source: "../controls/controls.qml" }
                    Loader { source: "../digitalauto/digitalauto.qml" }
                    Loader { source: "../installedvapps/installedvapps.qml" }
                    Loader { source: "../installedservices/installedservices.qml" }
                }
            }
        }
    }

    ListModel {
        id: settingsModel
        ListElement { title: "Market Place" }
        ListElement { title: "Control" }
        ListElement { title: "App Test Deployment" }
        ListElement { title: "Vehicle App" }
        ListElement { title: "Vehicle Service" }
    }
}