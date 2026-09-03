import QtQuick
import QtQuick.Layouts
import "Widgets"
import "Services" as Services

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        RowLayout {
            spacing: 5

            ColumnLayout {
                Layout.preferredWidth: 160
                Layout.fillHeight: true
                spacing: 10

                Text {
                    text: "Система"
                    color: colors.color15
                    font.pixelSize: 11
                    font.bold: true
                }

                RowLayout {
                    spacing: 14
                    Layout.alignment: Qt.AlignHCenter

                    CircularGauge {
                        value: Services.SystemUsage.cpuUsage
                        label: "CPU"
                        ringColor: colors.color14
                    }

                    CircularGauge {
                        value: Services.SystemUsage.ramUsage
                        label: "RAM"
                        ringColor: colors.color14
                    }
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                spacing: 10

                Text {
                    text: "Быстрые настройки"
                    color: colors.color15
                    font.pixelSize: 11
                    font.bold: true
                }

                QuickStatusRow {
                    Layout.fillWidth: true
                }
            }
        }


        ColumnLayout{
            spacing: 5
            UpdateButton {
                Layout.alignment: Qt.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                Text {
                    text: "Обработка изображения"
                    color: colors.color15
                    font.pixelSize: 11
                    font.bold: true
                }

                ImageDropZone {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
