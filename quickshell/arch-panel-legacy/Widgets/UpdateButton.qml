import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"

Rectangle {
    id: root

    property string scriptPath: Quickshell.env("HOME") + "/.config/scripts/genColor.sh"
    property bool running: false

    Colors { id: colors }

    implicitWidth: 140
    implicitHeight: 34
    radius: 8
    color: mouseArea.pressed ? colors.color12 : (mouseArea.containsMouse ? colors.color7 : colors.color10)

    Behavior on color { ColorAnimation { duration: 100 } }

    RowLayout {
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.running ? "\uF110" : "\uF021"
            font.family: "Symbols Nerd Font"
            font.pixelSize: 13
            color: colors.color13

            RotationAnimation on rotation {
                running: root.running
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
            }
        }

        Text {
            text: root.running ? "Обновление..." : "Обновить"
            color: colors.color15
            font.pixelSize: 12
            font.bold: true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !root.running
        onClicked: {
            root.running = true
            updateProc.running = true
        }
    }

    Process {
        id: updateProc
        command: ["bash", root.scriptPath]
        onExited: (exitCode, exitStatus) => {
            root.running = false
        }
    }
}
