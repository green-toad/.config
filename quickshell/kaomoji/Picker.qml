import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "DropDownContents"

// Hold-to-show kaomoji picker.
//
//  hold the combo  -> window appears next to the cursor and grabs the keyboard
//  arrows          -> move over the table
//  Enter / click   -> text goes into the caret of the window that was focused
//  release combo   -> window disappears (Escape does the same)
//
// Like the panel's launcher this is driven over IPC; the binds live in the
// Hyprland config (press -> show, release -> hide):
//   qs -p <dir> ipc call kaomoji show
//   qs -p <dir> ipc call kaomoji hide
Scope {
    id: picker

    Colors { id: colors }
    Config { id: config }

    // --- state ------------------------------------------------------------
    property bool held: false                 // combo currently pressed
    property var target: ({ address: "", cls: "" })   // window focused before opening
    property real posX: 0
    property real posY: 0
    property var targetScreen: Quickshell.screens[0]
    property string pendingType: ""

    // --- IPC (called from the Hyprland binds) ----------------------------------
    IpcHandler {
        target: "kaomoji"

        function show_pan(): void { picker.begin() }
        function hide_pan(): void { picker.end() }
        function toggle_pan(): void {
            if (picker.held) picker.end()
            else picker.begin()
        }
    }

    // --- open / close -------------------------------------------------------
    // One hyprctl round-trip: cursor position, monitors, and the window that
    // currently has focus (the paste target).
    Process {
        id: locator
        command: ["sh", "-c",
            'w=$(hyprctl -j activewindow 2>/dev/null); [ -z "$w" ] && w="{}"; ' +
            'printf \'{"cursor":%s,"monitors":%s,"window":%s}\' ' +
            '"$(hyprctl -j cursorpos)" "$(hyprctl -j monitors)" "$w"']
        stdout: StdioCollector {
            id: locatorOut
            onStreamFinished: picker.onLocated(locatorOut.text)
        }
    }

    function begin() {
        held = true
        if (!locator.running)
            locator.running = true
    }

    function end() {
        held = false
        popup.requestHardClose()
        if (pendingType !== "")
            typeTimer.restart()
    }

    function onLocated(raw) {
        if (!held)          // released before hyprctl answered: a quick tap
            return
        var d
        try {
            d = JSON.parse(raw)
        } catch (e) {
            console.warn("kaomoji: bad hyprctl output:", e)
            return
        }

        var cx = d.cursor.x, cy = d.cursor.y
        var mons = d.monitors || []
        var mon = null
        for (var i = 0; i < mons.length; i++) {
            var m = mons[i]
            var sc = m.scale || 1
            var rotated = (m.transform % 2) === 1
            m.lw = (rotated ? m.height : m.width) / sc
            m.lh = (rotated ? m.width : m.height) / sc
            if (cx >= m.x && cx < m.x + m.lw && cy >= m.y && cy < m.y + m.lh) {
                mon = m
                break
            }
        }

        var W = config.windowWidth, H = config.windowHeight
        var off = config.cursorOffset
        var lx = cx, ly = cy, sw = 1e6, sh = 1e6
        if (mon) {
            lx = cx - mon.x
            ly = cy - mon.y
            sw = mon.lw
            sh = mon.lh
            for (var s = 0; s < Quickshell.screens.length; s++) {
                if (Quickshell.screens[s].name === mon.name) {
                    targetScreen = Quickshell.screens[s]
                    break
                }
            }
        }

        // keep the whole window on the monitor
        posX = Math.max(0, Math.min(lx + off, sw - W))
        posY = Math.max(0, Math.min(ly + off, sh - H))

        var w = d.window || {}
        target = { address: w.address || "", cls: w["class"] || w.initialClass || "" }

        grid.reset()
        popup.requestOpen()
    }

    // --- inserting the text ----------------------------------------------------
    function isTerminal(cls) {
        var c = cls.toLowerCase()
        var list = config.terminalClasses || []
        for (var i = 0; i < list.length; i++)
            if (String(list[i]).toLowerCase() === c)
                return true
        return false
    }

    function insert(text) {
        console.log("kaomoji: insert via", config.insertMode, "->", text,
                    "| target:", picker.target.address, picker.target.cls)
        popup.requestHardClose()        // focus goes back to the previous window
        if (config.insertMode === "wtype") {
            pendingType = text
            if (!held)
                typeTimer.restart()
            // else: end() fires it once the combo is released
        } else {
            copier.command = ["wl-copy", "--", text]
            copier.running = true
        }
    }

    Process {
        id: copier
        onExited: (code) => {
            if (code === 0)
                pasteTimer.restart()
            else
                console.warn("kaomoji: wl-copy failed (is wl-clipboard installed?)")
        }
    }

    Timer {
        id: pasteTimer
        interval: config.pasteDelay
        onTriggered: {
            // "MODS, key" from config -> Lua table for hl.dsp.send_shortcut
            var sc = picker.isTerminal(picker.target.cls)
                ? config.terminalPasteShortcut : config.pasteShortcut
            var comma = sc.indexOf(",")
            var mods = comma >= 0 ? sc.substring(0, comma).trim() : ""
            var key = (comma >= 0 ? sc.substring(comma + 1) : sc).trim()

            var lua = "hl.dsp.send_shortcut({ mods = " + JSON.stringify(mods)
                + ", key = " + JSON.stringify(key)
            if (picker.target.address !== "")
                lua += ", window = " + JSON.stringify("address:" + picker.target.address)
            lua += " })"

            console.log("kaomoji: dispatch " + lua)
            Hyprland.dispatch(lua)
        }
    }

    Process {
        id: typer
        onExited: (code) => {
            if (code !== 0)
                console.warn("kaomoji: wtype exited with", code, "(is wtype installed?)")
        }
    }
    Timer {
        id: typeTimer
        interval: config.pasteDelay
        onTriggered: {
            if (picker.held || picker.pendingType === "")
                return
            typer.command = ["wtype", "--", picker.pendingType]
            picker.pendingType = ""
            typer.running = true
        }
    }

    // --- the window ---------------------------------------------------------------
    PanelWindow {
        id: win

        screen: picker.targetScreen
        anchors.top: true
        anchors.left: true
        margins.top: picker.posY
        margins.left: picker.posX

        implicitWidth: config.windowWidth
        implicitHeight: config.windowHeight

        color: "transparent"
        visible: popup.expanded || popup.opacity > 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "kaomoji-picker"
        WlrLayershell.keyboardFocus: popup.expanded
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        mask: Region { item: clickableArea }

        Item {
            id: surface
            anchors.fill: parent

            Item {
                id: clickableArea
                anchors.top: parent.top
                anchors.left: parent.left
                width: config.windowWidth
                height: config.barHeight + popup.animHeight
            }

            // bar + notch silhouette, fades together with the dropdown
            Item {
                anchors.fill: parent
                opacity: popup.opacity

                NotchShape {
                    anchors.top: parent.top
                    anchors.left: parent.left

                    barWidth: config.windowWidth
                    barHeight: config.barHeight
                    outerRadius: 14
                    notchRadius: 20
                    dropdownRadius: 14

                    // one dropdown spanning the full bar width = flush on both sides
                    dropdowns: [
                        { x: 0, width: config.windowWidth, height: popup.animHeight }
                    ]

                    fillColor: colors.color4
                    strokeColor: colors.border
                    strokeWidth: 1
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    height: config.barHeight
                    verticalAlignment: Text.AlignVCenter
                    text: config.title
                    color: colors.color7
                    font.pixelSize: 13
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    height: config.barHeight
                    verticalAlignment: Text.AlignVCenter
                    text: grid.count > 0 ? (grid.currentIndex + 1) + " / " + grid.count : ""
                    color: colors.color7
                    opacity: 0.7
                    font.pixelSize: 12
                }
            }

            DropDown {
                id: popup
                originY: config.barHeight
                dropdownX: 0
                dropdownWidth: config.windowWidth
                dropdownHeight: config.windowHeight - config.barHeight
                closeDelay: 0
                closeOnHoverLeave: false
                openOnHover: false

                KaomojiGridContent {
                    id: grid
                    anchors.fill: parent
                    focus: true

                    colors: colors
                    items: config.items
                    cellWidth: config.cellWidth
                    cellHeight: config.cellHeight
                    spacing: config.cellSpacing
                    columnsSetting: config.columns

                    onChosen: (text) => picker.insert(text)
                }
            }
        }
    }
}
