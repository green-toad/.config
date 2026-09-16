import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io

Rectangle {
    id: root

    property var colors

    implicitWidth: controlRow.implicitWidth + 24
    implicitHeight: controlRow.implicitHeight + 12
    radius: 8
    color: "transparent"

    Item {
        id: cavaBackground
        anchors.fill: parent
        clip: true

        property var bars: Array(16).fill(0)
        property bool silence: bars.every(v => v === 0)
        readonly property var blocks: [" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
        readonly property var kurukurugif: Qt.resolvedUrl("../Assets/kuru.gif")
        readonly property var kurukurugif: Qt.resolvedUrl("../Assets/archio.png") // тестовое
        readonly property int size: 36

        RowLayout {
            anchors.fill: parent
            spacing: 1

            Repeater {
                model: cavaBackground.bars.length

                Text {
                    required property int index
                    text: cavaBackground.silence
                          ? " "
                          : cavaBackground.blocks[
                                Math.min(Math.floor(cavaBackground.bars[index] / 28.5), 8)
                            ]
                    font.family: "monospace"
                    font.pixelSize: root.size
                    color: colors.color4
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignBottom
                }
            }
        }

        Component.onCompleted: writeCfg.running = true

        Process {
            id: writeCfg
            running: false
            command: ["bash", "-c",
                "mkdir -p /tmp/qs-cava && cat > /tmp/qs-cava/cava.ini <<'CFG'\n" +
                "[general]\n" +
                "framerate = 30\n" +
                "bars = " + cavaBackground.bars.length + "\n" +
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
            onExited: cavaProc.running = true
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
            onExited: cavaProc.running = true
        }
    }

    RowLayout {
        id: controlRow
        anchors.centerIn: parent
        spacing: 12

        Rectangle {
            implicitWidth: 32
            implicitHeight: 32
            radius: 4
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "⏮"
                font.pixelSize: root.size
                color: colors.color12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Players.active?.previous()
            }
        }

        Item {
            implicitWidth: root.size
            implicitHeight: root.size

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: {
                    if (Players.active?.playbackState === MprisPlaybackState.Playing)
                        return "assets/playing.gif";
                    else
                        return "assets/paused.png";
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Players.active?.togglePlaying()
            }
        }

        Rectangle {
            implicitWidth: 32
            implicitHeight: 32
            radius: 4
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "⏭"
                font.pixelSize: root.size
                color: colors.color12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Players.active?.next()
            }
        }
    }
}