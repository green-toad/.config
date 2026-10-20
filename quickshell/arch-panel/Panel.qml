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

// Всё живёт в ОДНОМ окне (bar) и рисуется одним силуэтом (NotchShape):
// верхняя "таблетка" с рабочими столами, из неё разворачиваются лаунчер
// и дропдауны бара. Дропдауны бара могут рисоваться поверх лаунчера -
// открывающийся всегда выше закрывающегося (см. DropDown.raise()).
//
// Клавиатура: лаунчер берёт Exclusive-фокус окна, пока открыт. Раньше из-за
// этого на Hyprland приходил синтетический hover в точку (0,0) окна и
// Super+D случайно открывал системное меню под логотипом. Поэтому после
// открытия лаунчера на короткое время (hoverGuard) hover по иконкам бара
// игнорируется.
//  - иконки бара: только курсор (hover открывает дропдаун);
//  - лаунчер: хоткей/IPC (super+D -> `qs ipc call launcher toggle`) или Escape.
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

    // Лаунчер: ширина, на которую "растягивается" таблетка, и состояние
    property int launcherWidth: 500
    property bool launcherWanted: false
    // true пока лаунчер открыт ИЛИ ещё сворачивается: ширина бара держится
    // до конца анимации высоты, потом сжимается обратно
    readonly property bool launcherShown: launcherWanted || launcherPopup.animHeight > 0.5
    property bool hoverGuard: false

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
        if (shell.hoverGuard) return
        for (const d of [systemDropdown, wifiDropdown, bluetoothDropdown, audioDropdown]) {
            if (d !== target) d.requestHardClose()
        }
        target.requestOpen()
    }

    function closeBarDropdowns() {
        systemDropdown.requestHardClose()
        wifiDropdown.requestHardClose()
        bluetoothDropdown.requestHardClose()
        audioDropdown.requestHardClose()
    }

    function openLauncher() {
        if (launcherWanted) return
        closeBarDropdowns()
        launcherWanted = true
        hoverGuard = true
        hoverGuardTimer.restart()
        // сначала бар растягивается до ширины лаунчера, затем он падает вниз
        launcherOpenTimer.interval = barRoot.width >= launcherWidth - 1 ? 1 : 140
        launcherOpenTimer.restart()
    }
    function closeLauncher() {
        launcherWanted = false
        launcherOpenTimer.stop()
        launcherPopup.requestHardClose()
    }
    function toggleLauncher() {
        if (launcherWanted) closeLauncher()
        else openLauncher()
    }

    Timer {
        id: launcherOpenTimer
        onTriggered: if (shell.launcherWanted) launcherPopup.requestOpen()
    }
    Timer {
        id: hoverGuardTimer
        interval: 450
        onTriggered: shell.hoverGuard = false
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void { shell.toggleLauncher() }
        function open(): void { shell.openLauncher() }
        function close(): void { shell.closeLauncher() }
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
            audioDropdown.dropdownHeight,
            launcherPopup.dropdownHeight
        )

        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: shell.barHeight
        WlrLayershell.namespace: "arch-panel"
        WlrLayershell.keyboardFocus: shell.launcherWanted
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.OnDemand

        exclusionMode: ExclusionMode.Normal

        mask: Region { item: barRoot }
        HyprlandWindow.visibleMask: Region { item: barRoot }

        Item {
            id: barRoot
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            // полная ширина при наведении; с лаунчером - ровно под лаунчер;
            // иначе компактная таблетка под рабочие столы
            width: shell.expanded ? shell.expandedWidth
                 : (shell.launcherShown ? Math.max(shell.launcherWidth, shell.collapsedWidth)
                                        : shell.collapsedWidth)
            height: shell.barHeight + Math.max(
                systemDropdown.animHeight,
                wifiDropdown.animHeight,
                bluetoothDropdown.animHeight,
                audioDropdown.animHeight,
                launcherPopup.animHeight,
                0)

            Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            // Разворачивает панель только наведение на саму верхнюю полоску,
            // а не на лаунчер/дропдауны под ней
            Item {
                id: topStrip
                width: parent.width
                height: shell.barHeight

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

                z: -1

                dropdowns: [
                    { x: launcherPopup.dropdownX, width: launcherPopup.dropdownWidth, height: launcherPopup.animHeight },
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

            // Лаунчер: центрирован под таблеткой. Ширина бара = ширина лаунчера -
            // боковые стороны сливаются с баром без выемок; если бар шире
            // (панель развёрнута) - появляются обычные выемки.
            DropDown {
                id: launcherPopup
                originY: shell.barHeight
                dropdownWidth: Math.min(shell.launcherWidth, barRoot.width)
                dropdownX: Math.round((barRoot.width - dropdownWidth) / 2)
                dropdownHeight: 320
                closeDelay: 0

                closeOnHoverLeave: false
                hoverOpens: false
                raiseOnOpen: false

                backgroundColor: colors.color4
                cornerRadius: shell.dropdownRadius

                onExpandedChanged: if (!expanded) shell.launcherWanted = false

                AppLauncherContent {
                    anchors.fill: parent
                    colors: colors
                    onAppLaunched: launcherPopup.requestClose()
                }
            }

            DropDown {
                id: systemDropdown
                backgroundColor: colors.color4
                borderColor: colors.border
                cornerRadius: shell.dropdownRadius
                takeFocus: false
                showBorder: launcherPopup.animHeight > 1
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
                backgroundColor: colors.color4
                borderColor: colors.border
                cornerRadius: shell.dropdownRadius
                takeFocus: false
                showBorder: launcherPopup.animHeight > 1
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
                backgroundColor: colors.color4
                borderColor: colors.border
                cornerRadius: shell.dropdownRadius
                takeFocus: false
                showBorder: launcherPopup.animHeight > 1
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
                backgroundColor: colors.color4
                borderColor: colors.border
                cornerRadius: shell.dropdownRadius
                takeFocus: false
                showBorder: launcherPopup.animHeight > 1
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
}
