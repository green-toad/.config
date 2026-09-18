pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null

    property bool enabled: adapter ? adapter.enabled : false
    property bool discoverable: adapter ? adapter.discoverable : false
    readonly property bool discovering: adapter ? adapter.discovering : false

    readonly property var devices: adapter ? adapter.devices.values : []

    readonly property var sortedDevices: {
        const list = root.devices.slice()
        list.sort(function (a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            if (a.paired !== b.paired) return a.paired ? -1 : 1
            return (a.name || "").localeCompare(b.name || "")
        })
        return list
    }

    readonly property var connectedDevices: root.devices.filter(function (d) { return d.connected })

    function setEnabled(on) {
        if (adapter) adapter.enabled = on
        if (!on) return
    }

    function setDiscovering(on) {
        if (adapter) adapter.discovering = on
    }

    function connectTo(dev) {
        dev.connect()
    }

    function disconnectFrom(dev) {
        dev.disconnect()
    }

    function pair(dev) {
        dev.pair()
    }

    function cancelPair(dev) {
        dev.cancelPair()
    }

    function forget(dev) {
        dev.forget()
    }
}
