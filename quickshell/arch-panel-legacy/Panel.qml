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
// верхняя "таблетка", из неё разворачиваются лаунчер и дропдауны бара.
// Дропдауны могут рисоваться поверх лаунчера - открывающийся всегда выше
// закрывающегося (см. DropDown.raise()).
//
// Состав бара и содержимое дропдаунов берутся из config.lua
// (Services/Config.qml): виджеты бара - Widgets/BarWidget.qml,
// блоки дропдаунов - DropDownContents/Block.qml.
//
// Клавиатура: лаунчер берёт Exclusive-фокус окна, пока открыт. Раньше из-за
// этого на Hyprland приходил синтетический hover в точку (0,0) окна и
// Super+D случайно открывал системное меню под логотипом. Поэтому после
// открытия лаунчера на короткое время (hoverGuard) hover по иконкам бара
// игнорируется.
//  - иконки бара: только курсор (hover открывает дропдаун);
//  - лаунчер: хоткей/IPC (super+D -> `qs ipc call launcher toggle`) или Escape;
//  - `qs ipc call panel reload` - перечитать config.lua.
Scope {
    id: shell
    Colors { id: colors }

    // --- из конфига ------------------------------------------------------
    readonly property var barCfg: Services.Config.bar
    readonly property int barHeight: barCfg.height ?? 30
    readonly property int expandedWidth: barCfg.expandedWidth ?? 800
    readonly property int collapsedPadding: barCfg.collapsedPadding ?? 18
    readonly property int launcherWidth: Services.Config.launcher.width ?? 500
    readonly property int launcherHeight: Services.Config.launcher.height ?? 320

    // Панель в покое - компактная "таблетка" ровно под центральную зону
    // (по умолчанию рабочие столы). При наведении разворачивается до
    // expandedWidth (левая и правая зоны).
    readonly property real collapsedWidth: Math.max(centerZone.width + collapsedPadding * 2, 40)
    property bool expanded: false

    // Лаунчер: состояние
    property bool launcherWanted: false
    // true пока лаунчер открыт ИЛИ ещё сворачивается: ширина бара держится
    // до конца анимации высоты, потом сжимается обратно
    readonly property bool launcherShown: launcherWanted || launcherPopup.animHeight > 0.5
    property bool hoverGuard: false

    property int outerRadius: 14
    property int notchRadius: 20
    property int dropdownRadius: 14

    // --- дропдауны бара (создаются по конфигу) -----------------------------
    property var ddItems: []

    function dropdown(name) {
        for (const d of ddItems) {
            if (d.ddName === name) return d
        }
        return null
    }

    readonly property real maxDdHeight: {
        let m = 0
        for (const d of ddItems) m = Math.max(m, d.dropdownHeight)
        return m
    }
    readonly property real maxDdAnim: {
        let m = 0
        for (const d of ddItems) m = Math.max(m, d.animHeight)
        return m
    }
    readonly property bool anyDdExpanded: {
        for (const d of ddItems) {
            if (d.expanded) return true
        }
        return false
    }

    // Нельзя сворачиваться, пока открыт любой дропдаун или меню трея
    readonly property bool busy: anyDdExpanded || Services.PanelState.openTrayMenus > 0
    onBusyChanged: if (!busy) collapseTimer.restart()

    Timer {
        id: collapseTimer
        interval: 350
        onTriggered: if (!barHover.hovered && !shell.busy) shell.expanded = false
    }

    function openBarDropdown(name, anchorItem, zone) {
        if (shell.hoverGuard) return
        const target = dropdown(name)
        if (!target) return
        for (const d of ddItems) {
            if (d !== target) d.requestHardClose()
        }

        // Дропдаун выравнивается по иконке (левый край, либо правый - для
        // иконок во второй половине панели). Считаем по итоговой ширине:
        // правая зона прижата к правому краю, центральная - по центру.
        const p = anchorItem.mapToItem(barRoot, 0, 0)
        const delta = shell.expandedWidth - barRoot.width
        const shift = zone === "right" ? delta : (zone === "center" ? delta / 2 : 0)
        const ax = p.x + shift
        let x = (ax + anchorItem.width / 2 < shell.expandedWidth / 2)
                ? ax : ax + anchorItem.width - target.dropdownWidth
        x = Math.max(0, Math.min(x, shell.expandedWidth - target.dropdownWidth))
        target.dropdownX = Math.round(x)

        target.requestOpen()
    }

    function closeBarDropdowns() {
        for (const d of ddItems) d.requestHardClose()
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

    IpcHandler {
        target: "panel"

        function reload(): void { Services.Config.reload() }
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
        implicitHeight: shell.barHeight + Math.max(shell.maxDdHeight, shell.launcherHeight)

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
            // иначе компактная таблетка под центральную зону
            width: shell.expanded ? shell.expandedWidth
                 : (shell.launcherShown ? Math.max(shell.launcherWidth, shell.collapsedWidth)
                                        : shell.collapsedWidth)
            height: shell.barHeight + Math.max(shell.maxDdAnim, launcherPopup.animHeight, 0)

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

                dropdowns: {
                    const list = [{
                        x: launcherPopup.dropdownX,
                        width: launcherPopup.dropdownWidth,
                        height: launcherPopup.animHeight
                    }]
                    for (const d of shell.ddItems)
                        list.push({ x: d.dropdownX, width: d.dropdownWidth, height: d.animHeight })
                    return list
                }

                fillColor: colors.color4
                strokeColor: colors.border
                strokeWidth: 1
            }

            // ---------------------------------------------------- зоны бара
            // Левая и правая зоны видны только в развёрнутой панели.
            BarZone {
                id: leftZone
                zone: "left"
                model: shell.barCfg.left ?? []
                barHeight: shell.barHeight
                spacing: shell.barCfg.spacing ?? 1
                anchors.top: parent.top
                anchors.left: parent.left

                opacity: shell.expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 160 } }

                onOpenDropdown: (name, item, z) => shell.openBarDropdown(name, item, z)
            }

            // Центральная зона видна всегда - от её ширины считается
            // размер свёрнутой таблетки.
            BarZone {
                id: centerZone
                zone: "center"
                model: shell.barCfg.center ?? []
                barHeight: shell.barHeight
                spacing: shell.barCfg.spacing ?? 1
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter

                onOpenDropdown: (name, item, z) => shell.openBarDropdown(name, item, z)
            }

            BarZone {
                id: rightZone
                zone: "right"
                model: shell.barCfg.right ?? []
                barHeight: shell.barHeight
                spacing: shell.barCfg.spacing ?? 1
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: 12

                opacity: shell.expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 160 } }

                onOpenDropdown: (name, item, z) => shell.openBarDropdown(name, item, z)
            }

            // Лаунчер: центрирован под таблеткой. Ширина бара = ширина лаунчера -
            // боковые стороны сливаются с баром без выемок; если бар шире
            // (панель развёрнута) - появляются обычные выемки.
            DropDown {
                id: launcherPopup
                originY: shell.barHeight
                dropdownWidth: Math.min(shell.launcherWidth, barRoot.width)
                dropdownX: Math.round((barRoot.width - dropdownWidth) / 2)
                dropdownHeight: shell.launcherHeight
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

            // Дропдауны из config.lua (dropdowns = { имя = { ... } })
            Repeater {
                id: ddRepeater
                model: Services.Config.dropdownNames

                onItemAdded: (index, item) => shell.ddItems = shell.ddItems.concat([item])
                onItemRemoved: (index, item) => shell.ddItems = shell.ddItems.filter(d => d !== item)

                delegate: DropDown {
                    id: dd
                    required property string modelData

                    readonly property string ddName: modelData
                    readonly property var cfg: Services.Config.dropdowns[modelData] ?? ({})

                    backgroundColor: colors.color4
                    borderColor: colors.border
                    cornerRadius: shell.dropdownRadius
                    takeFocus: false
                    showBorder: launcherPopup.animHeight > 1

                    originY: shell.barHeight
                    dropdownWidth: cfg.width ?? 340
                    // высота: из конфига или по содержимому
                    dropdownHeight: cfg.height ?? (view.implicitHeight + contentMargins * 2)
                    closeDelay: cfg.closeDelay ?? 10

                    Block {
                        id: view
                        anchors.fill: parent
                        spec: ({
                            type: "column",
                            spacing: dd.cfg.spacing ?? 8,
                            items: dd.cfg.content ?? []
                        })
                    }
                }
            }
        }
    }
}
