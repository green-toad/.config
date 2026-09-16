import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "Widgets"
import "Services"
import "DropDownContents"

PanelWindow {
    id: bar
    Colors { id: colors }

    property int barWidth: 800
    property int barHeight: 30

    property int outerRadius: 14
    property int notchRadius: 20
    property int dropdownRadius: 14

    readonly property real maxDropdownHeight: Math.max(
        systemDropdown.dropdownHeight,
        appLauncher.dropdownHeight
    )

    anchors.top: true
    margins.top: 6

    implicitWidth: barWidth
    implicitHeight: barHeight + maxDropdownHeight

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: barHeight
    WlrLayershell.namespace: "arch-panel"

    WlrLayershell.keyboardFocus: appLauncher.expanded
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Normal

    mask: Region { item: clickableArea }

    HyprlandWindow.visibleMask: Region { item: clickableArea }

    IpcHandler {
        target: "launcher"

        function toggle(): void { 
            systemDropdown.requestHardClose()
            appLauncher.toggle() 
            }
        function open(): void { 
            systemDropdown.requestHardClose()
            appLauncher.requestOpen() 
            }
        function close(): void { 
            systemDropdown.requestHardClose()
            appLauncher.requestClose() 
            }
    }

    Item {
        id: shellSurface
        anchors.fill: parent

        Item {
            id: clickableArea
            anchors.top: parent.top
            anchors.left: parent.left
            width: bar.barWidth
            height: bar.barHeight + Math.max(
                systemDropdown.animHeight,
                appLauncher.animHeight,
                0)
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

            dropdowns: [
                { x: systemDropdown.dropdownX, width: systemDropdown.dropdownWidth, height: systemDropdown.animHeight },
                { x: appLauncher.dropdownX, width: appLauncher.dropdownWidth, height: appLauncher.animHeight }
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
                        if (logoHover.hovered){
                            appLauncher.requestHardClose()
                            systemDropdown.requestOpen()
                        }else{
                            appLauncher.requestHardClose()
                            systemDropdown.requestClose()
                        }
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

        DropDown {
            id: appLauncher
            originY: bar.barHeight
            dropdownX: (bar.barWidth - dropdownWidth) / 2
            dropdownWidth: 500
            dropdownHeight: 320
            closeDelay: 100
            // closeOnHoverLeave: false

            AppLauncherContent {
                anchors.fill: parent
                colors: colors
                onAppLaunched: appLauncher.requestClose()
            }
        }
    }
}
