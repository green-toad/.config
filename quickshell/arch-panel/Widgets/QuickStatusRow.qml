import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Services" as Services
import "../"

ColumnLayout {
    id: root
    spacing: 8
    Colors { id: colors }

    // ---- Volume ---------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: Services.AudioService.muted ? "\uF026" : "\uF028"
            font.family: "Symbols Nerd Font"
            font.pixelSize: 14
            color: colors.color6
            Layout.preferredWidth: 18
        }

        Slider {
            id: volSlider
            Layout.fillWidth: true
            from: 0
            to: 1.5
            value: Services.AudioService.volume
            onMoved: Services.AudioService.setVolume(value)
        }

        Text {
            text: Math.round(Services.AudioService.volume * 100) + "%"
            color: colors.color15
            font.pixelSize: 11
            Layout.preferredWidth: 32
        }
    }

    // ---- Wi-Fi ------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "\uF1EB"
            font.family: "Symbols Nerd Font"
            font.pixelSize: 14
            color: Services.WifiService.connected ? colors.color10 : colors.color5
            Layout.preferredWidth: 18
        }

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: Services.WifiService.ssid
            color: colors.color15
            font.pixelSize: 12
        }
    }

    // ---- Battery ------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: Services.BatteryService.available

        Text {
            text: Services.BatteryService.charging ? "\uF0E7" : "\uF240"
            font.family: "Symbols Nerd Font"
            font.pixelSize: 14
            color: colors.color10
            Layout.preferredWidth: 18
        }

        Text {
            Layout.fillWidth: true
            text: Math.round(Services.BatteryService.percent * 100) + "%"
                  + (Services.BatteryService.charging ? " (заряжается)" : "")
            color: colors.color15
            font.pixelSize: 12
        }
    }
}
