import QtQuick
import Quickshell
import Quickshell.Io
import "../"

Rectangle {
    id: root
    Colors { id: colors }

    property string scriptPath: Quickshell.env("HOME") + "/.config/scripts/genStatColor.sh"

    property bool hovering: false
    property string lastFile: ""
    property string statusText: "Перетащите изображение сюда"

    color: hovering ? colors.color8 : colors.color9
    radius: 10
    border.width: 2
    border.color: hovering ? colors.color14 : colors.color2

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Column {
        anchors.centerIn: parent
        spacing: 4
        width: parent.width - 16

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "\uF03E"
            font.family: "Symbols Nerd Font"
            font.pixelSize: 20
            color: colors.color5
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.statusText
            color: "#a6adc8"
            font.pixelSize: 10
        }
    }

    DropArea {
        anchors.fill: parent
        onEntered: drag => { root.hovering = true }
        onExited: root.hovering = false

        onDropped: drop => {
            root.hovering = false
            let path = ""
            if (drop.hasUrls && drop.urls.length > 0) {
                path = drop.urls[0].toString().replace("file://", "")
            } else if (drop.hasText) {
                path = drop.text.trim()
            }

            if (path.length === 0) return

            root.lastFile = path
            root.statusText = "Обработка: " + path.split("/").pop()
            runScript.command = ["bash", root.scriptPath, path]
            runScript.running = true
        }
    }

    Process {
        id: runScript
        onExited: (exitCode, exitStatus) => {
            root.statusText = exitCode === 0
                ? "Готово: " + root.lastFile.split("/").pop()
                : "Ошибка при обработке файла"
        }
    }
}
