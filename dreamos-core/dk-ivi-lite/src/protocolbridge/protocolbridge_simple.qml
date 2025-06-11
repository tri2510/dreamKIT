import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    anchors.fill: parent
    color: "#ff0000"  // Red background to make it obvious if it loads
    
    Column {
        anchors.centerIn: parent
        spacing: 20
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Protocol Bridge is Working!"
            color: "#ffffff"
            font.pixelSize: 32
            font.bold: true
        }
        
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Test Button"
            onClicked: {
                console.log("Protocol Bridge button clicked!")
            }
        }
    }
}