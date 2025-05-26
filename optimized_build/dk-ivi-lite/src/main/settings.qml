import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: settings_page
    width: Screen.width
    height: Screen.height
    color: "#212121"

    Component.onCompleted: {
    }

    Text {
        id: settings_page_header_text
        text: "dreamKIT"
        x: 10
        y: 30
        font.bold: true
        font.pointSize: 20
        color: "#8BC34A"
        font.family: "Arial"
    }

    ColumnLayout {
        spacing: 10
        y: 100
        width: parent.width
        height: parent.height - 100

        RowLayout {
            id: mainLayout
            Layout.fillWidth: true
            height: Screen.height - settings_page_header_text.height - 100
            spacing: 1

            Rectangle {
                id: menuPanel
                Layout.preferredWidth: settings_page.width * 0.2
                Layout.fillHeight: true
                color: "#1E1E1E"

                ListView {
                    id: settingsList
                    anchors.fill: parent
                    model: settingsModel
                    delegate: Item {
                        id: menuItem
                        width: settingsList.width
                        height: 50

                        Rectangle {
                            id: backgroundRect
                            anchors.fill: parent
                            color: settingsList.currentIndex === index ? "#333333" : "#1E1E1E"
                            border.color: "#212121"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                Text {
                                    id: itemText
                                    text: title
                                    font.pixelSize: 16
                                    color: "white"
                                    verticalAlignment: Text.AlignVCenter
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    id: notificationCircle
                                    width: 20
                                    height: 20
                                    radius: width / 2
                                    color: "red"
                                    visible: hasNotification

                                    Text {
                                        anchors.centerIn: parent
                                        text: "!"
                                        color: "white"
                                        font.bold: true
                                        font.pointSize: 12
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                settingsList.currentIndex = index
                                stackLayout.currentIndex = index
                            }
                        }
                    }
                    highlight: Rectangle { color: "transparent" }
                }
            }

            Rectangle {
                id: contentPanel
                Layout.fillWidth: true
                Layout.fillHeight: true

                StackLayout {
                    id: stackLayout
                    anchors.fill: parent
                    currentIndex: settingsList.currentIndex

                    Loader { source: "../controls/controls.qml" }
                    Loader { source: "../digitalauto/digitalauto.qml" }
                    Loader { source: "../installedvapps/installedvapps.qml" }
                    Loader { source: "../installedservices/installedservices.qml" }
                    Loader { source: "../marketplace/marketplace.qml" }
                }
            }
        }
    }

    ListModel {
        id: settingsModel
        ListElement { title: "Control"; icon: "../resource/icons/search.png"; hasNotification: false }
        ListElement { title: "App Test Deployment"; icon: "../resource/icons/search.png"; hasNotification: false }
        ListElement { title: "Vehicle App"; icon: "../resource/icons/search.png"; hasNotification: false }
        ListElement { title: "Vehicle Service"; icon: "../resource/icons/search.png"; hasNotification: false }
        ListElement { title: "Market Place"; icon: "../resource/icons/search.png"; hasNotification: false }
    }
}
