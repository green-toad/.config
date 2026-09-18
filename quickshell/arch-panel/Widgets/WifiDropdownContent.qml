import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Networking
import "../Services" as Services

Item {
    id: root

    property var colors

    property var expandedNetwork: null
    property string authError: ""

    onVisibleChanged: {
        if (visible) Services.WifiService.startScan()
        else {
            Services.WifiService.stopScan()
            expandedNetwork = null
        }
    }

    function signalIcon(s) {
        if (s > 0.75) return "\uF1EB"
        if (s > 0.5) return "\uF6AB"
        if (s > 0.25) return "\uF6AC"
        return "\uF6AD"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // --- header: статус + тумблер + сканирование ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "\uF1EB"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 15
                color: Services.WifiService.wifiEnabled ? root.colors.color10 : root.colors.color5
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: 12
                color: root.colors.color15
                text: {
                    if (!Services.WifiService.available) return "Адаптер не найден"
                    if (!Services.WifiService.wifiEnabled) return "Wi-Fi выключен"
                    if (Services.WifiService.connected) return Services.WifiService.ssid
                    return Services.WifiService.scanning ? "Поиск сетей…" : "Не подключено"
                }
            }

            BusyIndicator {
                visible: Services.WifiService.scanning
                running: visible
                implicitWidth: 16
                implicitHeight: 16
            }

            Text {
                text: "\uF021"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 13
                color: root.colors.color7
                opacity: rescanArea.containsMouse ? 1 : 0.7
                MouseArea {
                    id: rescanArea
                    anchors.fill: parent
                    anchors.margins: -5
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.WifiService.startScan()
                }
            }

            Switch {
                enabled: Services.WifiService.wifiHardwareEnabled
                checked: Services.WifiService.wifiEnabled
                onToggled: Services.WifiService.setEnabled(checked)
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.colors.color8; opacity: 0.35 }

        // --- список сетей ---
        ListView {
            id: netList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: Services.WifiService.wifiEnabled
            model: Services.WifiService.sortedNetworks
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds

            delegate: ColumnLayout {
                width: netList.width
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 8
                    color: modelData.connected
                           ? root.colors.color6
                           : (rowHover.hovered ? root.colors.color2 : "transparent")

                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Text {
                            text: root.signalIcon(modelData.signalStrength)
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 14
                            color: root.colors.color7
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: root.colors.color15
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: modelData.security !== WifiSecurityType.Open
                            text: "\uF023"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 10
                            color: root.colors.color7
                            opacity: 0.7
                        }

                        Text {
                            visible: modelData.connected
                            text: "\uF00C"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 11
                            color: root.colors.color10
                        }

                        // "Забыть" — только для известных сетей, показываем по ховеру
                        Text {
                            visible: modelData.known && rowHover.hovered
                            text: "\uF1F8"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 11
                            color: root.colors.color5
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Services.WifiService.forget(modelData)
                                    if (root.expandedNetwork === modelData)
                                        root.expandedNetwork = null
                                }
                            }
                        }
                    }

                    HoverHandler { id: rowHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.authError = ""
                            if (modelData.connected) {
                                Services.WifiService.disconnectFrom(modelData)
                                root.expandedNetwork = null
                            } else if (modelData.known || modelData.security === WifiSecurityType.Open) {
                                Services.WifiService.connectTo(modelData)
                                root.expandedNetwork = null
                            } else {
                                root.expandedNetwork = (root.expandedNetwork === modelData) ? null : modelData
                            }
                        }
                    }

                    Connections {
                        target: modelData
                        function onConnectionFailed(reason) {
                            root.authError = "Не удалось подключиться"
                            root.expandedNetwork = modelData
                        }
                    }
                }

                // --- инлайн-поле пароля для защищённых незнакомых сетей ---
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 4
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    visible: root.expandedNetwork === modelData
                    spacing: 6

                    TextField {
                        id: pwField
                        Layout.fillWidth: true
                        placeholderText: root.authError.length > 0 ? root.authError : "Пароль"
                        echoMode: TextInput.Password
                        color: root.colors.color7
                        placeholderTextColor: root.authError.length > 0 ? root.colors.color5 : root.colors.color7
                        background: Rectangle {
                            implicitHeight: 30
                            radius: 8
                            color: root.colors.color2
                            border.color: root.colors.color4
                            border.width: 1
                        }
                        onVisibleChanged: if (visible) { text = ""; forceActiveFocus() }
                        onAccepted: {
                            root.authError = ""
                            Services.WifiService.connectWithPassword(modelData, text)
                        }
                    }

                    Text {
                        text: "\uF00C"
                        font.family: "Symbols Nerd Font"
                        color: root.colors.color10
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.authError = ""
                                Services.WifiService.connectWithPassword(modelData, pwField.text)
                            }
                        }
                    }

                    Text {
                        text: "\uF00D"
                        font.family: "Symbols Nerd Font"
                        color: root.colors.color5
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.expandedNetwork = null
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: netList.count === 0 && Services.WifiService.wifiEnabled && !Services.WifiService.scanning
                text: "Сети не найдены"
                color: root.colors.color7
                opacity: 0.6
                font.pixelSize: 12
            }
        }
    }
}
