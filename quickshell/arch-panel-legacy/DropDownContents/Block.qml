import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../Widgets"
import "../Services" as Services

// Блок содержимого дропдауна по записи из конфига ({ type = "volume", ... }).
// row / column - контейнеры, рекурсивно создающие вложенные Block.
//
// Параметры блока (во всех типах): width, height, fill (растянуть по высоте),
// fillWidth, align = "center" | "left" | "right" | "vcenter".
//
// Чтобы добавить свой блок: объяви Component в разделе "блоки" и добавь case
// в pickLeaf().
Item {
    id: root

    property var spec: ({})
    readonly property string type: spec.type ?? ""
    readonly property bool isRow: type === "row"
    readonly property bool isColumn: type === "column"

    Colors { id: palette }

    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 0

    function alignOf(s) {
        switch (s.align) {
            case "center": return Qt.AlignHCenter
            case "left": return Qt.AlignLeft
            case "right": return Qt.AlignRight
            case "vcenter": return Qt.AlignVCenter
            default: return 0
        }
    }

    function pickLeaf(type) {
        switch (type) {
            case "cpu": return cpuComp
            case "ram": return ramComp
            case "battery": return batteryComp
            case "power": return powerComp
            case "reboot": return rebootComp
            case "update": return updateComp
            case "image": return imageComp
            case "volume": return volumeComp
            case "player": return playerComp
            case "wifi": return wifiComp
            case "bluetooth": return bluetoothComp
            case "clock": return clockComp
            case "text": return textComp
            case "separator": return separatorComp
            case "spacer": return spacerComp
            default: return unknownComp
        }
    }

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: root.isRow ? rowComp : (root.isColumn ? columnComp : root.pickLeaf(root.type))
    }

    // ------------------------------------------------------------ контейнеры
    // Делегат один для row и column: Loader рекурсивно грузит этот же файл.
    // (inline-компонент не видит id внешнего файла - родитель передаётся в host)
    component ChildLoader: Loader {
        required property var modelData
        property var host
        source: "Block.qml"
        // по умолчанию тянется по ширине, если не задана ширина/выравнивание
        Layout.fillWidth: modelData.fillWidth
                          ?? (modelData.width === undefined && modelData.align === undefined)
        Layout.fillHeight: modelData.fill ?? false
        Layout.preferredWidth: modelData.width ?? -1
        Layout.preferredHeight: modelData.height ?? -1
        Layout.alignment: host ? host.alignOf(modelData) : 0
        onLoaded: item.spec = modelData
    }

    Component {
        id: columnComp
        ColumnLayout {
            spacing: root.spec.spacing ?? 6
            Repeater {
                model: root.spec.items ?? []
                delegate: ChildLoader { host: root }
            }
        }
    }

    Component {
        id: rowComp
        RowLayout {
            spacing: root.spec.spacing ?? 6
            Repeater {
                model: root.spec.items ?? []
                delegate: ChildLoader { host: root }
            }
        }
    }

    // ----------------------------------------------------------------- блоки
    Component { id: cpuComp; CircularGauge {
        value: Services.SystemUsage.cpuUsage
        label: root.spec.label ?? "CPU"
        ringColor: palette.color14
    } }
    Component { id: ramComp; CircularGauge {
        value: Services.SystemUsage.ramUsage
        label: root.spec.label ?? "RAM"
        ringColor: palette.color14
    } }
    Component { id: batteryComp; QuickStatusRow {} }
    Component { id: powerComp; PowerButton {} }
    Component { id: rebootComp; RebootButton {} }
    Component { id: updateComp; UpdateButton {} }
    Component { id: imageComp; ImageDropZone {} }
    Component { id: volumeComp; VolumeRow {} }
    Component { id: playerComp; PlayerPanel {
        colors: palette
        bleed: root.spec.bleed ?? 10
    } }
    Component { id: wifiComp; WifiDropdownContent { colors: palette } }
    Component { id: bluetoothComp; BluetoothDropdownContent { colors: palette } }

    Component { id: clockComp; Text {
        text: Qt.formatDateTime(clk.date, root.spec.format ?? "HH:mm")
        font.pixelSize: root.spec.size ?? 14
        color: palette.color15
        horizontalAlignment: Text.AlignHCenter
        SystemClock {
            id: clk
            precision: (root.spec.format ?? "HH:mm").indexOf("s") >= 0
                       ? SystemClock.Seconds : SystemClock.Minutes
        }
    } }

    Component { id: textComp; Text {
        text: root.spec.text ?? ""
        font.pixelSize: root.spec.size ?? 12
        color: palette.color15
        wrapMode: Text.WordWrap
    } }

    Component { id: separatorComp; Rectangle {
        implicitHeight: 1
        color: palette.color6
        opacity: 0.4
    } }

    Component { id: spacerComp; Item {
        implicitHeight: root.spec.height ?? 8
        implicitWidth: root.spec.width ?? 8
    } }

    Component { id: unknownComp; Text {
        text: "?" + root.type
        font.pixelSize: 11
        color: palette.color5
    } }
}
