pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Батарея через UPower. У "displayDevice" (составное устройство) флаг
// isLaptopBattery всегда false, поэтому раньше батарея считалась
// отсутствующей. Берём displayDevice, если он реально присутствует, иначе
// ищем первую настоящую батарею среди устройств.
Singleton {
    id: root

    readonly property var device: {
        const d = UPower.displayDevice
        if (d && d.ready && d.isPresent && d.type === UPowerDeviceType.Battery)
            return d
        const list = UPower.devices.values
        for (let i = 0; i < list.length; i++) {
            if (list[i].isLaptopBattery) return list[i]
        }
        return null
    }

    readonly property bool available: device !== null
    // 0..1 (на случай, если сервис отдаст 0..100 - нормализуем)
    readonly property real percent: {
        if (!device) return 0
        const p = device.percentage
        return Math.max(0, Math.min(1, p > 1 ? p / 100 : p))
    }
    readonly property bool charging: device
        ? (device.state === UPowerDeviceState.Charging
           || device.state === UPowerDeviceState.FullyCharged)
        : false
}
