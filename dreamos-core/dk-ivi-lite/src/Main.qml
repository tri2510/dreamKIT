import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1024
    height: 768

    SwipeView {
        id: swipeView
        anchors.fill: parent

        Loader {
            source: "aiassist.qml"
        }
        Loader {
            source: "digitalauto.qml"
        }
        Loader {
            source: "installedvapps.qml"
        }      
        Loader {
            source: "installedservices.qml"
        }
        Loader {
            source: "marketplace.qml"
        }
    }
}
