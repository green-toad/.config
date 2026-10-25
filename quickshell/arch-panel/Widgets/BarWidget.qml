import QtQuick
import Quickshell
import "../"
import "../Services" as Services

// Виджет бара по имени из config.lua. Чтобы добавить новый тип:
// объяви Component и добавь case в pickComponent().
Item {
    id: root

    property string type: ""
    property int barHeight: 30

    // (имя дропдауна, элемент-якорь)
    signal openDropdown(string name, Item anchorItem)

    Colors { id: palette }

    width: loader.item ? loader.item.width : 0
    height: barHeight

    function pickComponent(t) {
        switch (t) {
            case "logo": case "wifi": case "bluetooth": case "audio": return iconComp
            case "workspaces": return workspacesComp
            case "tray": return trayComp
            case "clock": return clockComp
            case "battery": return batteryComp
            default: return unknownComp
        }
    }

    Loader {
        id: loader
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: root.pickComponent(root.type)
    }

    Component {
        id: iconComp
        BarIcon {
            id: icon
            barHeight: root.barHeight
            dropdown: root.type === "logo" ? "system" : root.type
            glyphSize: root.type === "logo" ? 16 : 14
            glyph: {
                switch (root.type) {
                    case "logo": return "\uF303"
                    case "wifi": return "\uF1EB"
                    case "bluetooth": return "\uF294"
                    default: return Services.AudioService.muted ? "\uF026" : "\uF028"
                }
            }
            glyphColor: {
                switch (root.type) {
                    case "wifi": return Services.WifiService.wifiEnabled ? palette.color7 : palette.color5
                    case "bluetooth": return Services.BluetoothService.enabled ? palette.color7 : palette.color5
                    case "audio": return Services.AudioService.muted ? palette.color5 : palette.color7
                    default: return palette.color7
                }
            }
            onTriggered: name => root.openDropdown(name, icon)
        }
    }

    Component { id: workspacesComp; Workspaces {} }
    Component { id: trayComp; SysTray {} }

    Component {
        id: clockComp
        Text {
            leftPadding: 8
            rightPadding: 8
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: 12
            color: palette.color7
            SystemClock { id: clock; precision: SystemClock.Minutes }
        }
    }

    Component {
        id: batteryComp
        Text {
            visible: Services.BatteryService.available
            width: visible ? implicitWidth : 0
            leftPadding: 8
            rightPadding: 8
            text: (Services.BatteryService.charging ? "\uF0E7" : "\uF240")
                  + "  " + Math.round(Services.BatteryService.percent * 100) + "%"
            font.family: "Symbols Nerd Font"
            font.pixelSize: 12
            color: Services.BatteryService.percent < 0.2 ? palette.color5 : palette.color7
        }
    }

    Component {
        id: unknownComp
        Text {
            leftPadding: 8
            rightPadding: 8
            text: "?" + root.type
            font.pixelSize: 11
            color: palette.color5
        }
    }
}
