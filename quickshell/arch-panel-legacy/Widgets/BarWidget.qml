import QtQuick
import Quickshell
import "../"
import "../Services" as Services

// Один виджет бара по записи из конфига ({ type = "wifi", ... }).
// Реестр типов - функция pickComponent() внизу: чтобы добавить новый
// виджет, объяви Component и добавь case.
Item {
    id: root

    property var spec: ({})
    property int barHeight: 30
    readonly property string type: spec.type ?? ""

    // (имя дропдауна, элемент-якорь)
    signal openDropdown(string name, Item anchorItem)

    Colors { id: palette }

    width: loader.item ? loader.item.width : 0
    height: barHeight

    function colorOf(name, fallback) {
        if (name === undefined || name === null) return fallback
        return palette[name] !== undefined ? palette[name] : name
    }

    // ---- параметры иконок ------------------------------------------------
    function iconGlyph() {
        const s = root.spec
        if (s.glyph !== undefined) return Services.Config.glyph(s.glyph)
        switch (root.type) {
            case "logo": return Services.Config.glyph("f303")
            case "wifi": return Services.Config.glyph("f1eb")
            case "bluetooth": return Services.Config.glyph("f294")
            case "audio": return Services.Config.glyph(Services.AudioService.muted ? "f026" : "f028")
            default: return Services.Config.glyph("f111")
        }
    }
    function iconColor() {
        const on = palette.color7
        const off = palette.color5
        let c = on
        if (root.type === "wifi") c = Services.WifiService.wifiEnabled ? on : off
        else if (root.type === "bluetooth") c = Services.BluetoothService.enabled ? on : off
        else if (root.type === "audio") c = Services.AudioService.muted ? off : on
        return colorOf(root.spec.color, c)
    }
    function iconDropdown() {
        if (root.spec.dropdown !== undefined) return root.spec.dropdown
        switch (root.type) {
            case "logo": return "system"
            case "wifi": return "wifi"
            case "bluetooth": return "bluetooth"
            case "audio": return "audio"
            default: return ""
        }
    }

    function pickComponent(type) {
        switch (type) {
            case "logo": case "wifi": case "bluetooth": case "audio": case "icon":
                return iconComp
            case "workspaces": return workspacesComp
            case "tray": return trayComp
            case "clock": return clockComp
            case "battery": return batteryComp
            case "text": return textComp
            case "spacer": return spacerComp
            default: return unknownComp
        }
    }

    Loader {
        id: loader
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: root.pickComponent(root.type)
    }

    // ---------------------------------------------------------------- виджеты
    Component {
        id: iconComp
        BarIcon {
            id: icon
            barHeight: root.barHeight
            width: root.spec.width ?? 46
            glyph: root.iconGlyph()
            glyphSize: root.spec.size ?? (root.type === "logo" ? 16 : 14)
            glyphColor: root.iconColor()
            dropdown: root.iconDropdown()
            command: root.spec.command ?? []
            onTriggered: name => root.openDropdown(name, icon)
        }
    }

    Component {
        id: workspacesComp
        Workspaces {
            visibleCount: root.spec.count ?? 10
        }
    }

    Component {
        id: trayComp
        SysTray {
            monochrome: root.spec.monochrome ?? true
        }
    }

    Component {
        id: clockComp
        Text {
            leftPadding: 8
            rightPadding: 8
            text: Qt.formatDateTime(clock.date, root.spec.format ?? "HH:mm")
            font.pixelSize: root.spec.size ?? 12
            color: root.colorOf(root.spec.color, palette.color7)

            SystemClock {
                id: clock
                precision: (root.spec.format ?? "HH:mm").indexOf("s") >= 0
                           ? SystemClock.Seconds : SystemClock.Minutes
            }
        }
    }

    Component {
        id: batteryComp
        Text {
            visible: Services.BatteryService.available
            width: visible ? implicitWidth : 0
            leftPadding: 8
            rightPadding: 8
            text: (Services.BatteryService.charging ? Services.Config.glyph("f0e7") : Services.Config.glyph("f240"))
                  + ((root.spec.showPercent ?? true)
                     ? "  " + Math.round(Services.BatteryService.percent * 100) + "%" : "")
            font.family: "Symbols Nerd Font"
            font.pixelSize: root.spec.size ?? 12
            color: root.colorOf(root.spec.color, Services.BatteryService.percent < 0.2 ? palette.color5 : palette.color7)
        }
    }

    Component {
        id: textComp
        Text {
            leftPadding: 8
            rightPadding: 8
            text: root.spec.text ?? ""
            font.pixelSize: root.spec.size ?? 12
            color: root.colorOf(root.spec.color, palette.color7)
        }
    }

    Component {
        id: spacerComp
        Item {
            width: root.spec.width ?? 10
            height: 1
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
