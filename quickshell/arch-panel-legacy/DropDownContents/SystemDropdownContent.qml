import QtQuick
import QtQuick.Layouts
import "../Widgets"
import "../Services" as Services

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
