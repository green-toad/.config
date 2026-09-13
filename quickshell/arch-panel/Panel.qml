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

    // --- bar geometry ---------------------------------------------
    property int barWidth: 800
    property int barHeight: 30

    property int outerRadius: 14
    property int notchRadius: 20
    property int dropdownRadius: 14

    // The window is allocated once at its MAXIMUM possible size and
    // never resized again (see note below). That max is the tallest
    // any single dropdown is allowed to grow to - add every dropdown's
    // `dropdownHeight` here as you add dropdowns.
    readonly property real maxDropdownHeight: Math.max(
        systemDropdown.dropdownHeight
        // , otherDropdown.dropdownHeight
    )

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
    implicitHeight: barHeight + maxDropdownHeight

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: barHeight
    WlrLayershell.namespace: "arch-panel"

    exclusionMode: ExclusionMode.Normal

    // The window's real surface is always max-height, but only the
    // topRow + however much of the tallest open dropdown is revealed
    // right now should actually receive clicks - everything else
    // passes through to whatever is behind the panel. `mask` gives us
    // a clickable region independent of the surface's physical size.
    mask: Region { item: clickableArea }

    // Hyprland-specific hint: tell the compositor which pixels are
    // actually non-transparent right now, so it can skip compositing/
    // blurring the empty area below the collapsed dropdown(s).
    HyprlandWindow.visibleMask: Region { item: clickableArea }

    Item {
        id: shellSurface
        anchors.fill: parent

        // Tracks exactly the currently-visible silhouette (bar +
        // however much of the tallest open dropdown is revealed right
        // now). Used both for the click mask above and to size
        // NotchShape's clip area.
        Item {
            id: clickableArea
            anchors.top: parent.top
            anchors.left: parent.left
            width: bar.barWidth
            height: bar.barHeight + Math.max(
                systemDropdown.animHeight
                // , otherDropdown.animHeight
                , 0)
        }

        NotchShape {
            id: shellShape
            anchors.top: parent.top
            anchors.left: parent.left

            barWidth: bar.barWidth
            barHeight: bar.barHeight
            outerRadius: bar.outerRadius
            notchRadius: bar.notchRadius
            dropdownRadius: bar.dropdownRadius

            // Every currently-open (or animating-closed) dropdown gets
            // its own notch here. Adding a second dropdown to the bar
            // is just adding its entry to this list - nothing else in
            // NotchShape needs to change.
            dropdowns: [
                { x: systemDropdown.dropdownX, width: systemDropdown.dropdownWidth, height: systemDropdown.animHeight }
                // , { x: otherDropdown.dropdownX, width: otherDropdown.dropdownWidth, height: otherDropdown.animHeight }
            ]

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

                HoverHandler {
                    id: logoHover
                    onHoveredChanged: {
                        if (logoHover.hovered)
                            systemDropdown.requestOpen()
                        else
                            systemDropdown.requestClose()
                    }
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

        // --- dropdowns --------------------------------------------
        // Each one is fully self-contained (own geometry, own hover/
        // close timing) - Panel just positions it, wires up a trigger,
        // and lists it in NotchShape.dropdowns above.
        //
        // To add a second dropdown:
        //   1. Add another `DropDown { ... }` block below with its own id.
        //   2. Give it a trigger that calls its requestOpen()/requestClose().
        //   3. Uncomment its entry in maxDropdownHeight, clickableArea and
        //      NotchShape.dropdowns above.
        DropDown {
            id: systemDropdown
            originY: bar.barHeight
            dropdownX: 0
            dropdownWidth: 500
            dropdownHeight: 320

            SystemDropdownContent {
                anchors.fill: parent
                colors: colors
            }
        }
    }
}
