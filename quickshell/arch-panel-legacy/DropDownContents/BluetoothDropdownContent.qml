import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Bluetooth
import "../Services" as Services

// Полноценная замена bluetoothctl: список устройств (спаренные/доступные),
// pair/connect/disconnect/forget, тумблер адаптера, discovery, батарея.
Item {
    id: root

    property var colors

    onVisibleChanged: {
        if (visible) Services.BluetoothService.setDiscovering(true)
        else Services.BluetoothService.setDiscovering(false)
    }

    function stateLabel(dev) {
        if (dev.pairing) return "Сопряжение…"
        switch (dev.state) {
            case BluetoothDeviceState.Connecting: return "Подключение…"
            case BluetoothDeviceState.Disconnecting: return "Отключение…"
            case BluetoothDeviceState.Connected: return "Подключено"
            default: return dev.paired ? "Сопряжено" : "Доступно"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // --- header ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "\uF294"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 15
                color: Services.BluetoothService.enabled ? root.colors.color10 : root.colors.color5
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: 12
                color: root.colors.color15
                text: {
                    if (!Services.BluetoothService.available) return "Адаптер не найден"
                    if (!Services.BluetoothService.enabled) return "Bluetooth выключен"
                    const n = Services.BluetoothService.connectedDevices.length
                    if (n === 1) return Services.BluetoothService.connectedDevices[0].name
                    if (n > 1) return n + " устройств подключено"
                    return Services.BluetoothService.discovering ? "Поиск устройств…" : "Не подключено"
                }
            }

            BusyIndicator {
                visible: Services.BluetoothService.discovering
                running: visible
                implicitWidth: 25
                implicitHeight: 25
            }

            // Switch {
            //     checked: Services.BluetoothService.enabled
            //     onToggled: Services.BluetoothService.setEnabled(checked)
            // }

            Rectangle {
                id: bluetoothButton

                implicitWidth: 27
                implicitHeight: 27
                radius: 13
                color: mouseArea.pressed ? 
                    root.colors.color8 : 
                    (
                        mouseArea.containsMouse ? 
                        root.colors.color2 : 
                        (
                            Services.BluetoothService.enabled ?
                            root.colors.color10 : 
                            root.colors.color8
                        )
                    )

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "\u{F293}"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 17
                    color: Services.BluetoothService.enabled
                        ? root.colors.color13
                        : root.colors.color11
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.BluetoothService.setEnabled(!Services.BluetoothService.enabled)
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.colors.color8; opacity: 0.35 }

        // --- список устройств ---
        ListView {
            id: devList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: Services.BluetoothService.enabled
            model: Services.BluetoothService.sortedDevices
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                width: devList.width
                implicitHeight: 42
                radius: 8
                color: modelData.connected
                       ? root.colors.color6
                       : (rowHover.hovered ? root.colors.color2 : "transparent")

                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name.length > 0 ? modelData.name : modelData.deviceName
                            color: root.colors.color15
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.stateLabel(modelData)
                            color: root.colors.color7
                            opacity: 0.65
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        visible: modelData.batteryAvailable
                        text: "\uF240 " + Math.round(modelData.battery * 100) + "%"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 10
                        color: root.colors.color7
                        opacity: 0.75
                    }

                    // Забыть — только для спаренных, по ховеру
                    Text {
                        visible: modelData.paired && rowHover.hovered
                        text: "\uF1F8"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 11
                        color: root.colors.color5
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.BluetoothService.forget(modelData)
                        }
                    }

                    // Основная кнопка действия: подключить/отключить/сопрячь
                    Rectangle {
                        implicitWidth: actionLabel.implicitWidth + 16
                        implicitHeight: 24
                        radius: 7
                        color: actionArea.pressed ? root.colors.color12
                               : (actionArea.containsMouse ? root.colors.color7 : root.colors.color4)

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            font.pixelSize: 11
                            color: root.colors.color15
                            text: {
                                if (modelData.connected) return "Отключить"
                                if (modelData.paired) return "Подключить"
                                return "Сопряжение"
                            }
                        }

                        MouseArea {
                            id: actionArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected)
                                    Services.BluetoothService.disconnectFrom(modelData)
                                else if (modelData.paired)
                                    Services.BluetoothService.connectTo(modelData)
                                else
                                    Services.BluetoothService.pair(modelData)
                            }
                        }
                    }
                }

                HoverHandler { id: rowHover }
            }

            Text {
                anchors.centerIn: parent
                visible: devList.count === 0 && Services.BluetoothService.enabled
                text: Services.BluetoothService.discovering ? "Поиск…" : "Устройства не найдены"
                color: root.colors.color7
                opacity: 0.6
                font.pixelSize: 12
            }
        }
    }
}
