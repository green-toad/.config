import QtQuick
import QtQuick.Shapes

// Draws the panel's background silhouette as a single filled path:
// a wide top bar with normal rounded corners, plus a concave "notch"
// dip below it for every currently-open dropdown. Fully decoupled
// from Panel/DropDown - it only needs each dropdown's x/width/height
// (and optionally its own corner radius) via the `dropdowns` list, so
// visually linking a second (or third...) dropdown to the bar is just
// adding another entry to that list.
//
// Whichever side of a dropdown touches the bar's own edge (x == 0, or
// x+width == barWidth) is drawn as a straight line - no notch needed
// there, since there's no "step" to smooth out. Between two dropdowns,
// or on a side that doesn't reach the bar's edge, the outline dips
// down to a rounded notch and back up to the flat bar baseline.
Shape {
    id: root

    // --- bar geometry -------------------------------------------------
    property real barWidth: 800
    property real barHeight: 30

    property real outerRadius: 14       // bar's own 4 corners
    property real notchRadius: 20       // concave transition radius (default, per-notch)
    property real dropdownRadius: 14    // dropdown bottom corners (default, per-drop)

    // --- dropdowns ------------------------------------------------------
    // List of currently-visible dropdowns to notch around, e.g.:
    //   [{ x: 0, width: 500, height: 320 },
    //    { x: 560, width: 200, height: 140, radius: 10 }]
    // `radius` per entry is optional and falls back to dropdownRadius.
    // Entries with height < 0.5 or width < 1 are treated as closed and
    // ignored - so a fully-collapsed dropdown just isn't there.
    property var dropdowns: []

    // --- appearance ---------------------------------------------------
    property color fillColor: "black"
    property color strokeColor: "transparent"
    property real strokeWidth: 0

    implicitWidth: barWidth
    implicitHeight: barHeight + maxDropHeight()

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

    function maxDropHeight() {
        var list = root.dropdowns || []
        var m = 0
        for (var i = 0; i < list.length; i++) {
            var h = list[i].height || 0
            if (h > m) m = h
        }
        return m
    }

    // Normalizes, clamps and sorts the active (non-collapsed) dropdowns
    // left-to-right, so buildPath() can just walk them in order.
    function activeDrops(W) {
        var list = root.dropdowns || []
        var out = []
        for (var i = 0; i < list.length; i++) {
            var d = list[i]
            var dH = Math.max(d.height || 0, 0)
            var dW = Math.min(Math.max(d.width || 0, 0), W)
            if (dH < 0.5 || dW < 1)
                continue
            var dX = Math.max(0, Math.min(d.x || 0, W - dW))
            out.push({
                x: dX,
                right: dX + dW,
                height: dH,
                radius: (d.radius !== undefined ? d.radius : root.dropdownRadius)
            })
        }
        out.sort(function (a, b) { return a.x - b.x })
        return out
    }

    function buildPath() {
        var BIG = 1e6 // "no constraint" sentinel for Math.min

        var W = Math.max(root.barWidth, 1)
        var barH = Math.max(root.barHeight, 0)
        var OR = Math.min(root.outerRadius, barH, W / 2)

        var drops = activeDrops(W)

        if (drops.length === 0) {
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

        var leftFlush = drops[0].x <= 0.5
        var rightFlush = drops[drops.length - 1].right >= W - 0.5

        // Per-drop notch/corner radii, bounded by the gap to whatever's
        // next to them (a neighbouring drop, or the bar's own edge).
        var geo = []
        for (var i = 0; i < drops.length; i++) {
            var d = drops[i]
            var prevRight = i === 0 ? 0 : drops[i - 1].right
            var nextX = i === drops.length - 1 ? W : drops[i + 1].x
            var leftGap = (i === 0 && leftFlush) ? BIG : (d.x - prevRight)
            var rightGap = (i === drops.length - 1 && rightFlush) ? BIG : (nextX - d.right)

            var NR = Math.max(0, Math.min(root.notchRadius, d.height / 2, leftGap, rightGap))
            var DR = Math.max(0, Math.min(d.radius, (d.right - d.x) / 2, Math.max(d.height - NR, 0)))

            geo.push({ x: d.x, right: d.right, height: d.height, NR: NR, DR: DR, yBottom: barH + d.height })
        }

        var seg = []
        seg.push("M " + OR + ",0")
        seg.push("L " + (W - OR) + ",0")
        seg.push("A " + OR + "," + OR + " 0 0 1 " + W + "," + OR)

        var last = geo[geo.length - 1]
        if (rightFlush) {
            // last dropdown's right edge = bar's right edge: one straight line
            seg.push("L " + W + "," + (last.yBottom - last.DR))
        } else {
            seg.push("L " + W + "," + (barH - OR))
            seg.push("A " + OR + "," + OR + " 0 0 1 " + (W - OR) + "," + barH)
        }

        // Walk the drops right-to-left along the bar's bottom baseline,
        // dipping into each notched drop and back up.
        for (var k = geo.length - 1; k >= 0; k--) {
            var g = geo[k]
            var isRightmost = (k === geo.length - 1)
            var isLeftmost = (k === 0)

            if (!(isRightmost && rightFlush)) {
                seg.push("L " + (g.right + g.NR) + "," + barH)
                seg.push("A " + g.NR + "," + g.NR + " 0 0 0 " + g.right + "," + (barH + g.NR))
            }

            seg.push("L " + g.right + "," + (g.yBottom - g.DR))
            seg.push("A " + g.DR + "," + g.DR + " 0 0 1 " + (g.right - g.DR) + "," + g.yBottom)
            seg.push("L " + (g.x + g.DR) + "," + g.yBottom)
            seg.push("A " + g.DR + "," + g.DR + " 0 0 1 " + g.x + "," + (g.yBottom - g.DR))

            if (isLeftmost && leftFlush) {
                seg.push("L 0," + OR)
                seg.push("A " + OR + "," + OR + " 0 0 1 " + OR + ",0")
            } else {
                seg.push("L " + g.x + "," + (barH + g.NR))
                seg.push("A " + g.NR + "," + g.NR + " 0 0 0 " + (g.x - g.NR) + "," + barH)
            }
        }

        if (!leftFlush) {
            seg.push("L " + OR + "," + barH)
            seg.push("A " + OR + "," + OR + " 0 0 1 0," + (barH - OR))
            seg.push("L 0," + OR)
            seg.push("A " + OR + "," + OR + " 0 0 1 " + OR + ",0")
        }

        seg.push("Z")
        return seg.join(" ")
    }
}
