import QtQuick
import QtQuick.Shapes

// Draws the panel's background silhouette as a single filled path:
// a wide top bar with normal rounded corners, plus a concave "notch"
// dip below it for every currently-open dropdown. Overlapping dropdowns
// are merged into one outline (see skyline()). Fully decoupled
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

    // Силуэт "бар + все дропдауны" как профиль-гистограмма: на каждом
    // участке по X берётся высота самого высокого дропдауна над ним.
    // Благодаря этому дропдауны могут перекрываться (лаунчер + звук,
    // закрывающийся + открывающийся) - контур всегда остаётся цельным.
    function skyline(W) {
        var drops = activeDrops(W)
        var pts = [0, W]
        for (var i = 0; i < drops.length; i++) {
            pts.push(drops[i].x)
            pts.push(drops[i].right)
        }
        pts.sort(function (a, b) { return a - b })

        var segs = []
        for (var j = 0; j < pts.length - 1; j++) {
            var a = pts[j]
            var b = pts[j + 1]
            if (b - a < 0.01) continue
            var mid = (a + b) / 2
            var h = 0
            for (var k = 0; k < drops.length; k++) {
                if (drops[k].x <= mid && mid <= drops[k].right && drops[k].height > h)
                    h = drops[k].height
            }
            if (h < 0.5) h = 0
            var last = segs.length - 1
            if (last >= 0 && Math.abs(segs[last].h - h) < 0.01)
                segs[last].b = b
            else
                segs.push({ a: a, b: b, h: h })
        }
        return segs
    }

    function buildPath() {
        var EPS = 0.5
        var W = Math.max(root.barWidth, 1)
        var barH = Math.max(root.barHeight, 0)
        var OR = Math.min(root.outerRadius, barH, W / 2)
        var NR0 = root.notchRadius
        var DR0 = root.dropdownRadius

        var segs = skyline(W)
        var n = segs.length
        var i

        // Переходы между соседними участками. c - вогнутый радиус на
        // низком участке, v - выпуклый на высоком; up = правый участок выше.
        var tr = []
        for (i = 0; i < n - 1; i++) {
            var d = Math.abs(segs[i].h - segs[i + 1].h)
            var c = Math.min(NR0, d / 2)
            var v = Math.min(DR0, d - c)
            tr.push({ t: segs[i].b, up: segs[i + 1].h > segs[i].h, c: c, v: v })
        }
        var edgeL = segs[0].h >= EPS ? Math.min(DR0, segs[0].h) : 0
        var edgeR = segs[n - 1].h >= EPS ? Math.min(DR0, segs[n - 1].h) : 0

        // Радиусы не должны в сумме превышать ширину участка
        for (i = 0; i < n; i++) {
            var w = segs[i].b - segs[i].a
            var fixed = 0
            var mov = 0
            if (i === 0) { if (segs[0].h < EPS) fixed += OR; else mov += edgeL }
            else mov += tr[i - 1].up ? tr[i - 1].v : tr[i - 1].c
            if (i === n - 1) { if (segs[i].h < EPS) fixed += OR; else mov += edgeR }
            else mov += tr[i].up ? tr[i].c : tr[i].v

            var sc = mov > 0 ? Math.max(0, Math.min(1, (w - fixed) / mov)) : 1
            if (sc < 1) {
                if (i === 0) { if (segs[0].h >= EPS) edgeL *= sc }
                else if (tr[i - 1].up) tr[i - 1].v *= sc
                else tr[i - 1].c *= sc

                if (i === n - 1) { if (segs[i].h >= EPS) edgeR *= sc }
                else if (tr[i].up) tr[i].c *= sc
                else tr[i].v *= sc
            }
        }

        var seg = []
        seg.push("M " + OR + ",0")
        seg.push("L " + (W - OR) + ",0")
        seg.push("A " + OR + "," + OR + " 0 0 1 " + W + "," + OR)

        // правый край
        var yLast = barH + segs[n - 1].h
        if (segs[n - 1].h < EPS) {
            seg.push("L " + W + "," + (barH - OR))
            seg.push("A " + OR + "," + OR + " 0 0 1 " + (W - OR) + "," + barH)
        } else {
            seg.push("L " + W + "," + (yLast - edgeR))
            seg.push("A " + edgeR + "," + edgeR + " 0 0 1 " + (W - edgeR) + "," + yLast)
        }

        // справа налево по нижней границе профиля
        for (i = n - 1; i >= 1; i--) {
            var t = tr[i - 1]
            var yR = barH + segs[i].h
            var yL = barH + segs[i - 1].h
            if (t.up) {
                // текущий участок выше: выпуклый угол, стенка вверх, вогнутый угол
                seg.push("L " + (t.t + t.v) + "," + yR)
                seg.push("A " + t.v + "," + t.v + " 0 0 1 " + t.t + "," + (yR - t.v))
                seg.push("L " + t.t + "," + (yL + t.c))
                seg.push("A " + t.c + "," + t.c + " 0 0 0 " + (t.t - t.c) + "," + yL)
            } else {
                // текущий участок ниже: вогнутый угол, стенка вниз, выпуклый угол
                seg.push("L " + (t.t + t.c) + "," + yR)
                seg.push("A " + t.c + "," + t.c + " 0 0 0 " + t.t + "," + (yR + t.c))
                seg.push("L " + t.t + "," + (yL - t.v))
                seg.push("A " + t.v + "," + t.v + " 0 0 1 " + (t.t - t.v) + "," + yL)
            }
        }

        // левый край
        var y0 = barH + segs[0].h
        if (segs[0].h < EPS) {
            seg.push("L " + OR + "," + barH)
            seg.push("A " + OR + "," + OR + " 0 0 1 0," + (barH - OR))
        } else {
            seg.push("L " + edgeL + "," + y0)
            seg.push("A " + edgeL + "," + edgeL + " 0 0 1 0," + (y0 - edgeL))
        }
        seg.push("L 0," + OR)
        seg.push("A " + OR + "," + OR + " 0 0 1 " + OR + ",0")
        seg.push("Z")
        return seg.join(" ")
    }
}
