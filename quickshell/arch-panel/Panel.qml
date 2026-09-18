import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "Widgets"
import "Services" as Services
import "DropDownContents"

// Корень теперь Scope, а не PanelWindow: лаунчер вынесен в СВОЁ отдельное
// Wayland-окно (launcherWindow), физически изолированное от бара (bar).
//
// Почему: WlrLayershell.keyboardFocus - это свойство всей поверхности
// окна. Раньше лаунчер и системный дропдаун жили в одном PanelWindow, и
// любой keyboard-grab на этой поверхности (Exclusive, а также
// HyprlandFocusGrab) на Hyprland задевает hover-доставку у соседних
// попапов в ТОЙ ЖЕ surface - грэб порождает синтетический pointer-focus
// у истока поверхности (0,0), а там как раз иконка логотипа, поэтому
// Super+D внезапно триггерил системное меню. Разные окна = разные
// surfaces = грэб физически не может задеть бар.
//
// Разделение ролей:
//  - bar: ТОЛЬКО курсор. Никаких хоткеев, никогда не просит клавиатуру.
//    Системный / Wi-Fi / Bluetooth дропдауны открываются по наведению
//    на свою иконку и закрываются, когда курсор уходит с попапа.
//  - launcherWindow: ТОЛЬКО клавиатура/IPC. Открытие/закрытие - хоткей
//    (super+D -> `qs ipc call launcher toggle`) или Escape. Курсор внутри
//    нужен только чтобы кликнуть по приложению - никакого hover-open/close.
Scope {
    id: shell
    Colors { id: colors }

    property int barWidth: 800
    property int barHeight: 30

    property int outerRadius: 14
    property int notchRadius: 20
    property int dropdownRadius: 14

    function openBarDropdown(target) {
        launcherWindow.closeLauncher()
        for (const d of [systemDropdown, wifiDropdown, bluetoothDropdown]) {
            if (d !== target) d.requestHardClose()
        }
        target.requestOpen()
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            systemDropdown.requestHardClose()
            wifiDropdown.requestHardClose()
            bluetoothDropdown.requestHardClose()
            launcherWindow.toggleLauncher()
        }
        function open(): void {
            systemDropdown.requestHardClose()
            wifiDropdown.requestHardClose()
            bluetoothDropdown.requestHardClose()
            launcherWindow.openLauncher()
        }
        function close(): void {
            launcherWindow.closeLauncher()
        }
    }

    PanelWindow {
        id: bar

        anchors.top: true
        margins.top: 6

        implicitWidth: shell.barWidth
        implicitHeight: shell.barHeight + Math.max(
            systemDropdown.dropdownHeight,
            wifiDropdown.dropdownHeight,
            bluetoothDropdown.dropdownHeight
        )

        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: shell.barHeight
        WlrLayershell.namespace: "arch-panel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        exclusionMode: ExclusionMode.Normal

        mask: Region { item: clickableArea }
        HyprlandWindow.visibleMask: Region { item: clickableArea }

        Item {
            id: shellSurface
            anchors.fill: parent

            Item {
                id: clickableArea
                anchors.top: parent.top
                anchors.left: parent.left
                width: shell.barWidth
                height: shell.barHeight + Math.max(
                    systemDropdown.animHeight,
                    wifiDropdown.animHeight,
                    bluetoothDropdown.animHeight,
                    0)
            }

            NotchShape {
                id: shellShape
                anchors.top: parent.top
                anchors.left: parent.left

                barWidth: shell.barWidth
                barHeight: shell.barHeight
                outerRadius: shell.outerRadius
                notchRadius: shell.notchRadius
                dropdownRadius: shell.dropdownRadius

                dropdowns: [
                    { x: systemDropdown.dropdownX, width: systemDropdown.dropdownWidth, height: systemDropdown.animHeight },
                    { x: wifiDropdown.dropdownX, width: wifiDropdown.dropdownWidth, height: wifiDropdown.animHeight },
                    { x: bluetoothDropdown.dropdownX, width: bluetoothDropdown.dropdownWidth, height: bluetoothDropdown.animHeight }
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
                height: shell.barHeight
                spacing: 5

                // logo
                Item {
                    id: logoArea
                    Layout.preferredWidth: 32
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
                            if (logoHover.hovered) shell.openBarDropdown(systemDropdown)
                            else systemDropdown.requestClose()
                        }
                    }
                }
                // wifi
                Item {
                    Layout.preferredWidth: 32
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        text: "\uF1EB"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 14
                        color: Services.WifiService.wifiEnabled ? colors.color7 : colors.color5
                    }

                    HoverHandler {
                        id: wifiHover
                        onHoveredChanged: {
                            if (wifiHover.hovered) shell.openBarDropdown(wifiDropdown)
                            else wifiDropdown.requestClose()
                        }
                    }
                }
                // bluetooth
                Item {
                    Layout.preferredWidth: 32
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        text: "\uF294"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 14
                        color: Services.BluetoothService.enabled ? colors.color7 : colors.color5
                    }

                    HoverHandler {
                        id: btHover
                        onHoveredChanged: {
                            if (btHover.hovered) shell.openBarDropdown(bluetoothDropdown)
                            else bluetoothDropdown.requestClose()
                        }
                    }
                }
                // workspaces
                Item {
                    anchors.centerIn: parent
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Workspaces {
                        anchors.centerIn: parent
                    }
                }
                //tray
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
                originY: shell.barHeight
                dropdownX: 0
                dropdownWidth: 360
                dropdownHeight: 260

                SystemDropdownContent {
                    anchors.fill: parent
                    colors: colors
                }
            }

            DropDown {
                id: wifiDropdown
                originY: shell.barHeight
                dropdownX: 50
                dropdownWidth: 340
                dropdownHeight: 320

                WifiDropdownContent {
                    anchors.fill: parent
                    colors: colors
                }
            }

            DropDown {
                id: bluetoothDropdown
                originY: shell.barHeight
                dropdownX: 100
                dropdownWidth: 340
                dropdownHeight: 320

                BluetoothDropdownContent {
                    anchors.fill: parent
                    colors: colors
                }
            }
        }
    }

    PanelWindow {
        id: launcherWindow

        anchors.top: true
        margins.top: shell.barHeight + 6

        implicitWidth: launcherPopup.dropdownWidth
        implicitHeight: launcherPopup.dropdownHeight

        color: "transparent"
        visible: launcherPopup.expanded || launcherPopup.opacity > 0

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: 0
        WlrLayershell.namespace: "arch-launcher"

        WlrLayershell.keyboardFocus: launcherPopup.expanded
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        exclusionMode: ExclusionMode.Ignore
        mask: Region { item: launcherPopup }

        function toggleLauncher() { launcherPopup.toggle() }
        function openLauncher() { launcherPopup.requestOpen() }
        function closeLauncher() { launcherPopup.requestHardClose() }

        Rectangle {
            anchors.fill: launcherPopup
            radius: shell.dropdownRadius
            color: colors.color4
            border.color: colors.border
            border.width: 1
        }

        DropDown {
            id: launcherPopup
            originY: 0
            dropdownX: 0
            dropdownWidth: 500
            dropdownHeight: 320
            closeDelay: 0

            closeOnHoverLeave: false

            AppLauncherContent {
                anchors.fill: parent
                colors: colors
                onAppLaunched: launcherPopup.requestClose()
            }
        }
    }
}
