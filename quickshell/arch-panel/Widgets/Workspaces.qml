import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../"

Row {
    id: root
    spacing: 10

    Colors { id: colors }

    readonly property var hyprWorkspaces: Hyprland.workspaces
    readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    property int visibleCount: 10

    Repeater {
        model: root.visibleCount
        
        delegate: Rectangle {
            id: dot
            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: wsId === root.activeId
            readonly property bool exists: {
                for (let i = 0; i < root.hyprWorkspaces.values.length; i++) {
                    if (root.hyprWorkspaces.values[i].id === wsId) return true
                }
                return false
            }

            width: active ? 18 : 8
            height: 8
            radius: 4
            color: active ? colors.color9 : (exists ? colors.color6 : colors.color0)

            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }

            MouseArea {
                anchors.fill: parent
                anchors.margins: 0
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + dot.wsId)
            }
        }
    }
}
