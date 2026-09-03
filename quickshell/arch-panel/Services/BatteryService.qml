pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property real percent: device ? device.percentage : 0   // 0..1
    readonly property bool charging: device ? (device.state === UPowerDeviceState.Charging) : false
    readonly property bool available: device ? device.isLaptopBattery : false
}
