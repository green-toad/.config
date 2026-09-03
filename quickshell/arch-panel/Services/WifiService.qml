pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string ssid: "—"
    property bool connected: false

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ssidProc.running = true
    }

    Process {
        id: ssidProc
        // active connections only, first Wi-Fi device
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | head -n1 | cut -d: -f2"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                root.connected = s.length > 0
                root.ssid = s.length > 0 ? s : "Not connected"
            }
        }
    }
}
