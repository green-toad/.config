import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../Services" as Services

// Плеер: название/исполнитель, перемотка со временем и кнопки.
// Фон - обложка играющего трека: внизу видна целиком, к верху плавно
// растворяется в фон дропдауна.
Item {
    id: root

    property var colors
    // насколько обложка выходит за блок вбок/вниз (до краёв дропдауна);
    // 10 = стандартные поля DropDown. 0 - не выходить.
    property real bleed: 10
    property real cornerRadius: 14

    readonly property var player: Services.Players.active
    readonly property string artUrl: player && player.trackArtUrl ? String(player.trackArtUrl) : ""
    readonly property bool canSeek: player !== null && player.canSeek
                                    && player.positionSupported && player.lengthSupported

    implicitHeight: col.implicitHeight
    implicitWidth: 300

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

    // ------------------------------------------------------------ обложка
    ClippingRectangle {
        id: coverBg
        z: -1
        anchors.fill: parent
        anchors.leftMargin: -root.bleed
        anchors.rightMargin: -root.bleed
        anchors.bottomMargin: -root.bleed
        anchors.topMargin: 0
        radius: root.cornerRadius
        color: "transparent"

        opacity: cover.status === Image.Ready ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Image {
            id: cover
            anchors.fill: parent
            source: root.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }

        // фон дропдауна сверху (непрозрачный) -> обложка снизу
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.colors.color4 }
                GradientStop { position: 0.35; color: Qt.alpha(root.colors.color4, 0.82) }
                GradientStop { position: 1.0; color: Qt.alpha("#000000", 0.40) }
            }
        }
    }

    // ----------------------------------------------------------- содержимое
    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 6

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
}
