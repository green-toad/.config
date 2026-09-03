pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuUsage: 0     // 0..1
    property real ramUsage: 0     // 0..1

    property var _prevIdle: 0
    property var _prevTotal: 0

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true
            ramProc.running = true
        }
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "head -n1 /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                // cpu  user nice system idle iowait irq softirq steal
                const parts = text.trim().split(/\s+/).slice(1).map(Number)
                const idle = parts[3] + parts[4]
                const total = parts.reduce((a, b) => a + b, 0)

                const diffIdle = idle - root._prevIdle
                const diffTotal = total - root._prevTotal

                if (root._prevTotal !== 0 && diffTotal > 0) {
                    root.cpuUsage = 1 - (diffIdle / diffTotal)
                }
                root._prevIdle = idle
                root._prevTotal = total
            }
        }
    }

    Process {
        id: ramProc
        command: ["sh", "-c", "free | awk '/Mem:/ {print $3/$2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(text.trim())
                if (!isNaN(v)) root.ramUsage = v
            }
        }
    }
}
