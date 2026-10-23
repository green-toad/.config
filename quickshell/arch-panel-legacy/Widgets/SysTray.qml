import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// Renders every registered tray item; menus work natively via QsMenuAnchor.
RowLayout {
    id: root
    spacing: 8

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem
            required property SystemTrayItem modelData

            implicitWidth: 20
            implicitHeight: 20

            IconImage {
                anchors.fill: parent
                source: trayItem.modelData.icon
                asynchronous: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        if (trayItem.modelData.onlyMenu) {
                            trayItem.modelData.display()
                        } else {
                            trayItem.modelData.activate()
                        }
                    } else if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.secondaryActivate()
                    } else if (mouse.button === Qt.RightButton) {
                        contextMenu.open()
                    }
                }
            }

            QsMenuAnchor {
                id: contextMenu
                menu: trayItem.modelData.menu
                anchor.item: trayItem
                anchor.rect.y: trayItem.height
            }
        }
    }
}
