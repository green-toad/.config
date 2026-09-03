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

    // --- geometry -----------------------------------------------------
    property int barWidth: 800
    property int barHeight: 30
    property int dropdownHeight: 320

    anchors.top: true
    // centered horizontally at the top
    margins.top: 6

    implicitWidth: barWidth
    implicitHeight: expanded ? barHeight + dropdownHeight : barHeight

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: barHeight
    WlrLayershell.namespace: "arch-panel"

    // exclusive zone only for the bar itself, dropdown overlays content
    exclusionMode: ExclusionMode.Normal

    property bool expanded: false

    // hide dropdown shortly after mouse leaves either the logo or the popup
    Timer {
        id: closeTimer
        interval: 250
        onTriggered: bar.expanded = false
    }

    function requestOpen() {
        closeTimer.stop()
        expanded = true
    }
    function requestClose() {
        closeTimer.restart()
    }

    // ====================================================================
    // Root visual: one continuous "capsule" that grows downward
    // ====================================================================
    Rectangle {
        id: shellSurface
        anchors.fill: parent
        color: "#1e1e2e"
        radius: 14
        border.color: "#313244"
        border.width: 1
        clip: true

        Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // ---------------------------------------------------------------
        // Top row (always visible) — the 800x30 bar content
        // ---------------------------------------------------------------
        RowLayout {
            id: topRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: bar.barHeight
            spacing: 0

            // ---- LEFT: distro logo (hover trigger) ------------------
            Item {
                id: logoArea
                Layout.preferredWidth: 46
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    text: "\uF303"           // Nerd Font Arch logo glyph
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 16
                    color: "#89b4fa"
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: bar.requestOpen()
                    onExited: bar.requestClose()
                }
            }

            // ---- CENTER: workspaces -----------------------------------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Workspaces {
                    anchors.centerIn: parent
                }
            }

            // ---- RIGHT: system tray -------------------------------------
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

        // ---------------------------------------------------------------
        // Dropdown content, revealed under the top row
        // ---------------------------------------------------------------
        Item {
            id: dropdown
            anchors.top: topRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: bar.expanded || opacity > 0
            opacity: bar.expanded ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: 140 } }

            MouseArea {
                // keep it open while hovering the dropdown itself
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
