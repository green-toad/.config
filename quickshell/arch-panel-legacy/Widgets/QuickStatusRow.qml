import QtQuick
import QtQuick.Layouts
import "../Services" as Services
import "../"

ColumnLayout {
    id: root
    spacing: 8
    Colors { id: colors }

    // ---- Battery (на месте бывшего слайдера звука)
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
                width: Math.max(0, parent.width * Services.BatteryService.percent - 4)
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

    // Нет батареи (ПК) - просто пометка, чтобы слот не был пустым
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: !Services.BatteryService.available

        Text {
            text: "\uF1E6"
            font.family: "Symbols Nerd Font"
            font.pixelSize: 14
            color: colors.color10
            Layout.preferredWidth: 18
        }
        Text {
            text: "От сети"
            color: colors.color15
            font.pixelSize: 11
        }
    }
}
