pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real volume: 0     // 0..1
    property bool muted: false

    function refresh() { volProc.running = true }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                // "Volume: 0.45" or "Volume: 0.45 [MUTED]"
                const m = text.match(/Volume:\s*([\d.]+)/)
                if (m) root.volume = parseFloat(m[1])
                root.muted = text.includes("MUTED")
            }
        }
    }

    function setVolume(v) {
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)])
        volume = v
    }

    function toggleMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        refresh()
    }
}
