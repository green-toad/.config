import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

Row {
    id: trayContainer

    // Свойство для ссылки на главное окно (будет передано из shell.qml)
    property QtObject mainWindow: null

    anchors {
        right: parent.right
        rightMargin: 10
        verticalCenter: parent.verticalCenter
    }
    spacing: 10

    PopupWindow {
        id: customMenu
        visible: false
        anchor.window: mainWindow

        implicitWidth: 150
        implicitHeight: 100

        property var menuModel: []

        Column {
            anchors.fill: parent
            Repeater {
                model: customMenu.menuModel
                delegate: Rectangle {
                    width: customMenu.width
                    height: 30
                    color: "white"
                    Text {
                        text: modelData.label ? modelData.label : ""
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            modelData.trigger()
                            customMenu.visible = false
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            propagateComposedEvents: true
            onClicked: customMenu.visible = false
        }
    }

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: trayDelegate
            width: 20
            height: 20
            color: Qt.rgba(0, 0, 0, 0)

            Image {
                id: trayIcon
                anchors.centerIn: parent
                width: 17
                height: 17
                source: modelData.icon ? modelData.icon : ""
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate()
                    }
                    else if (mouse.button === Qt.RightButton) {
                        if (modelData.hasMenu) {

                            customMenu.menuModel = modelData.menu ? modelData.menu : []
                            var globalPos = trayDelegate.mapToGlobal(mouse.x, mouse.y)
                            // customMenu.x = globalPos.x
                            // customMenu.y = globalPos.y
                            customMenu.visible = true
                        }
                    }
                    else if (mouse.button === Qt.MiddleButton) {
                        modelData.secondaryActivate()
                    }
                }
            }
        }
    }
}