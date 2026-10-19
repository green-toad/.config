import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../"

// Иконки трея, перекрашенные под палитру панели; меню работают нативно
// через QsMenuAnchor.
RowLayout {
    id: root
    spacing: 4
    Colors { id: colors }

    // Привести иконки приложений к одному цвету панели.
    property bool monochrome: true
    property color tint: colors.color7
    // 0..1: насколько сильно закрашивать (1 = чистый силуэт одного цвета)
    property real tintStrength: 0.85

    // Пока открыто контекстное меню иконки, панель нельзя сворачивать
    property int openMenus: 0
    readonly property bool menuOpen: openMenus > 0

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem
            required property SystemTrayItem modelData

            implicitWidth: 26
            implicitHeight: 26

            Rectangle {
                anchors.fill: parent
                radius: 7
                color: colors.color7
                opacity: (mouse.containsMouse || contextMenu.visible) ? 0.16 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            IconImage {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: trayItem.modelData.icon
                asynchronous: true

                layer.enabled: root.monochrome
                layer.effect: MultiEffect {
                    saturation: -1.0
                    brightness: 0.2
                    colorization: root.tintStrength
                    colorizationColor: root.tint
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
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

                onVisibleChanged: root.openMenus += visible ? 1 : -1
            }

            Component.onDestruction: {
                if (contextMenu.visible) root.openMenus -= 1
            }
        }
    }
}
