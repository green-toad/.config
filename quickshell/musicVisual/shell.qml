import Quickshell
import Quickshell.Io
import QtQuick

Scope
{
    id: root

    property string music

    Variants
    {
        model: Quickshell.screens;

        PanelWindow
        {
            required property var modelData
            screen: modelData

            aboveWindows: false
            
            Colors { id: colors}

            color: Qt.rgba(255, 255, 255, 0)

            width: screen.width
            height: screen.height

            Text
            {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.music
                font.pixelSize: 150
                color: Qt.rgba(255, 255, 255, 1)
            }
        }
    }

    Process 
    {
        id: cavaProc

        command: ["cava"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.music = this.text
        }
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: cavaProc.running = true
    }
}