import QtQuick
import QtQuick.Controls
import "../"

// Общий слайдер в стиле панели (громкость, перемотка трека).
Slider {
    id: control
    Colors { id: colors }

    property color fillColor: colors.color7

    implicitHeight: 18

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth
        height: 6
        radius: 3
        color: colors.color8
        opacity: control.enabled ? 1 : 0.5

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: 3
            color: control.fillColor
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: 12
        height: 12
        radius: 6
        color: colors.color15
        visible: control.enabled
    }
}
