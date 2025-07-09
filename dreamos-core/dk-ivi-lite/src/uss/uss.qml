import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import UssAsync 1.0

Rectangle {
    id: ussPage
    anchors.fill: parent
    color: "#0F0F0F"  // Deep dark background matching controls
    
    property int buttonSpacing: 16
    property bool guiTestMode: false
    property var sensorDistances: [10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]
    property int testCycleStep: 0
    
    // GUI Test Animation Timer
    Timer {
        id: guiTestTimer
        interval: 1500
        running: guiTestMode
        repeat: true
        onTriggered: {
            if (guiTestMode) {
                // Cycle through different test patterns to show all zone colors
                testCycleStep = (testCycleStep + 1) % 8
                
                switch(testCycleStep) {
                    case 0: // Critical zone demo
                        sensorDistances = [0.2, 0.25, 0.15, 0.3, 0.28, 0.22, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]
                        closestObstacleText.text = "CRITICAL ZONE - Emergency Stop!"
                        break
                    case 1: // Warning zone demo
                        sensorDistances = [0.6, 0.7, 0.5, 0.8, 0.65, 0.75, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]
                        closestObstacleText.text = "WARNING ZONE - Slow Down"
                        break
                    case 2: // Caution zone demo
                        sensorDistances = [1.2, 1.4, 1.0, 1.5, 1.3, 1.1, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]
                        closestObstacleText.text = "CAUTION ZONE - Be Careful"
                        break
                    case 3: // Advisory zone demo
                        sensorDistances = [2.0, 2.3, 1.8, 2.5, 2.2, 2.1, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]
                        closestObstacleText.text = "ADVISORY ZONE - Object Detected"
                        break
                    case 4: // Rear sensors demo
                        sensorDistances = [10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 1.8, 0.9, 0.4, 0.6, 1.2, 2.1]
                        closestObstacleText.text = "REAR SENSORS - Parking Assist"
                        break
                    case 5: // Monitoring zone demo
                        sensorDistances = [3.5, 4.2, 3.8, 4.0, 3.9, 4.5, 3.2, 4.8, 3.6, 4.1, 3.7, 4.3]
                        closestObstacleText.text = "MONITORING ZONE - Far Objects"
                        break
                    case 6: // Mixed pattern demo
                        sensorDistances = [2.1, 1.5, 0.8, 0.5, 1.2, 2.8, 3.5, 1.8, 0.6, 0.9, 2.0, 4.2]
                        closestObstacleText.text = "MIXED PATTERN - Complex Environment"
                        break
                    case 7: // Max range demo
                        sensorDistances = [8.5, 9.2, 7.8, 6.5, 8.1, 9.8, 7.2, 8.8, 6.6, 7.9, 8.7, 9.3]
                        closestObstacleText.text = "MAX RANGE - Clear Path Ahead"
                        break
                }
            }
        }
    }
    
    UssAsync {
        id: ussAsync
        
        onUpdateSensor_front_left: (distance) => { 
            console.log("USS: Received front_left signal:", distance, "guiTestMode:", guiTestMode)
            if (!guiTestMode) {
                var newDistances = sensorDistances.slice()
                newDistances[0] = distance
                sensorDistances = newDistances
            }
        }
        onUpdateSensor_front_cornerLeft: (distance) => { 
            console.log("USS: Received front_cornerLeft signal:", distance, "guiTestMode:", guiTestMode)
            if (!guiTestMode) {
                var newDistances = sensorDistances.slice()
                newDistances[1] = distance
                sensorDistances = newDistances
            }
        }
        onUpdateSensor_front_center: (distance) => { 
            console.log("USS: Received front_center signal:", distance, "guiTestMode:", guiTestMode)
            if (!guiTestMode) {
                var newDistances = sensorDistances.slice()
                newDistances[2] = distance
                sensorDistances = newDistances
            }
        }
        onUpdateSensor_front_centerRight: (distance) => { 
            console.log("USS: Received front_centerRight signal:", distance, "guiTestMode:", guiTestMode)
            if (!guiTestMode) {
                var newDistances = sensorDistances.slice()
                newDistances[3] = distance
                sensorDistances = newDistances
            }
        }
        onUpdateSensor_front_cornerRight: (distance) => { 
            console.log("USS: Received front_cornerRight signal:", distance, "guiTestMode:", guiTestMode)
            if (!guiTestMode) {
                var newDistances = sensorDistances.slice()
                newDistances[4] = distance
                sensorDistances = newDistances
            }
        }
        onUpdateSensor_front_right: (distance) => { 
            console.log("USS: Received front_right signal:", distance, "guiTestMode:", guiTestMode)
            if (!guiTestMode) {
                var newDistances = sensorDistances.slice()
                newDistances[5] = distance
                sensorDistances = newDistances
            }
        }
        onUpdateSensor_rear_right: (distance) => { 
            console.log("USS: Received rear_right signal:", distance, "guiTestMode:", guiTestMode)
            if (!guiTestMode) {
                var newDistances = sensorDistances.slice()
                newDistances[6] = distance
                sensorDistances = newDistances
            }
        }
        onUpdateSensor_rear_cornerRight: (distance) => { 
            console.log("USS: Received rear_cornerRight signal:", distance, "guiTestMode:", guiTestMode)
            if (!guiTestMode) {
                var newDistances = sensorDistances.slice()
                newDistances[7] = distance
                sensorDistances = newDistances
            }
        }
        onUpdateSensor_rear_centerRight: (distance) => { 
            console.log("USS: Received rear_centerRight signal:", distance, "guiTestMode:", guiTestMode)
            if (!guiTestMode) {
                var newDistances = sensorDistances.slice()
                newDistances[8] = distance
                sensorDistances = newDistances
            }
        }
        onUpdateSensor_rear_center: (distance) => { 
            console.log("USS: Received rear_center signal:", distance, "guiTestMode:", guiTestMode)
            if (!guiTestMode) {
                var newDistances = sensorDistances.slice()
                newDistances[9] = distance
                sensorDistances = newDistances
            }
        }
        onUpdateSensor_rear_cornerLeft: (distance) => { 
            console.log("USS: Received rear_cornerLeft signal:", distance, "guiTestMode:", guiTestMode)
            if (!guiTestMode) {
                var newDistances = sensorDistances.slice()
                newDistances[10] = distance
                sensorDistances = newDistances
            }
        }
        onUpdateSensor_rear_left: (distance) => { 
            console.log("USS: Received rear_left signal:", distance, "guiTestMode:", guiTestMode)
            if (!guiTestMode) {
                var newDistances = sensorDistances.slice()
                newDistances[11] = distance
                sensorDistances = newDistances
            }
        }
        
        onUpdateClosestObstacle: (location, distance) => {
            if (!guiTestMode) {
                closestObstacleText.text = location + ": " + distance.toFixed(2) + "m"
            }
        }
    }
    
    Component.onCompleted: {
        ussAsync.init()
    }
    
    function getZoneColor(distance) {
        if (distance <= 0.3) return "#8B0000"      // Dark Red - Critical
        else if (distance <= 0.8) return "#FF0000" // Red - Warning
        else if (distance <= 1.5) return "#FFA500" // Orange - Caution
        else if (distance <= 2.5) return "#FFFF00" // Yellow - Advisory
        else if (distance <= 5.0) return "#90EE90" // Light Green - Monitoring
        else if (distance <= 10.0) return "#ADD8E6" // Light Blue - Max Range
        else return "#404040" // Dark Gray - No signal
    }
    
    function getZoneOpacity(distance) {
        if (distance <= 0.3) return 1.0
        else if (distance <= 0.8) return 0.85
        else if (distance <= 1.5) return 0.70
        else if (distance <= 2.5) return 0.55
        else if (distance <= 5.0) return 0.40
        else if (distance <= 10.0) return 0.25
        else return 0.05 // Very light for no signal
    }
    
    function getBeamLength(distance) {
        if (distance >= 10.0) return 80 // Max beam length for no signal
        return Math.max(20, 80 * (1 - distance / 10.0))
    }
    
    function getSensorName(index) {
        var sensorNames = [
            "Front Left", "Front Corner L", "Front Center L", 
            "Front Center R", "Front Corner R", "Front Right",
            "Rear Right", "Rear Corner R", "Rear Center R", 
            "Rear Center L", "Rear Corner L", "Rear Left"
        ]
        return sensorNames[index] || "Unknown"
    }
    
    // Corner test controls (top-right)
    Column {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 15
        spacing: 8
        z: 10
        
        Button {
            width: 120
            height: 30
            text: guiTestMode ? "Live Mode" : "GUI Test"
            onClicked: {
                guiTestMode = !guiTestMode
                if (guiTestMode) {
                    // Start GUI test mode with cycling animation
                    testCycleStep = 0
                    guiTestTimer.start()
                    closestObstacleText.text = "GUI Test Mode - Starting Demo..."
                } else {
                    // Return to live data
                    guiTestTimer.stop()
                    testCycleStep = 0
                    sensorDistances = [10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]
                    closestObstacleText.text = "Live Mode - Real Sensor Data"
                }
            }
            
            background: Rectangle {
                color: parent.pressed ? (guiTestMode ? "#AA5500" : "#00A088") : (guiTestMode ? "#FF8800" : "#00D4AA")
                radius: 6
            }
            
            contentItem: Text {
                text: parent.text
                color: guiTestMode ? "#FFFFFF" : "#000000"
                font.pixelSize: 11
                font.family: "Segoe UI"
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
        
        Button {
            width: 120
            height: 30
            text: "Test Sensors"
            onClicked: ussAsync.qml_setAllTestDistances(2.5)
            enabled: !guiTestMode
            
            background: Rectangle {
                color: parent.enabled ? (parent.pressed ? "#0055AA" : "#0066CC") : "#444444"
                radius: 6
            }
            
            contentItem: Text {
                text: parent.text
                color: parent.enabled ? "#FFFFFF" : "#888888"
                font.pixelSize: 11
                font.family: "Segoe UI"
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
        
        Button {
            width: 120
            height: 30
            text: "Clear All"
            onClicked: ussAsync.qml_setAllTestDistances(10.0)
            enabled: !guiTestMode
            
            background: Rectangle {
                color: parent.enabled ? (parent.pressed ? "#666666" : "#888888") : "#444444"
                radius: 6
            }
            
            contentItem: Text {
                text: parent.text
                color: parent.enabled ? "#FFFFFF" : "#888888"
                font.pixelSize: 11
                font.family: "Segoe UI"
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
    
    // Main container
    Item {
        anchors.fill: parent
        anchors.margins: 24
        
        // Header
        Text {
            id: headerText
            text: "USS - Ultrasonic Sensor System"
            font.pixelSize: 28
            font.family: "Segoe UI"
            font.weight: Font.Bold
            color: "#00D4AA"
            anchors.horizontalCenter: parent.horizontalCenter
            y: 20
        }
        
        // Main visualization container
        Item {
            id: visualizationContainer
            width: Math.min(parent.width, 1000)
            height: 600
            y: 80
            anchors.horizontalCenter: parent.horizontalCenter
            
            // Car illustration with fan beams
            Item {
                id: carIllustration
                width: 600
                height: 600
                anchors.centerIn: parent
                
                // Sensor fan beams
                Repeater {
                    model: [
                        // Front sensors (S1-S6) - reduced fan widths and better spacing for less overlap
                        {id: 0, x: 245, y: 185, angle: -135, fanWidth: 35, name: "S1"},    // Front Side Left - reduced from 60° to 35°
                        {id: 1, x: 270, y: 170, angle: -112.5, fanWidth: 25, name: "S2"},  // Front Corner Left - reduced from 45° to 25°
                        {id: 2, x: 290, y: 165, angle: -97.5, fanWidth: 20, name: "S3"},   // Front Center Left - reduced from 30° to 20°
                        {id: 3, x: 310, y: 165, angle: -82.5, fanWidth: 20, name: "S4"},   // Front Center Right - reduced from 30° to 20°
                        {id: 4, x: 330, y: 170, angle: -67.5, fanWidth: 25, name: "S5"},   // Front Corner Right - reduced from 45° to 25°
                        {id: 5, x: 355, y: 185, angle: -45, fanWidth: 35, name: "S6"},     // Front Side Right - reduced from 60° to 35°
                        // Rear sensors (S7-S12) - reduced fan widths and better spacing for less overlap
                        {id: 6, x: 355, y: 415, angle: 45, fanWidth: 35, name: "S7"},      // Rear Side Right - reduced from 60° to 35°
                        {id: 7, x: 330, y: 430, angle: 67.5, fanWidth: 25, name: "S8"},    // Rear Corner Right - reduced from 45° to 25°
                        {id: 8, x: 310, y: 435, angle: 82.5, fanWidth: 20, name: "S9"},    // Rear Center Right - reduced from 30° to 20°
                        {id: 9, x: 290, y: 435, angle: 97.5, fanWidth: 20, name: "S10"},   // Rear Center Left - reduced from 30° to 20°
                        {id: 10, x: 270, y: 430, angle: 112.5, fanWidth: 25, name: "S11"}, // Rear Corner Left - reduced from 45° to 25°
                        {id: 11, x: 245, y: 415, angle: 135, fanWidth: 35, name: "S12"}    // Rear Side Left - reduced from 60° to 35°
                    ]
                    
                    Item {
                        id: sensorBeam
                        property real distance: sensorDistances[modelData.id]
                        property color beamColor: getZoneColor(distance)
                        property real beamOpacity: getZoneOpacity(distance)
                        property real beamLength: getBeamLength(distance)
                        
                        x: modelData.x
                        y: modelData.y
                        
                        // Fan beam visualization
                        Canvas {
                            id: beamCanvas
                            width: 400
                            height: 400
                            anchors.centerIn: parent
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                
                                // Convert angle to radians
                                var centerAngle = modelData.angle * Math.PI / 180
                                var fanWidthDegrees = modelData.fanWidth || 45 // Use specific fan width for each sensor
                                var fanWidth = fanWidthDegrees * Math.PI / 180
                                var maxBeamLength = 150 // Bigger beam length
                                var actualBeamLength = Math.max(40, maxBeamLength * (1 - distance / 10.0))
                                
                                // For no signal (distance >= 10), show very light beam at max length
                                if (distance >= 10.0) {
                                    actualBeamLength = maxBeamLength
                                }
                                
                                // Create fan beam gradient
                                var gradient = ctx.createRadialGradient(width/2, height/2, 0, width/2, height/2, actualBeamLength)
                                gradient.addColorStop(0, Qt.rgba(beamColor.r, beamColor.g, beamColor.b, beamOpacity * 0.9))
                                gradient.addColorStop(0.5, Qt.rgba(beamColor.r, beamColor.g, beamColor.b, beamOpacity * 0.6))
                                gradient.addColorStop(1, Qt.rgba(beamColor.r, beamColor.g, beamColor.b, beamOpacity * 0.1))
                                
                                ctx.fillStyle = gradient
                                ctx.strokeStyle = Qt.rgba(beamColor.r, beamColor.g, beamColor.b, Math.min(0.9, beamOpacity))
                                ctx.lineWidth = 2
                                
                                // Draw fan beam with proper angles
                                ctx.beginPath()
                                ctx.moveTo(width/2, height/2)
                                
                                // Calculate start and end angles
                                var startAngle = centerAngle - fanWidth/2
                                var endAngle = centerAngle + fanWidth/2
                                
                                // Draw the arc
                                ctx.arc(width/2, height/2, actualBeamLength, startAngle, endAngle)
                                ctx.lineTo(width/2, height/2)
                                ctx.closePath()
                                ctx.fill()
                                ctx.stroke()
                                
                                // Add beam center line for better visibility
                                ctx.beginPath()
                                ctx.moveTo(width/2, height/2)
                                ctx.lineTo(width/2 + actualBeamLength * Math.cos(centerAngle), 
                                          height/2 + actualBeamLength * Math.sin(centerAngle))
                                ctx.strokeStyle = Qt.rgba(beamColor.r, beamColor.g, beamColor.b, beamOpacity * 0.8)
                                ctx.lineWidth = 2
                                ctx.stroke()
                            }
                            
                            // Redraw when properties change
                            Connections {
                                target: sensorBeam
                                function onDistanceChanged() { beamCanvas.requestPaint() }
                            }
                            
                            Component.onCompleted: {
                                beamCanvas.requestPaint()
                            }
                        }
                        
                        // Sensor point indicator
                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: beamColor
                            border.color: "#FFFFFF"
                            border.width: 1
                            anchors.centerIn: parent
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                color: distance < 5.0 ? "#000000" : "#FFFFFF"
                                font.pixelSize: 8
                                font.bold: true
                            }
                            
                            // Distance display
                            Rectangle {
                                width: 45
                                height: 16
                                radius: 8
                                color: "#000000"
                                border.color: beamColor
                                border.width: 1
                                visible: distance < 10.0
                                y: -25
                                anchors.horizontalCenter: parent.horizontalCenter
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: distance.toFixed(1) + "m"
                                    color: "#FFFFFF"
                                    font.pixelSize: 9
                                    font.family: "Segoe UI"
                                }
                            }
                        }
                    }
                }
                
                // Drawn car shape - smaller size
                Item {
                    id: drawnCar
                    width: 120
                    height: 260
                    x: 240
                    y: 170
                    z: 5 // Above the beams
                    
                    // Main car body
                    Rectangle {
                        id: carBody
                        width: 80
                        height: 200
                        x: 20
                        y: 30
                        color: "#2A2A2A"
                        border.color: "#00D4AA"
                        border.width: 2
                        radius: 15
                    }
                    
                    // Car roof
                    Rectangle {
                        width: 65
                        height: 80
                        x: 27.5
                        y: 80
                        color: "#1A1A1A"
                        border.color: "#00D4AA"
                        border.width: 1
                        radius: 10
                    }
                    
                    // Front bumper
                    Rectangle {
                        width: 100
                        height: 15
                        x: 10
                        y: 15
                        color: "#333333"
                        border.color: "#00D4AA"
                        border.width: 2
                        radius: 8
                    }
                    
                    // Rear bumper
                    Rectangle {
                        width: 100
                        height: 15
                        x: 10
                        y: 230
                        color: "#333333"
                        border.color: "#00D4AA"
                        border.width: 2
                        radius: 8
                    }
                    
                    // Front windshield
                    Rectangle {
                        width: 50
                        height: 25
                        x: 35
                        y: 50
                        color: "#4A4A4A"
                        border.color: "#00D4AA"
                        border.width: 1
                        radius: 5
                    }
                    
                    // Rear windshield
                    Rectangle {
                        width: 50
                        height: 25
                        x: 35
                        y: 185
                        color: "#4A4A4A"
                        border.color: "#00D4AA"
                        border.width: 1
                        radius: 5
                    }
                    
                    // Side mirrors
                    Rectangle {
                        width: 6
                        height: 8
                        x: 12
                        y: 70
                        color: "#333333"
                        border.color: "#00D4AA"
                        border.width: 1
                        radius: 3
                    }
                    
                    Rectangle {
                        width: 6
                        height: 8
                        x: 102
                        y: 70
                        color: "#333333"
                        border.color: "#00D4AA"
                        border.width: 1
                        radius: 3
                    }
                    
                    // Wheels
                    Rectangle {
                        width: 16
                        height: 16
                        x: 8
                        y: 50
                        color: "#1A1A1A"
                        border.color: "#666666"
                        border.width: 2
                        radius: 8
                    }
                    
                    Rectangle {
                        width: 16
                        height: 16
                        x: 96
                        y: 50
                        color: "#1A1A1A"
                        border.color: "#666666"
                        border.width: 2
                        radius: 8
                    }
                    
                    Rectangle {
                        width: 16
                        height: 16
                        x: 8
                        y: 194
                        color: "#1A1A1A"
                        border.color: "#666666"
                        border.width: 2
                        radius: 8
                    }
                    
                    Rectangle {
                        width: 16
                        height: 16
                        x: 96
                        y: 194
                        color: "#1A1A1A"
                        border.color: "#666666"
                        border.width: 2
                        radius: 8
                    }
                    
                    // Front headlights
                    Rectangle {
                        width: 8
                        height: 6
                        x: 20
                        y: 38
                        color: "#FFFF88"
                        border.color: "#FFFFFF"
                        border.width: 1
                        radius: 3
                        opacity: 0.8
                    }
                    
                    Rectangle {
                        width: 8
                        height: 6
                        x: 92
                        y: 38
                        color: "#FFFF88"
                        border.color: "#FFFFFF"
                        border.width: 1
                        radius: 3
                        opacity: 0.8
                    }
                    
                    // Rear lights
                    Rectangle {
                        width: 8
                        height: 6
                        x: 20
                        y: 216
                        color: "#FF4444"
                        border.color: "#FFFFFF"
                        border.width: 1
                        radius: 3
                        opacity: 0.8
                    }
                    
                    Rectangle {
                        width: 8
                        height: 6
                        x: 92
                        y: 216
                        color: "#FF4444"
                        border.color: "#FFFFFF"
                        border.width: 1
                        radius: 3
                        opacity: 0.8
                    }
                    
                    // Center line indicator
                    Rectangle {
                        width: 1
                        height: 200
                        x: 59.5
                        y: 30
                        color: "#00D4AA"
                        opacity: 0.4
                    }
                    
                    // Front direction indicator
                    Text {
                        text: "FRONT"
                        x: 45
                        y: 5
                        color: "#00D4AA"
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "Segoe UI"
                    }
                    
                    // Rear direction indicator
                    Text {
                        text: "REAR"
                        x: 50
                        y: 245
                        color: "#FF4444"
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "Segoe UI"
                    }
                }
                
                // Status display
                Rectangle {
                    width: 300
                    height: 40
                    radius: 20
                    color: "#1A1A1A"
                    border.color: guiTestMode ? "#FF8800" : "#00D4AA"
                    border.width: 2
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Text {
                        id: closestObstacleText
                        anchors.centerIn: parent
                        text: guiTestMode ? "GUI Test Mode - Demo Pattern" : "System Ready"
                        color: guiTestMode ? "#FF8800" : "#00D4AA"
                        font.pixelSize: 16
                        font.family: "Segoe UI"
                        font.weight: Font.Medium
                    }
                }
            }
            
            // Left panel - Live Sensor Values
            Rectangle {
                id: leftPanel
                width: 220
                height: 500
                x: 0
                y: 50
                color: "#1A1A1A"
                radius: 16
                border.color: "#2A2A2A"
                border.width: 1
                
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 15
                    
                    Column {
                        width: parent.width - 30
                        spacing: 12
                        
                        Text {
                            text: "Live Sensor Values"
                            font.pixelSize: 18
                            font.family: "Segoe UI"
                            font.weight: Font.Medium
                            color: "#00D4AA"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#2A2A2A"
                        }
                        
                        // Front Sensors Section
                        Text {
                            text: "FRONT SENSORS"
                            font.pixelSize: 14
                            font.family: "Segoe UI"
                            font.weight: Font.Bold
                            color: "#00D4AA"
                        }
                        
                        // Front sensor values
                        Repeater {
                            model: 6
                            
                            Row {
                                spacing: 8
                                width: parent.width
                                
                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: getZoneColor(sensorDistances[index])
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Text {
                                    text: "S" + (index + 1) + ":"
                                    color: "#FFFFFF"
                                    font.pixelSize: 11
                                    font.family: "Segoe UI"
                                    font.weight: Font.Medium
                                    width: 25
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Text {
                                    text: sensorDistances[index].toFixed(1) + "m"
                                    color: getZoneColor(sensorDistances[index])
                                    font.pixelSize: 11
                                    font.family: "Segoe UI"
                                    font.weight: Font.Bold
                                    width: 40
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Text {
                                    text: getSensorName(index)
                                    color: "#B0B0B0"
                                    font.pixelSize: 9
                                    font.family: "Segoe UI"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#2A2A2A"
                        }
                        
                        // Rear Sensors Section
                        Text {
                            text: "REAR SENSORS"
                            font.pixelSize: 14
                            font.family: "Segoe UI"
                            font.weight: Font.Bold
                            color: "#FF4444"
                        }
                        
                        // Rear sensor values
                        Repeater {
                            model: 6
                            
                            Row {
                                spacing: 8
                                width: parent.width
                                
                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: getZoneColor(sensorDistances[index + 6])
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Text {
                                    text: "S" + (index + 7) + ":"
                                    color: "#FFFFFF"
                                    font.pixelSize: 11
                                    font.family: "Segoe UI"
                                    font.weight: Font.Medium
                                    width: 25
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Text {
                                    text: sensorDistances[index + 6].toFixed(1) + "m"
                                    color: getZoneColor(sensorDistances[index + 6])
                                    font.pixelSize: 11
                                    font.family: "Segoe UI"
                                    font.weight: Font.Bold
                                    width: 40
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Text {
                                    text: getSensorName(index + 6)
                                    color: "#B0B0B0"
                                    font.pixelSize: 9
                                    font.family: "Segoe UI"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#2A2A2A"
                        }
                        
                        // Zone Legend (compact)
                        Text {
                            text: "Zone Legend"
                            font.pixelSize: 12
                            font.family: "Segoe UI"
                            font.weight: Font.Medium
                            color: "#00D4AA"
                        }
                        
                        Grid {
                            columns: 1
                            spacing: 4
                            width: parent.width
                            
                            Repeater {
                                model: [
                                    {name: "Critical", range: "0.0-0.3m", color: "#8B0000"},
                                    {name: "Warning", range: "0.3-0.8m", color: "#FF0000"},
                                    {name: "Caution", range: "0.8-1.5m", color: "#FFA500"},
                                    {name: "Advisory", range: "1.5-2.5m", color: "#FFFF00"},
                                    {name: "Monitoring", range: "2.5-5.0m", color: "#90EE90"},
                                    {name: "Max Range", range: "5.0-10.0m", color: "#ADD8E6"}
                                ]
                                
                                Row {
                                    spacing: 6
                                    
                                    Rectangle {
                                        width: 10
                                        height: 10
                                        radius: 2
                                        color: modelData.color
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    Text {
                                        text: modelData.name + " " + modelData.range
                                        color: "#CCCCCC"
                                        font.pixelSize: 9
                                        font.family: "Segoe UI"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#2A2A2A"
                        }
                        
                        // System Status
                        Text {
                            text: "System Status"
                            font.pixelSize: 12
                            font.family: "Segoe UI"
                            font.weight: Font.Medium
                            color: "#00D4AA"
                        }
                        
                        Column {
                            width: parent.width
                            spacing: 4
                            
                            Row {
                                spacing: 10
                                Text {
                                    text: "Mode:"
                                    color: "#B0B0B0"
                                    font.pixelSize: 10
                                    font.family: "Segoe UI"
                                }
                                Text {
                                    text: guiTestMode ? "GUI Test" : "Live Data"
                                    color: guiTestMode ? "#FF8800" : "#00FF00"
                                    font.pixelSize: 10
                                    font.family: "Segoe UI"
                                    font.weight: Font.Medium
                                }
                            }
                            
                            Row {
                                spacing: 10
                                Text {
                                    text: "Update Rate:"
                                    color: "#B0B0B0"
                                    font.pixelSize: 10
                                    font.family: "Segoe UI"
                                }
                                Text {
                                    text: "15-20 Hz"
                                    color: "#00D4AA"
                                    font.pixelSize: 10
                                    font.family: "Segoe UI"
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}