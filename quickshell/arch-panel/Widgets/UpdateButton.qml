import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    property string scriptPath: Quickshell.env("HOME") + "/.config/arch-panel/scripts/update.sh"
    property bool running: false

    implicitWidth: 140
    implicitHeight: 34
    radius: 8
    color: mouseArea.pressed ? "#74c7ec" : (mouseArea.containsMouse ? "#89b4fa" : "#585b70")

    Behavior on color { ColorAnimation { duration: 100 } }

    RowLayout {
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.running ? "\uF110" : "\uF021"   // spinner / refresh glyph
            font.family: "Symbols Nerd Font"
            font.pixelSize: 13
            color: "#1e1e2e"

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
            color: "#1e1e2e"
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
