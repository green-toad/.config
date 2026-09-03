import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

Row {
    id: workspaceRow
    anchors.centerIn: parent
    spacing: 7

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            width: 20
            height: 20
            radius: 10
            color: index === Hyprland.currentWorkspace ? "#FFFFFF" : "#888888"
            border.color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Hyprland.currentWorkspace = index
                }
            }
        }
    }
}