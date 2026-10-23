import QtQuick
import Quickshell
import Quickshell.Io

// Loads config.json (settings) and kaomoji.json (the list of strings)
// from the shell directory. Both files are watched: edit and save,
// changes apply live. Bad/missing files just leave the defaults below.
// JSON keys are exactly the property names of the "settings" block.
Scope {
    id: root

    // --- settings (defaults) -------------------------------------------
    property string title: "kaomoji"

    property int windowWidth: 300
    property int windowHeight: 450
    property int barHeight: 30
    property int cursorOffset: 12

    property int cellWidth: 136
    property int cellHeight: 42
    property int cellSpacing: 6
    // 0 = auto: as many columns as fit the window width.
    // > 0 = fixed; if wider than the window the table scrolls sideways.
    property int columns: 0

    // "sendshortcut": wl-copy + Ctrl+V sent to the window that was focused
    //                 (Hyprland's hl.dsp.send_shortcut, Lua config).
    // "wtype":        types the text with wtype once the combo is released
    //                 (needs the `wtype` package; fallback if send_shortcut misbehaves).
    property string insertMode: "sendshortcut"
    property string pasteShortcut: "CTRL, code:55"
    property string terminalPasteShortcut: "CTRL SHIFT, code:55"
    property var terminalClasses: ["kitty", "alacritty", "foot"]
    property int pasteDelay: 60

    // --- data ----------------------------------------------------------------
    property var items: []

    readonly property var settingKeys: [
        "title", "windowWidth", "windowHeight",
        "barHeight", "cursorOffset", "cellWidth", "cellHeight", "cellSpacing",
        "columns", "insertMode", "pasteShortcut", "terminalPasteShortcut",
        "terminalClasses", "pasteDelay"
    ]

    function applyConfig(txt) {
        var c
        try {
            c = JSON.parse(txt)
        } catch (e) {
            console.warn("kaomoji: config.json is not valid JSON:", e)
            return
        }
        for (var i = 0; i < settingKeys.length; i++) {
            var k = settingKeys[i]
            if (c[k] !== undefined && typeof c[k] === typeof root[k])
                root[k] = c[k]
        }
    }

    function applyItems(txt) {
        var arr
        try {
            arr = JSON.parse(txt)
        } catch (e) {
            console.warn("kaomoji: kaomoji.json is not valid JSON:", e)
            return
        }
        if (!Array.isArray(arr))
            return
        var out = []
        for (var i = 0; i < arr.length; i++)
            if (typeof arr[i] === "string" && arr[i].length > 0)
                out.push(arr[i])
        root.items = out
    }

    FileView {
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyConfig(text())
    }

    FileView {
        path: Quickshell.shellPath("kaomoji.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyItems(text())
    }
}
