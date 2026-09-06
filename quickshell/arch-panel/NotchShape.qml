import QtQuick
import QtQuick.Shapes

// Draws the panel's background silhouette as a single filled path:
// a wide top bar with normal rounded corners, and (once dropdownHeight > 0)
// a narrower panel below it. The dropdown's horizontal position is fully
// free via `dropdownX` (distance from the bar's left edge).
//
// Whichever side of the dropdown touches the bar's own edge (x == 0, or
// x+width == barWidth) is drawn as a straight line - no notch needed there,
// since there's no "step" to smooth out. The notch only appears on sides
// where the dropdown is narrower than the bar.
Shape {
    id: root

    // --- geometry ---------------------------------------------------
    property real barWidth: 800
    property real barHeight: 30
    property real dropdownWidth: 500
    property real dropdownHeight: 0     // animate this; 0 == flat bar only
    property real dropdownX: (barWidth - dropdownWidth) / 2 // default = centered

    property real outerRadius: 14       // bar's own 4 corners
    property real dropdownRadius: 14    // dropdown's bottom corners
    property real notchRadius: 20       // concave transition radius

    // --- appearance ---------------------------------------------------
    property color fillColor: "black"
    property color strokeColor: "transparent"
    property real strokeWidth: 0

    implicitWidth: barWidth
    implicitHeight: barHeight + dropdownHeight

    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fillColor
        strokeColor: root.strokeColor
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.RoundJoin
        capStyle: ShapePath.RoundCap

        PathSvg {
            path: root.buildPath()
        }
    }

    function buildPath() {
        var BIG = 1e6 // "no constraint" sentinel for Math.min

        var W = Math.max(root.barWidth, 1)
        var barH = Math.max(root.barHeight, 0)
        var dropW = Math.min(root.dropdownWidth, W)
        var dropH = Math.max(root.dropdownHeight, 0)

        var OR = Math.min(root.outerRadius, barH, W / 2)
        var dLeft = Math.max(0, Math.min(root.dropdownX, W - dropW))
        var dRight = dLeft + dropW

        var leftFlush = dLeft <= 0.5
        var rightFlush = dRight >= W - 0.5

        if (dropH < 0.5 || dropW < 1) {
            return "M " + OR + ",0 " +
                   "L " + (W - OR) + ",0 " +
                   "A " + OR + "," + OR + " 0 0 1 " + W + "," + OR + " " +
                   "L " + W + "," + (barH - OR) + " " +
                   "A " + OR + "," + OR + " 0 0 1 " + (W - OR) + "," + barH + " " +
                   "L " + OR + "," + barH + " " +
                   "A " + OR + "," + OR + " 0 0 1 0," + (barH - OR) + " " +
                   "L 0," + OR + " " +
                   "A " + OR + "," + OR + " 0 0 1 " + OR + ",0 Z"
        }

        var leftGap = leftFlush ? BIG : dLeft
        var rightGap = rightFlush ? BIG : (W - dRight)
        var NR = Math.min(root.notchRadius, dropH / 2, leftGap, rightGap)
        var DR = Math.min(root.dropdownRadius, dropW / 2, Math.max(dropH - NR, 0))
        var yBottom = barH + dropH

        var seg = []
        seg.push("M " + OR + ",0")
        seg.push("L " + (W - OR) + ",0")
        seg.push("A " + OR + "," + OR + " 0 0 1 " + W + "," + OR)

        if (rightFlush) {
            // dropdown's right edge = bar's right edge: one straight line
            seg.push("L " + W + "," + (yBottom - DR))
        } else {
            seg.push("L " + W + "," + (barH - OR))
            seg.push("A " + OR + "," + OR + " 0 0 1 " + (W - OR) + "," + barH)
            seg.push("L " + (dRight + NR) + "," + barH)
            seg.push("A " + NR + "," + NR + " 0 0 0 " + dRight + "," + (barH + NR))
            seg.push("L " + dRight + "," + (yBottom - DR))
        }

        seg.push("A " + DR + "," + DR + " 0 0 1 " + (dRight - DR) + "," + yBottom)
        seg.push("L " + (dLeft + DR) + "," + yBottom)
        seg.push("A " + DR + "," + DR + " 0 0 1 " + dLeft + "," + (yBottom - DR))

        if (leftFlush) {
            seg.push("L 0," + OR)
            seg.push("A " + OR + "," + OR + " 0 0 1 " + OR + ",0")
        } else {
            seg.push("L " + dLeft + "," + (barH + NR))
            seg.push("A " + NR + "," + NR + " 0 0 0 " + (dLeft - NR) + "," + barH)
            seg.push("L " + OR + "," + barH)
            seg.push("A " + OR + "," + OR + " 0 0 1 0," + (barH - OR))
            seg.push("L 0," + OR)
            seg.push("A " + OR + "," + OR + " 0 0 1 " + OR + ",0")
        }

        seg.push("Z")
        return seg.join(" ")
    }
}
