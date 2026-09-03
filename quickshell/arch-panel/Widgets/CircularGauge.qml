import QtQuick
import QtQuick.Shapes

// A simple circular progress ring with a label underneath.
Item {
    id: root

    property real value: 0        // 0..1
    property string label: ""
    property color ringColor: "#89b4fa"
    property color trackColor: "#313244"
    property int size: 64
    property int thickness: 6

    implicitWidth: size
    implicitHeight: size + 18

    Behavior on value { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    Shape {
        id: shape
        width: root.size
        height: root.size
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: root.thickness
            strokeColor: root.trackColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: (root.size - root.thickness) / 2
                radiusY: (root.size - root.thickness) / 2
                startAngle: -90
                sweepAngle: 359.999
            }
        }

        ShapePath {
            strokeWidth: root.thickness
            strokeColor: root.ringColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: (root.size - root.thickness) / 2
                radiusY: (root.size - root.thickness) / 2
                startAngle: -90
                sweepAngle: 359.999 * root.value
            }
        }
    }

    Text {
        anchors.centerIn: shape
        text: Math.round(root.value * 100) + "%"
        color: "#cdd6f4"
        font.pixelSize: 12
        font.bold: true
    }

    Text {
        anchors.top: shape.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        color: "#a6adc8"
        font.pixelSize: 11
    }
}
