import Quickshell
import Quickshell.Io
import QtQuick

Scope
{
    id: root
    
    readonly property string time: {
        Qt.formatDateTime(clock.date, "hh\nmm")
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Variants
    {
        model: Quickshell.screens;

        PanelWindow
        {
            required property var modelData
            screen: modelData

            aboveWindows: false
            
            Colors { id: colors}

            width: screen.width * (8 / 9)
            height: screen.height / 2

            color: Qt.rgba(255, 255, 255, 0)

            Text
            {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: screen.width / 8
                text: root.time
                color: colors.color11
                style: Text.Outline
                styleColor: colors.color12
            }
        }
    }
}