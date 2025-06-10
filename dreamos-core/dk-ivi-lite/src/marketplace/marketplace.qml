import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import "../resource/customwidgets"
import MarketplaceAsync 1.0

Rectangle {
    id: marketplace_page
    visible: true
    width: parent.width
    height: parent.height

    property int numbeOfInstalledApps: 0
    property int numbeOfSearchedApps: 0
    property int installAppIndex: -1
    property bool isSearchTextInputEmpty: true
    property int removeAppIndex: -1
    property string activeAppName: ""

    Rectangle {
        id: bg
        color: "#0F0F0F"
        anchors.fill: parent
    }

    function searchApp () {
        appListModel.clear()
        appAsync.searchAppFromStore(searchTextInput.text)
        appListMenu.currentIndex = -1
        Qt.inputMethod.hide();
    }

    Component.onCompleted: {
        appAsync.initMarketplaceListFromDB()
    }

    Connections {
        target: appListMenu
        function onCurrentIndexChanged() {
            if (appListMenu.currentIndex === -1) {
                return
            }

            appListModel.clear()
            searchTextInput.text = "Search apps and services..."
            isSearchTextInputEmpty = true

            if (appListMenu.currentIndex === 0) {
                appAsync.searchAppFromStore("vehicle")
            }
            else if (appListMenu.currentIndex === 1) {
                appAsync.searchAppFromStore("vehicle-service")
            }
            else {
                appAsync.searchAppFromStore("XXXXXX")
            }
        }
    }

    Connections {
        target: appListView
        function onCurrentIndexChanged() {
            console.log(`appListView index changed to ${appListView.currentIndex}`)
            if ((appListView.currentIndex === -1)
                    || (appListView.currentIndex >= (appListView.count - 1))
                    || (appListView.currentIndex >= (numbeOfSearchedApps)))  {
                appListView.currentIndex = -1
                return
            }

            let matchApp = appListModel.get(appListView.currentIndex)
            if(matchApp && !matchApp.is_installed) {
                activeAppName = matchApp.name
                installAppIndex = appListView.currentIndex
                installAppPopup.open()
            }
        }
    }

    Connections {
        target: searchTextInput
        function accepted() {
            console.log("searchTextInput accepted")
            Qt.inputMethod.hide();
        }

        function onEditingFinished() {
            console.log("onEditingFinished finish")
            Qt.inputMethod.hide();
            if (searchTextInput.text === "") {
                searchTextInput.text = "Search apps and services..."
                isSearchTextInputEmpty = true
                return
            }
            isSearchTextInputEmpty = false
        }
        
        function onActiveFocusChanged(activeFocus) {
            if (activeFocus) {
                if(searchTextInput.text === "Search apps and services...") {
                    searchTextInput.text = "";
                }
            }
        }
    }

    MarketplaceAsync {
        id: appAsync
        onClearAppInfoToAppList: () => {
            appListModel.clear()
        }

        onAppendAppInfoToAppList: (name, author, rating, noofdownload, icon, isInstalled) => {
            if (name === "") {
                appListModel.append({name: "No Result.", author: "", rating: "", noofdownload: "", iconpath: "", is_installed: false})
            } else {
                appListModel.append({
                    name: name,
                    author: author,
                    rating: rating+"*",
                    noofdownload: noofdownload,
                    iconpath: icon,
                    is_installed: isInstalled
                })
            }
        }

        onAppendLastRowToAppList: (noOfApps) => {
            numbeOfSearchedApps = noOfApps
            appListModel.append({name: "", author: "", rating: "", noofdownload: "", iconpath: ""})
            appListView.positionViewAtBeginning()
        }

        onHandleFailureAppInstallation: (type, msg) => {
            // Handle failure - you might want to add a popup here
        }

        onClearMarketplaceNameList: () => {
            marketplace_comboBox_model.clear();
        }

        onAppendMarketplaceUrlList: (name) => {
            marketplace_comboBox_model.append({text: name});
            marketplace_comboBox.currentIndex = 0
        }

        onSetInstallServiceRunningStatus: (status) => {
            notifArea.visible = status
        }
    }

    Dialog {
        id: installAppPopup
        width: 500
        height: 400
        anchors.centerIn: parent
        modal: true

        onAccepted: {
            appAsync.installApp(installAppIndex)
            installAppPopup.close()
            appListView.currentIndex = -1
            notifArea.visible = true
        }
        
        onRejected: {
            installAppPopup.close()
            appListView.currentIndex = -1
        }

        background: Rectangle {
            color: "#1A1A1A"
            radius: 16
            border.color: "#2A2A2A"
            border.width: 1
        }

        contentItem: Column {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 24

            Text {
                width: parent.width
                text: `Confirm install app <b>${activeAppName}</b>?`
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.family: "Segoe UI"
                font.pixelSize: 16
                wrapMode: Text.WordWrap
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24

                Button {
                    text: "Cancel"
                    onClicked: installAppPopup.rejected()
                    background: Rectangle {
                        color: "#2A2A2A"
                        radius: 12
                        border.color: "#404040"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#B0B0B0"
                        font.family: "Segoe UI"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    text: "Install"
                    onClicked: installAppPopup.accepted()
                    background: Rectangle {
                        color: "#00D4AA"
                        radius: 12
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.family: "Segoe UI"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    // Main content area
    Rectangle {
        id: searchAppRec
        anchors.fill: parent
        anchors.margins: 32
        color: "transparent"

        // Search area
        Rectangle {
            id: search_area
            x: 0
            y: 0
            width: 380
            height: 56
            color: "#1A1A1A"
            radius: 28
            border.color: "#2A2A2A"
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12

                CustomBtn1 {
                    id: searchAppButton
                    width: 40
                    height: 40
                    btnIconSource: "../resource/search.png"
                    iconWidth: 20
                    iconHeight: 20
                    colorDefault: "#00D4AA20"
                    colorClicked: "#00D4AA40"
                    btn_border_color: "transparent"
                    btn_background_color: "transparent"
                    btn_color_overlay: "#00D4AA40"
                    onClicked: searchApp()
                }

                TextInput {
                    id: searchTextInput
                    width: 300
                    height: 40
                    text: "Search apps and services..."
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    font.family: "Segoe UI"
                    color: activeFocus ? "#FFFFFF" : "#707070"
                    clip: true
                }
            }
        }

        // Tab menu
        ListView {
            id: appListMenu
            x: 0
            y: 80
            width: parent.width
            height: 60
            orientation: ListView.Horizontal
            currentIndex: -1
            spacing: 24

            highlight: Rectangle {
                color: "transparent"
                Rectangle {
                    width: parent.width
                    height: 3
                    anchors.bottom: parent.bottom
                    color: "#00D4AA"
                    radius: 1.5
                }
            }

            delegate: Item {
                width: 180
                height: 60

                Text {
                    text: name
                    font.pointSize: 16
                    font.family: "Segoe UI"
                    font.weight: appListMenu.currentIndex === index ? Font.Medium : Font.Normal
                    color: appListMenu.currentIndex === index ? "#00D4AA" : "#B0B0B0"
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        appListMenu.currentIndex = index
                    }
                }
            }

            model: ListModel {
                ListElement { name: "Vehicle App" }
                ListElement { name: "Vehicle Service" }
            }
        }

        // App grid
        GridView {
            id: appListView
            x: 0
            y: 160
            width: parent.width
            height: parent.height - 180
            currentIndex: -1
            cellWidth: Math.floor(width / Math.floor(width / 200))
            cellHeight: 280
            clip: true

            function setActiveIndex(index) {
                currentIndex = index
            }

            delegate: Item {
                width: appListView.cellWidth
                height: appListView.cellHeight
                visible: name.length > 0 && name !== "No Result." && iconpath && iconpath.length > 0

                Rectangle {
                    id: appCard
                    width: parent.width - 16
                    height: parent.height - 16
                    anchors.centerIn: parent
                    color: appListView.currentIndex === index ? "#00D4AA15" : "#1A1A1A"
                    radius: 20
                    border.color: appListView.currentIndex === index ? "#00D4AA" : "#2A2A2A"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        // App Icon
                        Rectangle {
                            width: 100
                            height: 100
                            radius: 20
                            color: "#FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter

                            Image {
                                id: appIcon
                                source: iconpath || "../resource/default-app-icon.png"
                                width: 80
                                height: 80
                                anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit

                                Rectangle {
                                    anchors.fill: parent
                                    visible: appIcon.status === Image.Error
                                    color: "#E3F2FD"
                                    radius: 16

                                    Text {
                                        anchors.centerIn: parent
                                        text: name.length > 0 ? name.charAt(0).toUpperCase() : "?"
                                        font.pixelSize: 32
                                        font.bold: true
                                        color: "#1976D2"
                                    }
                                }
                            }

                            // Install badge
                            Rectangle {
                                visible: is_installed && name.length > 0 && name !== "No Result."
                                width: 20
                                height: 20
                                radius: 10
                                color: "#00D4AA"
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: -8

                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: "white"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }

                        // App info
                        Column {
                            width: parent.width
                            spacing: 4

                            Text {
                                text: name
                                font.bold: true
                                font.pixelSize: 16
                                color: "#FFFFFF"
                                font.family: "Segoe UI"
                                anchors.horizontalCenter: parent.horizontalCenter
                                elide: Text.ElideRight
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                text: author
                                font.pixelSize: 12
                                color: "#90FFFFFF"
                                font.family: "Segoe UI"
                                anchors.horizontalCenter: parent.horizontalCenter
                                elide: Text.ElideRight
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Install button
                        Rectangle {
                            visible: name.length > 0 && name !== "No Result."
                            width: parent.width
                            height: 40  // Made slightly taller
                            color: is_installed ? "#00D4AA" : "#2196F3"
                            radius: 20
                            border.width: 2
                            border.color: "transparent"
                            
                            Text {
                                anchors.centerIn: parent
                                text: is_installed ? "Installed" : "Install"
                                color: "white"
                                font.family: "Segoe UI"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5  // Extend click area slightly beyond button
                                enabled: !is_installed
                                hoverEnabled: true
                                
                                onEntered: {
                                    parent.border.color = "#FFFFFF"
                                    parent.scale = 1.05
                                }
                                
                                onExited: {
                                    parent.border.color = "transparent"
                                    parent.scale = 1.0
                                }
                                
                                onPressed: {
                                    parent.scale = 0.95
                                }
                                
                                onReleased: {
                                    parent.scale = 1.05
                                }
                                
                                onClicked: {
                                    console.log("=== INSTALL BUTTON CLICKED ===")
                                    console.log("App name:", name)
                                    console.log("App index:", index)
                                    console.log("Is installed:", is_installed)
                                    
                                    if (!is_installed) {
                                        activeAppName = name
                                        installAppIndex = index
                                        installAppPopup.open()
                                    }
                                }
                            }
                            
                            // Smooth transitions
                            Behavior on scale {
                                NumberAnimation { duration: 100 }
                            }
                            
                            Behavior on border.color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                    }

                    // Card background mouse area (for info only, does not interfere with button)
                    MouseArea {
                        anchors.fill: parent
                        anchors.bottomMargin: 60  // Keep well clear of install button
                        onClicked: {
                            console.log("App card info area clicked for:", name)
                            // Could show app details here in the future
                        }
                    }
                }
            }

            model: ListModel {
                id: appListModel
                ListElement {
                    name: ""
                    author: ""
                    rating: ""
                    noofdownload: ""
                    iconpath: ""
                    is_installed: false
                }
            }
        }

        // Notification area
        Rectangle {
            id: notifArea
            x: search_area.x + search_area.width + 20
            y: search_area.y
            width: 400
            height: 56
            visible: false
            color: "#1A1A1A"
            radius: 28
            border.color: "#00D4AA"
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                BusyIndicator {
                    width: 24
                    height: 24
                    Material.accent: "#00D4AA"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Installing..."
                    font.family: "Segoe UI"
                    font.pixelSize: 14
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // Marketplace selector
    ComboBox {
        id: marketplace_comboBox
        x: parent.width - 280
        y: 32
        width: 250
        height: 48
        model: ListModel {
            id: marketplace_comboBox_model
        }

        background: Rectangle {
            color: "#1A1A1A"
            radius: 24
            border.color: "#2A2A2A"
            border.width: 1
        }

        contentItem: Text {
            text: marketplace_comboBox.currentText
            color: "#FFFFFF"
            font.family: "Segoe UI"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        delegate: ItemDelegate {
            width: marketplace_comboBox.width
            text: model.text
            
            background: Rectangle {
                color: "#1A1A1A"
                border.color: "#2A2A2A"
            }
            
            contentItem: Text {
                text: parent.text
                color: "#FFFFFF"
                font.family: "Segoe UI"
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: {
                marketplace_comboBox.currentIndex = index
                appAsync.setCurrentMarketPlaceIdx(index)
            }
        }
    }
}