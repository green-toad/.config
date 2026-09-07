import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Services" as Services
import "../"

ColumnLayout {
    id: root
    spacing: 8
    Colors { id: colors }

    // ---- Вспомогательное свойство для имитации состояния Wi-Fi ----
    property bool wifiEnabled: Services.WifiService.connected

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
                implicitWidth: 14
                implicitHeight: 14
                radius: 7
                color: colors.color15
                border.color: colors.color6
                border.width: 1
                // Небольшая тень для объёма
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

    // ---- Wi-Fi ------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Иконка Wi‑Fi (меняет цвет в зависимости от состояния)
        Text {
            text: "\uF1EB"
            font.family: "Symbols Nerd Font"
            font.pixelSize: 14
            color: wifiEnabled ? colors.color10 : colors.color5
            Layout.preferredWidth: 18
            MouseArea {
                anchors.fill: parent
                onClicked: wifiEnabled = !wifiEnabled
            }
        }

        // SSID или статус
        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: wifiEnabled ? Services.WifiService.ssid : "Выключен"
            color: colors.color15
            font.pixelSize: 12
        }

        // Переключатель (стилизованный)
        Switch {
            id: wifiSwitch
            checked: wifiEnabled
            onCheckedChanged: wifiEnabled = checked   // синхронизируем

            indicator: Rectangle {
                implicitWidth: 36
                implicitHeight: 20
                radius: 10
                color: wifiSwitch.checked ? colors.color10 : colors.color5
                border.color: colors.color15
                border.width: 0.5

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: colors.color15
                    x: wifiSwitch.checked ? parent.width - width - 3 : 3
                    y: 3
                    Behavior on x { NumberAnimation { duration: 120 } }
                }
            }

            // Скрываем стандартный фон
            background: Item { }
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

        // Кастомный индикатор батареи
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 16
            color: "transparent"
            border.color: colors.color15
            border.width: 1
            radius: 3
            clip: true

            // Заполнение
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

            // Контакт батареи (маленький выступ справа)
            Rectangle {
                width: 4
                height: 6
                x: parent.width - 2
                y: (parent.height - height) / 2
                radius: 1
                color: colors.color15
            }
        }

        Text {
            text: Math.round(Services.BatteryService.percent * 100) + "%"
                  + (Services.BatteryService.charging ? " ⚡" : "")
            color: colors.color15
            font.pixelSize: 11
            Layout.preferredWidth: 48
            horizontalAlignment: Text.AlignRight
        }
    }
}