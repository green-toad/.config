import QtQuick
import QtQuick.Layouts
import "../Widgets"
import "../Services" as Services

// Компоновка - как была; из config.lua приходит только список включённых
// частей (parts): cpu, ram, battery, power, reboot, update, image.
Item {
    id: root

    property var colors
    property var parts: []

    function has(n) { return parts.indexOf(n) >= 0 }

    // 260 (высота дропдауна) минус поля
    implicitHeight: 240

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            visible: root.has("cpu") || root.has("ram") || root.has("battery")
                     || root.has("power") || root.has("reboot")

            ColumnLayout {
                Layout.preferredWidth: 150
                Layout.fillHeight: true
                spacing: 10
                visible: root.has("cpu") || root.has("ram") || root.has("battery")

                RowLayout {
                    spacing: 14
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.has("cpu") || root.has("ram")

                    CircularGauge {
                        visible: root.has("cpu")
                        value: Services.SystemUsage.cpuUsage
                        label: "CPU"
                        ringColor: root.colors.color14
                    }

                    CircularGauge {
                        visible: root.has("ram")
                        value: Services.SystemUsage.ramUsage
                        label: "RAM"
                        ringColor: root.colors.color14
                    }
                }

                QuickStatusRow {
                    Layout.fillWidth: true
                    visible: root.has("battery")
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 46
                Layout.fillHeight: true
                spacing: 10
                visible: root.has("power") || root.has("reboot")

                PowerButton {
                    Layout.fillWidth: true
                    visible: root.has("power")
                }

                RebootButton {
                    Layout.fillWidth: true
                    visible: root.has("reboot")
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            visible: root.has("update") || root.has("image")

            UpdateButton {
                Layout.alignment: Qt.AlignHCenter
                visible: root.has("update")
            }

            ImageDropZone {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.has("image")
            }
        }
    }
}
