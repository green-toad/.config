import QtQuick
import QtQuick.Layouts
import "../Services" as Services

// Плеер для звукового дропдауна: название/исполнитель, полоса перемотки
// со временем и ряд кнопок (MediaControlWidget).
ColumnLayout {
    id: root
    spacing: 6

    property var colors
    readonly property var player: Services.Players.active
    readonly property bool canSeek: player !== null && player.canSeek
                                    && player.positionSupported && player.lengthSupported

    function fmt(sec) {
        sec = Math.max(0, Math.floor(sec || 0))
        const h = Math.floor(sec / 3600)
        const m = Math.floor((sec % 3600) / 60)
        const s = sec % 60
        const ss = (s < 10 ? "0" : "") + s
        if (h > 0) return h + ":" + (m < 10 ? "0" : "") + m + ":" + ss
        return m + ":" + ss
    }

    // position у MPRIS сам не обновляется - дёргаем, пока трек играет
    Timer {
        running: root.player !== null && root.player.isPlaying
        interval: 500
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Text {
        Layout.fillWidth: true
        text: root.player ? (root.player.trackTitle || "Без названия") : "Нет активного плеера"
        elide: Text.ElideRight
        font.pixelSize: 13
        font.bold: true
        color: root.colors.color15
    }

    Text {
        Layout.fillWidth: true
        Layout.preferredHeight: 14
        text: root.player ? (root.player.trackArtist || "") : ""
        elide: Text.ElideRight
        font.pixelSize: 11
        color: root.colors.color14
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.preferredWidth: 34
            text: root.fmt(root.player ? root.player.position : 0)
            font.pixelSize: 10
            color: root.colors.color14
        }

        StyledSlider {
            Layout.fillWidth: true
            enabled: root.canSeek
            from: 0
            to: Math.max(root.player ? root.player.length : 1, 1)
            value: root.player ? root.player.position : 0
            onMoved: root.player.position = value
        }

        Text {
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: root.fmt(root.player ? root.player.length : 0)
            font.pixelSize: 10
            color: root.colors.color14
        }
    }

    MediaControlWidget {
        Layout.fillWidth: true
        Layout.preferredHeight: 56
        colors: root.colors
    }
}
