import QtQuick
import QtQuick.Layouts
import "../Widgets"

// Звук: громкость + плеер. parts: volume, player.
Item {
    id: root

    property var colors
    property var parts: []

    function has(n) { return parts.indexOf(n) >= 0 }

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 8

        VolumeRow {
            Layout.fillWidth: true
            visible: root.has("volume")
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.colors.color6
            opacity: 0.4
            visible: root.has("volume") && root.has("player")
        }

        PlayerPanel {
            Layout.fillWidth: true
            colors: root.colors
            visible: root.has("player")
        }
    }
}
