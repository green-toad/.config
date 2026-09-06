import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "Widgets"
import "Services"

PanelWindow {
    id: bar
    Colors { id: colors }

    // --- geometry -----------------------------------------------------
    property int barWidth: 800
    property int barHeight: 30
    property int dropdownHeight: 320
    property int dropdownWidth: 500
    property int dropdownX: 0

    property int outerRadius: 14
    property int dropdownRadius: 14
    property int notchRadius: 20

    property bool expanded: false

    // Purely visual animation value - drives QML painting only.
    // It must NEVER feed the window's implicitHeight (see below).
    property real animDropdownHeight: expanded ? dropdownHeight : 0
    Behavior on animDropdownHeight {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    anchors.top: true
    margins.top: 6

    // IMPORTANT: the window is allocated at its MAXIMUM possible size
    // once, and never resized again. Resizing an actual wlr-layer-shell
    // surface every animation frame forces a compositor reconfigure each
    // time, which is what causes the flicker / white-flash / judder on
    // open-close - not path/shape computation cost. Keeping the surface
    // a constant size and animating only the QML content inside it turns
    // the whole thing into ordinary GPU-composited repaints.
    implicitWidth: barWidth
    implicitHeight: barHeight + dropdownHeight

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: barHeight
    WlrLayershell.namespace: "arch-panel"

    exclusionMode: ExclusionMode.Normal

    // The window's real surface is always max-height, but only the
    // topRow + currently-revealed dropdown area should actually receive
    // clicks - everything else should pass through to whatever is behind
    // the panel. `mask` gives us a clickable region independent of the
    // surface's physical size.
    mask: Region { item: clickableArea }

    // Hyprland-specific hint: tell the compositor which pixels are
    // actually non-transparent right now, so it can skip compositing/
    // blurring the empty area below the collapsed dropdown. Optional,
    // but cheap and genuinely helps on weaker iGPUs.
    HyprlandWindow.visibleMask: Region { item: clickableArea }

    Timer {
        id: closeTimer
        interval: 800
        onTriggered: bar.expanded = false
    }

    function requestOpen() {
        closeTimer.stop()
        expanded = true
    }
    function requestClose() {
        closeTimer.restart()
    }

    Item {
        id: shellSurface
        anchors.fill: parent

        // Tracks exactly the currently-visible silhouette (bar + however
        // much of the dropdown is revealed right now). Used both for the
        // click mask above and to size the dropdown's own clip area.
        Item {
            id: clickableArea
            anchors.top: parent.top
            anchors.left: parent.left
            width: bar.barWidth
            height: bar.barHeight + bar.animDropdownHeight
        }

        NotchShape {
            id: shellShape
            anchors.top: parent.top
            anchors.left: parent.left

            barWidth: bar.barWidth
            barHeight: bar.barHeight
            dropdownWidth: bar.dropdownWidth
            dropdownX: bar.dropdownX
            dropdownHeight: bar.animDropdownHeight

            outerRadius: bar.outerRadius
            dropdownRadius: bar.dropdownRadius
            notchRadius: bar.notchRadius

            fillColor: colors.color4
            strokeColor: colors.border
            strokeWidth: 1
        }

        RowLayout {
            id: topRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: bar.barHeight
            spacing: 0

            Item {
                id: logoArea
                Layout.preferredWidth: 46
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    text: "\uF303"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 16
                    color: colors.color7
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: bar.requestOpen()
                    onExited: bar.requestClose()
                }
            }

            Item {
                anchors.centerIn: parent
                Layout.fillWidth: true
                Layout.fillHeight: true

                Workspaces {
                    anchors.centerIn: parent
                }
            }

            Item {
                Layout.preferredWidth: 220
                Layout.fillHeight: true

                SysTray {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Item {
            id: dropdown
            x: bar.dropdownX
            y: bar.barHeight
            width: bar.dropdownWidth
            height: bar.animDropdownHeight
            clip: true
            visible: bar.expanded || opacity > 0
            opacity: bar.expanded ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: 140 } }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: bar.requestOpen()
                onExited: bar.requestClose()
                onPressed: mouse.accepted = false
            }

            DropdownPanel {
                anchors.fill: parent
                anchors.margins: 10
            }
        }
    }
}
