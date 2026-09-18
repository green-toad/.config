import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Services" as Services
import "../"

ColumnLayout {
    id: root
    spacing: 8
    Colors { id: colors }

    // ---- Volume
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

            background: Rectangle {
                implicitHeight: 6
                radius: 3
                color: colors.color8
                Rectangle {
                    width: volSlider.visualPosition * parent.width
                    height: parent.height
                    radius: 3
                    color: colors.color6
                }
            }

            handle: Rectangle {
                color: colors.color15
                border.color: colors.color6
                border.width: 1

                layer.enabled: true
                layer.effect: null
            }
        }

        Text {
            text: Math.round(Services.AudioService.volume * 100) + "%"
            color: colors.color15
            font.pixelSize: 11
            Layout.preferredWidth: 32
            horizontalAlignment: Text.AlignRight
        }
    }

    // ---- Battery
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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 16
            color: "transparent"
            border.color: colors.color15
            border.width: 1
            radius: 3
            clip: true

            Rectangle {
                width: parent.width * Services.BatteryService.percent - 4
                height: parent.height - 4
                x: 2
                y: 2
                radius: 2
                color: {
                    var p = Services.BatteryService.percent
                    if (p < 0.2) return colors.color5
                    if (p < 0.4) return colors.color11
                    return colors.color10
                }
                Behavior on width { NumberAnimation { duration: 200 } }
            }
        }

        Text {
            text: Math.round(Services.BatteryService.percent * 100) + "%"
            color: colors.color15
            font.pixelSize: 11
            Layout.preferredWidth: 48
            horizontalAlignment: Text.AlignRight
        }
    }
}