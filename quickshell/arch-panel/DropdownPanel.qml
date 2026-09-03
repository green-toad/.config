import QtQuick
import QtQuick.Layouts
import "Widgets"
import "Services" as Services

// Content shown below the bar when hovering the distro logo.
Item {
    id: root

    RowLayout {
        anchors.fill: parent
        spacing: 20

        // ---- Column 1: system monitor ---------------------------------
        ColumnLayout {
            Layout.preferredWidth: 160
            Layout.fillHeight: true
            spacing: 10

            Text {
                text: "Система"
                color: "#a6adc8"
                font.pixelSize: 11
                font.bold: true
            }

            RowLayout {
                spacing: 14
                Layout.alignment: Qt.AlignHCenter

                CircularGauge {
                    value: Services.SystemUsage.cpuUsage
                    label: "CPU"
                    ringColor: "#89b4fa"
                }

                CircularGauge {
                    value: Services.SystemUsage.ramUsage
                    label: "RAM"
                    ringColor: "#a6e3a1"
                }
            }

            Item { Layout.fillHeight: true }
        }

        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#313244" }

        // ---- Column 2: quick status + update button --------------------
        ColumnLayout {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            spacing: 10

            Text {
                text: "Быстрые настройки"
                color: "#a6adc8"
                font.pixelSize: 11
                font.bold: true
            }

            QuickStatusRow {
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }

            UpdateButton {
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#313244" }

        // ---- Column 3: image drop zone ---------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Text {
                text: "Обработка изображения"
                color: "#a6adc8"
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
