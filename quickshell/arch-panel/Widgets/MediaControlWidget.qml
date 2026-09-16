import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Rectangle {
    id: root

    // ------------------------------------------------------------------
    // Public API
    // ------------------------------------------------------------------
    property var colors

    property url playingIcon: Qt.resolvedUrl("../Assets/kuru.gif")
    property url pausedIcon: Qt.resolvedUrl("../Assets/archio.png")

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
    readonly property int baseIconSize: 32
    readonly property int baseCoverSize: 36
    readonly property int baseSpacing: 12
    readonly property int basePadding: 12
    readonly property int baseBarFontSize: 20
    readonly property int baseRadius: 8

    readonly property real baselineHeight: baseIconSize + basePadding * 2
    readonly property real uiScale: Math.max(0.65, Math.min(2.0, height / baselineHeight))

    readonly property real iconSize: baseIconSize * uiScale
    readonly property real coverSize: baseCoverSize * uiScale
    readonly property real rowSpacing: baseSpacing * uiScale
    readonly property real barFontSize: baseBarFontSize * uiScale

    implicitWidth: baseCoverSize + baseIconSize * 2 + baseSpacing * 2 + basePadding * 2
    implicitHeight: baselineHeight

    radius: baseRadius * uiScale
    color: "transparent"

    Behavior on radius { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

    // ------------------------------------------------------------------
    // Audio state — this is what gates cava
    //
    // "Music is playing" is not enough on its own: MPRIS can report
    // Playing while the sink is muted or the volume is at 0, in which
    // case there's nothing to visualize and spinning up cava is pure
    // waste. So cava only runs when ALL of these are true:
    //   - a player is actively playing
    //   - the default sink isn't muted
    //   - the default sink's volume is above 0
    // ------------------------------------------------------------------
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real sinkVolume: sink?.audio?.volume ?? 0
    readonly property bool sinkMuted: sink?.audio?.muted ?? true
    readonly property bool isPlaying: Players.active?.playbackState === MprisPlaybackState.Playing

    readonly property bool audioActive: isPlaying && !sinkMuted && sinkVolume > 0.001

    property bool cavaConfigReady: false

    onAudioActiveChanged: {
        if (cavaConfigReady)
            cavaProc.running = audioActive;
        if (!audioActive)
            cavaBackground.bars = Array(root.barCount).fill(0);
    }

    readonly property int barCount: 16

    // ------------------------------------------------------------------
    // Visualizer
    // ------------------------------------------------------------------
    Item {
        id: cavaBackground
        anchors.fill: parent
        clip: true

        property var bars: Array(root.barCount).fill(0)
        property bool silence: bars.every(v => v === 0)
        readonly property var blocks: [" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]

        opacity: root.audioActive && !silence ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

        RowLayout {
            anchors.fill: parent
            spacing: 1

            Repeater {
                model: cavaBackground.bars.length

                Text {
                    required property int index
                    readonly property real level: cavaBackground.bars[index] / 255

                    text: cavaBackground.silence
                          ? " "
                          : cavaBackground.blocks[
                                Math.min(Math.floor(cavaBackground.bars[index] / 28.5), 8)
                            ]
                    font.family: "monospace"
                    font.pixelSize: root.barFontSize
                    color: colors?.color4 ?? "#ffffff"
                    opacity: 0.55 + 0.45 * level
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignBottom
                }
            }
        }

        // Config is written once at startup — regenerating it on every
        // play/pause is pointless, only the capture process itself needs
        // to start/stop with playback.
        Component.onCompleted: writeCfg.running = true

        Process {
            id: writeCfg
            running: false
            command: ["bash", "-c",
                "mkdir -p /tmp/qs-cava && cat > /tmp/qs-cava/cava.ini <<'CFG'\n" +
                "[general]\n" +
                "framerate = 30\n" +
                "bars = " + root.barCount + "\n" +
                "[input]\n" +
                "method = pipewire\n" +
                "source = auto\n" +
                "[smoothing]\n" +
                "noise_reduction = 77\n" +
                "monstercat = 1\n" +
                "[output]\n" +
                "method = raw\n" +
                "raw_target = /dev/stdout\n" +
                "data_format = ascii\n" +
                "ascii_max_range = 255\n" +
                "bar_delimiter = 59\n" +
                "CFG\n"
            ]
            onExited: {
                root.cavaConfigReady = true;
                cavaProc.running = root.audioActive;
            }
        }

        Process {
            id: cavaProc
            running: false
            command: ["cava", "-p", "/tmp/qs-cava/cava.ini"]
            stdout: SplitParser {
                onRead: (line) => {
                    const parts = line.trim().replace(/;$/, "").split(";");
                    if (parts.length >= cavaBackground.bars.length) {
                        cavaBackground.bars = parts
                            .slice(0, cavaBackground.bars.length)
                            .map(v => parseInt(v) || 0);
                    }
                }
            }
            // Only auto-restart on an unexpected crash. If we stopped it
            // on purpose (audio went silent/muted/paused) audioActive is
            // already false here, so this is a no-op — this is the fix
            // for the old unconditional "onExited: running = true", which
            // made cava impossible to actually stop.
            onExited: (exitCode, exitStatus) => {
                if (root.audioActive)
                    restartTimer.restart();
            }
        }

        Timer {
            id: restartTimer
            interval: 300
            repeat: false
            onTriggered: if (root.audioActive) cavaProc.running = true
        }
    }

    // ------------------------------------------------------------------
    // Controls
    // ------------------------------------------------------------------
    RowLayout {
        id: controlRow
        anchors.centerIn: parent
        spacing: root.rowSpacing

        MediaIconButton {
            glyph: "⏮"
            size: root.iconSize
            iconColor: colors?.color12 ?? "#ffffff"
            onClicked: Players.active?.previous()
        }

        Item {
            implicitWidth: root.coverSize
            implicitHeight: root.coverSize
            scale: playPauseArea.pressed ? 0.9 : (playPauseArea.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: Players.active?.playbackState === MprisPlaybackState.Playing
                        ? root.playingIcon
                        : root.pausedIcon
            }

            MouseArea {
                id: playPauseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Players.active?.togglePlaying()
            }
        }

        MediaIconButton {
            glyph: "⏭"
            size: root.iconSize
            iconColor: colors?.color12 ?? "#ffffff"
            onClicked: Players.active?.next()
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
