import QtQuick
import QtQuick.Layouts
import "../Widgets"
import "../Services" as Services

// Звук: регулятор громкости + плеер (пауза, треки, перемотка).
Item {
    id: root

    property var colors

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22

                Text {
                    anchors.centerIn: parent
                    text: Services.AudioService.muted ? "\uF026" : "\uF028"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 14
                    color: Services.AudioService.muted ? root.colors.color14 : root.colors.color7
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.AudioService.toggleMute()
                }
            }

            StyledSlider {
                Layout.fillWidth: true
                from: 0
                to: 1.5
                value: Services.AudioService.volume
                onMoved: Services.AudioService.setVolume(value)
            }

            Text {
                text: Math.round(Services.AudioService.volume * 100) + "%"
                color: root.colors.color15
                font.pixelSize: 11
                Layout.preferredWidth: 32
                horizontalAlignment: Text.AlignRight
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.colors.color6
            opacity: 0.4
        }

        PlayerPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            colors: root.colors
        }
    }
}
