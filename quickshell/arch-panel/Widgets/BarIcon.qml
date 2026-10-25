import QtQuick

// Иконка бара: по наведению просит открыть дропдаун.
Item {
    id: icon

    property int barHeight: 30
    property string glyph: ""
    property int glyphSize: 14
    property color glyphColor: "white"
    property string dropdown: ""

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
}
