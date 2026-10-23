pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

// Полноценный Wi-Fi сервис поверх нативного Quickshell.Networking
// (NetworkManager через DBus). Требует Quickshell >= 0.3.0.
//
// Заменяет собой "nmtui": включение адаптера, сканирование, список сетей
// с сигналом/защитой/статусом, подключение (в т.ч. по паролю), забыть сеть.
Singleton {
    id: root

    readonly property bool backendReady: Networking.backend === NetworkBackendType.NetworkManager

    // Первое Wi-Fi устройство в системе. Для мульти-адаптерных машин
    // при желании можно расширить до списка, пока хватает одного.
    readonly property var device: {
        if (!backendReady) return null
        const list = Networking.devices.values
        for (let i = 0; i < list.length; i++) {
            if (list[i].type === DeviceType.Wifi)
                return list[i]
        }
        return null
    }

    readonly property bool available: device !== null

    property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property bool scanning: device ? device.scannerEnabled : false

    readonly property var networks: device ? device.networks.values : []

    readonly property var activeNetwork: {
        const list = root.networks
        for (let i = 0; i < list.length; i++)
            if (list[i].connected) return list[i]
        return null
    }

    readonly property bool connected: activeNetwork !== null
    readonly property string ssid: activeNetwork ? activeNetwork.name : ""
    readonly property real signalStrength: activeNetwork ? activeNetwork.signalStrength : 0

    // Подключённая сеть — первой, дальше по убыванию сигнала.
    readonly property var sortedNetworks: {
        const list = root.networks.slice()
        list.sort(function (a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            return (b.signalStrength || 0) - (a.signalStrength || 0)
        })
        return list
    }

    function setEnabled(on) {
        Networking.wifiEnabled = on
        if (on) startScan()
        else stopScan()
    }

    function startScan() {
        if (device) device.scannerEnabled = true
    }

    function stopScan() {
        if (device) device.scannerEnabled = false
    }

    function connectTo(network) {
        network.connect()
    }

    // Для сетей, требующих пароль (WPA/WPA2/WPA3-SAE). Если пароль неверный,
    // network.connectionFailed(reason) прилетит с NoSecrets - обработайте
    // это в UI (см. WifiDropdownContent.qml).
    function connectWithPassword(network, psk) {
        network.connectWithPsk(psk)
    }

    function disconnectFrom(network) {
        network.disconnect()
    }

    function forget(network) {
        network.forget()
    }
}
