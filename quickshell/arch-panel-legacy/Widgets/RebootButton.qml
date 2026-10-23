import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"

Rectangle {
    id: root
    property bool running: false

    Colors { id: colors }

    implicitWidth: 37
    implicitHeight: 37
    radius: 10
    color: mouseArea.pressed ? colors.color12 : (mouseArea.containsMouse ? colors.color7 : colors.color10)

    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
        anchors.centerIn: parent
        text: root.running ? "\uF110" : "\uF021"
        font.family: "Symbols Nerd Font"
        font.pixelSize: 13
        color: colors.color13
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
        command: ["reboot"]
        onExited: (exitCode, exitStatus) => {
            root.running = false
        }
    }
}
