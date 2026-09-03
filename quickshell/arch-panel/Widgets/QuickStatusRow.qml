import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Services" as Services

ColumnLayout {
    id: root
    spacing: 8

    // ---- Volume ---------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: Services.AudioService.muted ? "\uF026" : "\uF028"
            font.family: "Symbols Nerd Font"
            font.pixelSize: 14
            color: "#89b4fa"
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
            color: "#cdd6f4"
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
            color: Services.WifiService.connected ? "#a6e3a1" : "#f38ba8"
            Layout.preferredWidth: 18
        }

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: Services.WifiService.ssid
            color: "#cdd6f4"
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
            color: "#f9e2af"
            Layout.preferredWidth: 18
        }

        Text {
            Layout.fillWidth: true
            text: Math.round(Services.BatteryService.percent * 100) + "%"
                  + (Services.BatteryService.charging ? " (заряжается)" : "")
            color: "#cdd6f4"
            font.pixelSize: 12
        }
    }
}
