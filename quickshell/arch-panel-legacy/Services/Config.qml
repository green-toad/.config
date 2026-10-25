pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Конфиг панели из config.lua.
//
// Lua запускается отдельным процессом (lua/loader.lua), который печатает
// конфиг в JSON. Если Lua нет или в конфиге ошибка - остаётся последний
// рабочий конфиг (вначале - встроенный по умолчанию, он повторяет config.lua).
// Файл отслеживается: сохранил - панель обновилась.
//
// Путь можно переопределить переменной ARCH_PANEL_CONFIG.
Singleton {
    id: root

    function urlToPath(u) {
        return decodeURIComponent(u.toString().replace(/^file:\/\//, ""))
    }

    readonly property string configPath: Quickshell.env("ARCH_PANEL_CONFIG")
                                         || urlToPath(Qt.resolvedUrl("../config.lua"))
    readonly property string loaderPath: urlToPath(Qt.resolvedUrl("../lua/loader.lua"))

    property var data: withDefaults({})
    readonly property var bar: data.bar
    readonly property var launcher: data.launcher
    readonly property var dropdowns: data.dropdowns
    readonly property var dropdownNames: Object.keys(data.dropdowns)

    property bool loadedFromLua: false
    property string error: ""

    // --- helpers для виджетов ------------------------------------------
    // "f1eb" / "1F600" -> символ, иначе строка как есть
    function glyph(g) {
        if (g === undefined || g === null) return ""
        const s = String(g)
        if (/^[0-9a-fA-F]{4,6}$/.test(s)) return String.fromCodePoint(parseInt(s, 16))
        return s
    }

    function reload() {
        if (proc.running) { pending = true; return }
        proc.running = true
    }

    // --- значения по умолчанию (зеркало config.lua) --------------------
    function defaults() {
        const T = t => ({ type: t })
        return {
            bar: {
                height: 30, expandedWidth: 800, collapsedPadding: 18, spacing: 1,
                left: [T("logo"), T("wifi"), T("bluetooth"), T("audio")],
                center: [T("workspaces")],
                right: [T("tray")]
            },
            launcher: { width: 500, height: 320 },
            dropdowns: {
                system: {
                    width: 360, height: 260, closeDelay: 800, spacing: 6,
                    content: [
                        { type: "row", fill: true, spacing: 8, items: [
                            { type: "column", width: 150, fill: true, spacing: 10, items: [
                                { type: "row", spacing: 14, align: "center", items: [T("cpu"), T("ram")] },
                                T("battery")
                            ] },
                            { type: "column", width: 46, fill: true, spacing: 10, items: [T("power"), T("reboot")] }
                        ] },
                        { type: "column", spacing: 5, items: [
                            { type: "update", fillWidth: false, align: "center" },
                            { type: "image", fill: true }
                        ] }
                    ]
                },
                wifi: { width: 340, content: [{ type: "wifi", fill: true }] },
                bluetooth: { width: 340, content: [{ type: "bluetooth", fill: true }] },
                audio: { width: 340, content: [T("volume"), T("separator"), T("player")] }
            }
        }
    }

    // Пользовательский конфиг поверх умолчаний: bar/launcher - по ключам,
    // дропдауны - по именам (false удаляет дропдаун).
    function withDefaults(cfg) {
        const d = defaults()
        const out = {
            bar: Object.assign({}, d.bar, cfg.bar || {}),
            launcher: Object.assign({}, d.launcher, cfg.launcher || {}),
            dropdowns: Object.assign({}, d.dropdowns)
        }
        const user = cfg.dropdowns || {}
        for (const k of Object.keys(user)) {
            if (user[k] === false) delete out.dropdowns[k]
            else out.dropdowns[k] = Object.assign({}, d.dropdowns[k] || {}, user[k])
        }
        return out
    }

    function apply(text) {
        let r
        try {
            r = JSON.parse(text)
        } catch (e) {
            root.error = "config.lua: не удалось разобрать вывод загрузчика: " + e
            console.warn(root.error)
            return
        }
        if (!r.ok) {
            root.error = "config.lua: " + r.error
            console.warn(root.error)
            return
        }
        root.error = ""
        root.loadedFromLua = true
        root.data = withDefaults(r.config)
    }

    property bool pending: false

    Process {
        id: proc
        // Перебираем возможные интерпретаторы: lua, lua5.4, ..., luajit
        command: ["sh", "-c",
            "for b in lua lua5.4 lua5.3 luajit lua5.1; do "
            + "if command -v \"$b\" >/dev/null 2>&1; then exec \"$b\" \"$0\" \"$1\"; fi; done; "
            + "echo '{\"ok\":false,\"error\":\"интерпретатор lua не найден (pacman -S lua)\"}'",
            root.loaderPath, root.configPath]
        stdout: StdioCollector {
            onStreamFinished: root.apply(text)
        }
        onExited: {
            if (root.pending) { root.pending = false; root.reload() }
        }
    }

    FileView {
        path: root.configPath
        watchChanges: true
        onFileChanged: reloadTimer.restart()
    }

    Timer {
        id: reloadTimer
        interval: 150
        onTriggered: root.reload()
    }

    Component.onCompleted: reload()
}
