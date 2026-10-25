import QtQuick
import QtQuick.Layouts
import "../"
import "../Services" as Services

// Громкость: кнопка mute, слайдер, проценты.
RowLayout {
    id: root
    spacing: 8
    Colors { id: colors }

    Item {
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22

        Text {
            anchors.centerIn: parent
            text: Services.AudioService.muted ? "\uF026" : "\uF028"
            font.family: "Symbols Nerd Font"
            font.pixelSize: 14
            color: Services.AudioService.muted ? colors.color14 : colors.color7
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Services.AudioService.toggleMute()
        }
    }

    StyledSlider {
        Layout.fillWidth: true
        from: 0
        to: 1.5
        value: Services.AudioService.volume
        onMoved: Services.AudioService.setVolume(value)
    }

    Text {
        text: Math.round(Services.AudioService.volume * 100) + "%"
        color: colors.color15
        font.pixelSize: 11
        Layout.preferredWidth: 32
        horizontalAlignment: Text.AlignRight
    }
}
