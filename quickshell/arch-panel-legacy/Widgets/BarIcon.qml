import QtQuick
import Quickshell

// Иконка бара: по наведению просит открыть дропдаун, по клику (если задана
// command) запускает команду.
Item {
    id: icon

    property int barHeight: 30
    property string glyph: ""
    property int glyphSize: 14
    property color glyphColor: "white"
    property string dropdown: ""
    property var command: []

    signal triggered(string name)

    implicitWidth: 46
    width: 46
    height: barHeight

    Text {
        anchors.centerIn: parent
        text: icon.glyph
        font.family: "Symbols Nerd Font"
        font.pixelSize: icon.glyphSize
        color: icon.glyphColor
    }

    HoverHandler {
        onHoveredChanged: if (hovered && icon.dropdown !== "") icon.triggered(icon.dropdown)
    }

    MouseArea {
        anchors.fill: parent
        enabled: icon.command && icon.command.length > 0
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: Quickshell.execDetached(icon.command)
    }
}
