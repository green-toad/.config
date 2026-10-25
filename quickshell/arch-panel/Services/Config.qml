pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Конфиг панели из config.lua: только состав и порядок виджетов.
//
// Lua запускается отдельным процессом (lua/loader.lua) и печатает конфиг в
// JSON. Если Lua нет или в конфиге ошибка - остаётся последний рабочий
// конфиг (вначале встроенный, он повторяет config.lua). Файл отслеживается.
// Путь можно переопределить переменной ARCH_PANEL_CONFIG.
Singleton {
    id: root

    function urlToPath(u) {
        return decodeURIComponent(u.toString().replace(/^file:\/\//, ""))
    }

    readonly property string configPath: Quickshell.env("ARCH_PANEL_CONFIG")
                                         || urlToPath(Qt.resolvedUrl("../config.lua"))
    readonly property string loaderPath: urlToPath(Qt.resolvedUrl("../lua/loader.lua"))

    // Дропдауны, которые умеет рисовать QML
    readonly property var knownDropdowns: ["system", "wifi", "bluetooth", "audio"]

    property var data: withDefaults({})
    readonly property var bar: data.bar               // { left, center, right } - списки имён
    readonly property var dropdowns: data.dropdowns   // { имя: [части] }
    // только известные и непустые
    readonly property var dropdownNames: knownDropdowns.filter(n => (data.dropdowns[n] ?? []).length > 0)

    property string error: ""
    property bool pending: false

    function defaults() {
        return {
            bar: {
                left: ["logo", "wifi", "bluetooth", "audio"],
                center: ["workspaces"],
                right: ["tray"]
            },
            dropdowns: {
                system: ["cpu", "ram", "battery", "power", "reboot", "update", "image"],
                wifi: ["wifi"],
                bluetooth: ["bluetooth"],
                audio: ["volume", "player"]
            }
        }
    }

    function names(v) {
        return Array.isArray(v) ? v.filter(x => typeof x === "string") : null
    }

    // Что не указано в config.lua - берётся из умолчаний
    function withDefaults(cfg) {
        const d = defaults()
        const out = { bar: {}, dropdowns: {} }
        for (const z of ["left", "center", "right"])
            out.bar[z] = names((cfg.bar || {})[z]) ?? d.bar[z]
        for (const k of Object.keys(d.dropdowns))
            out.dropdowns[k] = names((cfg.dropdowns || {})[k]) ?? d.dropdowns[k]
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
        root.data = withDefaults(r.config)
    }

    function reload() {
        if (proc.running) { pending = true; return }
        proc.running = true
    }

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
