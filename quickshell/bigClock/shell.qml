import Quickshell
import Quickshell.Io
import QtQuick

import "ClockWidget"

Scope
{
    Time { id: timeSource }
    Variants
    {
        model: Quickshell.screens;

        PanelWindow
        {
            required property var modelData
            screen: modelData

            aboveWindows: false
            
            Colors { id: colors}

            implicitWidth: screen.width
            implicitHeight: screen.height

            color: Qt.rgba(255, 255, 255, 0)

            Clock 
            {
                anchors.leftMargin: screen.width / 25
                font.pixelSize: screen.width / 7
                text: timeSource.time
                color: colors.color11
                styleColor: colors.color12
            }
            /*
            Text {
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 24
                text: "Bars count: " + cava.bars.length + " | Values: " + cava.bars.join(", ")
            }

            Row 
            {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }
                spacing: 4

                Repeater {
                    model: cava.bars.length > 0 ? cava.bars : []

                    Rectangle {
                        width: Math.max(6, (parent.width - (model.count-1) * parent.spacing) / model.count)
                        height: parent.height * (modelData / 100.0)
                        color: colors.color11
                        radius: 2
                        anchors.bottom: parent.bottom
                    }
                }
            }
            */
        }
    }
}