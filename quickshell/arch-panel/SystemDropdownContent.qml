import QtQuick
import QtQuick.Layouts
import "Widgets"
import "Services" as Services

// The content of the "system" dropdown (CPU/RAM gauges, quick status,
// power controls, update button, image drop zone). Pulled out of
// DropdownPanel.qml so it's just content - it doesn't know it lives in
// a dropdown, in DropDown, or in Panel. Use `DropDown { SystemDropdownContent { anchors.fill: parent } }`.
Item {
    id: root

    // Injected by whoever instantiates this (Panel, currently) - this
    // component intentionally doesn't reach into an outer `colors` id
    // the way the original DropdownPanel.qml silently did.
    property var colors

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        RowLayout {
            spacing: 5

            ColumnLayout {
                Layout.preferredWidth: 160
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
            }

            ColumnLayout {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                spacing: 10

                QuickStatusRow {
                    Layout.fillWidth: true
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 50
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
            spacing: 5
            UpdateButton {
                Layout.alignment: Qt.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                ImageDropZone {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
