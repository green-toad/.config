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

    // Панель в покое - компактная "таблетка" ровно под рабочие столы.
    // При наведении разворачивается до expandedWidth (иконки слева, трей справа).
    property int expandedWidth: 800
    property int collapsedPadding: 18
    readonly property real collapsedWidth: workspaces.width + collapsedPadding * 2
    property int barHeight: 30
    property bool expanded: false

    // Нельзя сворачиваться, пока открыт любой дропдаун или меню трея
    readonly property bool busy: systemDropdown.expanded || wifiDropdown.expanded
                                 || bluetoothDropdown.expanded || audioDropdown.expanded
                                 || tray.menuOpen
    onBusyChanged: if (!busy) collapseTimer.restart()

    Timer {
        id: collapseTimer
        interval: 350
        onTriggered: if (!barHover.hovered && !shell.busy) shell.expanded = false
    }

    property int outerRadius: 14
    property int notchRadius: 20
    property int dropdownRadius: 14

    function openBarDropdown(target) {
        launcherWindow.closeLauncher()
        for (const d of [systemDropdown, wifiDropdown, bluetoothDropdown, audioDropdown]) {
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
            audioDropdown.requestHardClose()
            launcherWindow.toggleLauncher()
        }
        function open(): void {
            systemDropdown.requestHardClose()
            wifiDropdown.requestHardClose()
            bluetoothDropdown.requestHardClose()
            audioDropdown.requestHardClose()
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

        // Окно всегда максимальной ширины (по центру, т.к. якорь только сверху):
        // ресайзить Wayland-поверхность на каждом кадре анимации - дорого.
        // Сворачивается/разворачивается только видимая часть (barRoot),
        // а mask отдаёт события лишь ей.
        implicitWidth: shell.expandedWidth
        implicitHeight: shell.barHeight + Math.max(
            systemDropdown.dropdownHeight,
            wifiDropdown.dropdownHeight,
            bluetoothDropdown.dropdownHeight,
            audioDropdown.dropdownHeight
        )

        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: shell.barHeight
        WlrLayershell.namespace: "arch-panel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        exclusionMode: ExclusionMode.Normal

        mask: Region { item: barRoot }
        HyprlandWindow.visibleMask: Region { item: barRoot }

        Item {
            id: barRoot
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            width: shell.expanded ? shell.expandedWidth : shell.collapsedWidth
            height: shell.barHeight + Math.max(
                systemDropdown.animHeight,
                wifiDropdown.animHeight,
                bluetoothDropdown.animHeight,
                audioDropdown.animHeight,
                0)

            Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            HoverHandler {
                id: barHover
                onHoveredChanged: {
                    if (hovered) {
                        collapseTimer.stop()
                        shell.expanded = true
                    } else {
                        collapseTimer.restart()
                    }
                }
            }

            NotchShape {
                id: shellShape
                anchors.top: parent.top
                anchors.left: parent.left

                barWidth: barRoot.width
                barHeight: shell.barHeight
                outerRadius: shell.outerRadius
                notchRadius: shell.notchRadius
                dropdownRadius: shell.dropdownRadius

                dropdowns: [
                    { x: systemDropdown.dropdownX, width: systemDropdown.dropdownWidth, height: systemDropdown.animHeight },
                    { x: wifiDropdown.dropdownX, width: wifiDropdown.dropdownWidth, height: wifiDropdown.animHeight },
                    { x: bluetoothDropdown.dropdownX, width: bluetoothDropdown.dropdownWidth, height: bluetoothDropdown.animHeight },
                    { x: audioDropdown.dropdownX, width: audioDropdown.dropdownWidth, height: audioDropdown.animHeight }
                ]

                fillColor: colors.color4
                strokeColor: colors.border
                strokeWidth: 1
            }

            // Иконка слева. Видна только в развёрнутой панели.
            component BarIcon: Item {
                id: icon
                property string glyph
                property int glyphSize: 14
                property color glyphColor: "white"
                signal entered()

                width: 46
                height: parent ? parent.height : 30

                Text {
                    anchors.centerIn: parent
                    text: icon.glyph
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: icon.glyphSize
                    color: icon.glyphColor
                }

                HoverHandler {
                    onHoveredChanged: if (hovered) icon.entered()
                }
            }

            Row {
                id: leftIcons
                anchors.top: parent.top
                anchors.left: parent.left
                height: shell.barHeight
                spacing: 1

                opacity: shell.expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 160 } }

                // logo
                // (systemDropdown.requestClose() при уходе курсора - зло во плоти, не возвращать)
                BarIcon {
                    glyph: "\uF303"
                    glyphSize: 16
                    glyphColor: colors.color7
                    onEntered: shell.openBarDropdown(systemDropdown)
                }
                // wifi
                BarIcon {
                    glyph: "\uF1EB"
                    glyphColor: Services.WifiService.wifiEnabled ? colors.color7 : colors.color5
                    onEntered: shell.openBarDropdown(wifiDropdown)
                }
                // bluetooth
                BarIcon {
                    glyph: "\uF294"
                    glyphColor: Services.BluetoothService.enabled ? colors.color7 : colors.color5
                    onEntered: shell.openBarDropdown(bluetoothDropdown)
                }
                // звук
                BarIcon {
                    glyph: Services.AudioService.muted ? "\uF026" : "\uF028"
                    glyphColor: Services.AudioService.muted ? colors.color5 : colors.color7
                    onEntered: shell.openBarDropdown(audioDropdown)
                }
            }

            // workspaces - всегда видны, по центру; от их ширины считается
            // размер свёрнутой панели
            Workspaces {
                id: workspaces
                anchors.horizontalCenter: parent.horizontalCenter
                y: (shell.barHeight - height) / 2
            }

            // tray - только в развёрнутой панели
            SysTray {
                id: tray
                anchors.right: parent.right
                anchors.rightMargin: 12
                y: (shell.barHeight - height) / 2

                opacity: shell.expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
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
                dropdownHeight: Services.WifiService.wifiEnabled ? 320 : 60
                closeDelay: 10

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
                dropdownHeight: Services.BluetoothService.enabled ? 320 : 60
                closeDelay: 10

                BluetoothDropdownContent {
                    anchors.fill: parent
                    colors: colors
                }
            }

            DropDown {
                id: audioDropdown
                originY: shell.barHeight
                dropdownX: 150
                dropdownWidth: 340
                dropdownHeight: 200
                closeDelay: 10

                AudioDropdownContent {
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
