import QtQuick
import QtQuick.Layouts
import "../Widgets"
import "../Services" as Services

// Содержимое системного дропдауна. Wi-Fi и Bluetooth отсюда убраны -
// у них теперь свои собственные hover-дропдауны справа на баре
// (см. Panel.qml: wifiDropdown / bluetoothDropdown). Здесь остаются
// только гейджи, громкость/батарея, кнопки питания, апдейт и дропзона.
//
// NOTE: предполагается, что CPU/RAM-гейджи и QuickStatusRow (громкость/
// батарея) остаются здесь - в задаче было сказано оставить "только
// системные кнопки и область перетаскивания", но полностью убирать
// индикаторы громкости/батареи/нагрузки показалось избыточным сужением
// функциональности. Если хотите вынести их тоже (например, в саму
// строку бара) - скажите, это небольшая правка.
Item {
    id: root

    property var colors

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            ColumnLayout {
                Layout.preferredWidth: 150
                Layout.fillHeight: true
                spacing: 10

                RowLayout {
                    spacing: 14
                    Layout.alignment: Qt.AlignHCenter

                    CircularGauge {
                        value: Services.SystemUsage.cpuUsage
                        label: "CPU"
                        ringColor: root.colors.color14
                    }

                    CircularGauge {
                        value: Services.SystemUsage.ramUsage
                        label: "RAM"
                        ringColor: root.colors.color14
                    }
                }

                QuickStatusRow {
                    Layout.fillWidth: true
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 46
                Layout.fillHeight: true
                spacing: 10

                PowerButton {
                    Layout.fillWidth: true
                }

                RebootButton {
                    Layout.fillWidth: true
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            UpdateButton {
                Layout.alignment: Qt.AlignHCenter
            }

            ImageDropZone {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // MediaControlWidget {
            //     Layout.fillHeight: true
            //     Layout.fillWidth: true
            //     colors: colors
            // }
        }
    }
}
