import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../Services" as Services

Rectangle {
    id: root

    // ------------------------------------------------------------------
    // Public API
    // ------------------------------------------------------------------
    property var colors
    property real seekStep: 10   // секунд на кнопки перемотки

    property url playingIcon: Qt.resolvedUrl("../Assets/kuru.gif")
    property url pausedIcon: Qt.resolvedUrl("../Assets/archico.png")

    // ------------------------------------------------------------------
    // Size-aware scaling
    //
    // Everything below is expressed as a "base" value (the design-time
    // size) multiplied by `uiScale`. uiScale reacts to the widget's own
    // height, so if whatever places this widget gives it more/less room
    // (Layout.preferredHeight, an explicit height binding, etc.) the
    // buttons, glyphs and spacing scale with it instead of staying fixed.
    //
    // NOTE: uiScale must never be derived from a property that itself
    // depends on uiScale (that's a binding loop). implicitHeight below is
    // therefore built purely from the *base* constants.
    // ------------------------------------------------------------------
    readonly property int baseIconSize: 64
    readonly property int baseCoverSize: 36
    readonly property int baseSpacing: 12
    readonly property int basePadding: 12
    readonly property int baseRadius: 8

    readonly property real baselineHeight: baseIconSize + basePadding * 2
    readonly property real uiScale: Math.max(0.65, Math.min(2.0, height / baselineHeight))

    readonly property real iconSize: baseIconSize * uiScale
    readonly property real coverSize: baseCoverSize * uiScale
    readonly property real rowSpacing: baseSpacing * uiScale

    implicitWidth: baseCoverSize + baseIconSize * 2 + baseSpacing * 2 + basePadding * 2
    implicitHeight: baselineHeight

    radius: baseRadius * uiScale
    color: "transparent"

    Behavior on radius { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

    // ------------------------------------------------------------------
    // Controls
    // ------------------------------------------------------------------
    RowLayout {
        id: controlRow
        anchors.centerIn: parent
        opacity: Services.Players.active ? 1 : 0.4
        spacing: root.rowSpacing

        MediaIconButton {
            glyph: "⏮"
            size: root.iconSize
            iconColor: colors?.color7 ?? "#ffffff"
            onClicked: Services.Players.active?.previous()
        }

        MediaIconButton {
            glyph: "⏪"
            size: root.iconSize
            iconColor: colors?.color7 ?? "#ffffff"
            onClicked: Services.Players.seekBy(-root.seekStep)
        }

        Item {
            implicitWidth: root.coverSize
            implicitHeight: root.coverSize
            scale: playPauseArea.pressed ? 0.9 : (playPauseArea.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: Services.Players.active?.playbackState === MprisPlaybackState.Playing
                        ? root.playingIcon
                        : root.pausedIcon
            }

            MouseArea {
                id: playPauseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Players.active?.togglePlaying()
            }
        }

        MediaIconButton {
            glyph: "⏩"
            size: root.iconSize
            iconColor: colors?.color7 ?? "#ffffff"
            onClicked: Services.Players.seekBy(root.seekStep)
        }

        MediaIconButton {
            glyph: "⏭"
            size: root.iconSize
            iconColor: colors?.color7 ?? "#ffffff"
            onClicked: Services.Players.active?.next()
        }
    }

    // ------------------------------------------------------------------
    // Reusable prev/next button: hover highlight + press feedback,
    // sized entirely off `size` so it tracks uiScale automatically.
    // ------------------------------------------------------------------
    component MediaIconButton: Rectangle {
        id: button

        property alias glyph: label.text
        property real size: 32
        property color iconColor: "#ffffff"
        signal clicked()

        implicitWidth: size
        implicitHeight: size
        radius: size * 0.25
        color: mouseArea.containsMouse ? Qt.rgba(iconColor.r, iconColor.g, iconColor.b, 0.12) : "transparent"
        scale: mouseArea.pressed ? 0.88 : 1.0

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

        Text {
            id: label
            anchors.centerIn: parent
            font.pixelSize: button.size * 0.55
            color: button.iconColor
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
