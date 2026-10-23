import QtQuick

// Keyboard-driven table of strings. The table has its own logical size
// (columns x rows of fixed-size cells) which may be larger than the view
// in both directions; only cells that intersect the view are instantiated,
// everything else simply isn't created/drawn. Arrow keys move the
// selection, the view scrolls (animated) to keep it visible.
FocusScope {
    id: root

    property var colors
    property var items: []

    property real cellWidth: 136
    property real cellHeight: 42
    property real spacing: 6
    // 0 = auto (as many columns as fit the width)
    property int columnsSetting: 0

    property int currentIndex: 0

    signal chosen(string text)

    clip: true

    // --- table geometry --------------------------------------------------
    readonly property int count: items ? items.length : 0
    readonly property real stepX: cellWidth + spacing
    readonly property real stepY: cellHeight + spacing
    readonly property int columns: columnsSetting > 0
        ? columnsSetting
        : Math.max(1, Math.floor((width + spacing) / stepX))
    readonly property int rows: Math.ceil(count / columns)
    readonly property real contentW: columns * stepX - spacing
    readonly property real contentH: rows * stepY - spacing
    readonly property real maxScrollX: Math.max(0, contentW - width)
    readonly property real maxScrollY: Math.max(0, contentH - height)

    // --- scrolling ---------------------------------------------------------
    property real targetX: 0
    property real targetY: 0
    property real scrollX: targetX
    property real scrollY: targetY
    Behavior on scrollX { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on scrollY { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    onMaxScrollXChanged: targetX = Math.min(targetX, maxScrollX)
    onMaxScrollYChanged: targetY = Math.min(targetY, maxScrollY)
    onCountChanged: if (currentIndex >= count) currentIndex = Math.max(0, count - 1)

    // --- visible window of cells --------------------------------------------
    readonly property int firstCol: Math.max(0, Math.floor(scrollX / stepX))
    readonly property int lastCol: Math.min(columns - 1, Math.floor((scrollX + width) / stepX))
    readonly property int firstRow: Math.max(0, Math.floor(scrollY / stepY))
    readonly property int lastRow: Math.min(rows - 1, Math.floor((scrollY + height) / stepY))
    readonly property int visCols: Math.max(0, lastCol - firstCol + 1)
    readonly property int visRows: Math.max(0, lastRow - firstRow + 1)

    function clamp(v, lo, hi) { return Math.max(lo, Math.min(v, hi)) }

    function reset() {
        currentIndex = 0
        targetX = 0
        targetY = 0
    }

    function ensureVisible() {
        if (count === 0)
            return
        var c = currentIndex % columns
        var r = Math.floor(currentIndex / columns)
        var left = c * stepX, right = left + cellWidth
        var top = r * stepY, bottom = top + cellHeight

        var tx = targetX, ty = targetY
        if (left < tx) tx = left
        else if (right > tx + width) tx = right - width
        if (top < ty) ty = top
        else if (bottom > ty + height) ty = bottom - height

        targetX = clamp(tx, 0, maxScrollX)
        targetY = clamp(ty, 0, maxScrollY)
    }

    function select(i) {
        if (count === 0)
            return
        currentIndex = clamp(i, 0, count - 1)
        ensureVisible()
    }

    function move(dx, dy) {
        if (count === 0)
            return
        var c = currentIndex % columns
        var r = Math.floor(currentIndex / columns)
        var nc = clamp(c + dx, 0, columns - 1)
        var nr = clamp(r + dy, 0, rows - 1)
        var ni = nr * columns + nc
        if (ni >= count)
            ni = dy !== 0 ? count - 1 : currentIndex // partial last row
        select(ni)
    }

    function choose() {
        if (currentIndex >= 0 && currentIndex < count)
            chosen(items[currentIndex])
    }

    Keys.onPressed: (event) => {
        switch (event.key) {
        case Qt.Key_Left:  move(-1, 0); break
        case Qt.Key_Right: move(1, 0); break
        case Qt.Key_Up:    move(0, -1); break
        case Qt.Key_Down:  move(0, 1); break
        case Qt.Key_Home:  select(0); break
        case Qt.Key_End:   select(count - 1); break
        case Qt.Key_Return:
        case Qt.Key_Enter: choose(); break
        default: return
        }
        event.accepted = true
    }

    WheelHandler {
        onWheel: (e) => {
            var horizontal = (e.modifiers & Qt.ShiftModifier) !== 0
            var dy = horizontal ? 0 : e.angleDelta.y
            var dx = horizontal ? e.angleDelta.y : e.angleDelta.x
            root.targetY = root.clamp(root.targetY - dy, 0, root.maxScrollY)
            root.targetX = root.clamp(root.targetX - dx, 0, root.maxScrollX)
        }
    }

    Repeater {
        model: root.visCols * root.visRows

        delegate: Rectangle {
            id: cell

            required property int index

            readonly property int col: root.firstCol + index % root.visCols
            readonly property int row: root.firstRow + Math.floor(index / root.visCols)
            readonly property int cellIndex: row * root.columns + col
            readonly property bool current: cellIndex === root.currentIndex

            visible: cellIndex < root.count
            x: col * root.stepX - root.scrollX
            y: row * root.stepY - root.scrollY
            width: root.cellWidth
            height: root.cellHeight
            radius: 8
            color: current ? root.colors.color6 : root.colors.color2

            Text {
                anchors.fill: parent
                anchors.margins: 6
                text: cell.cellIndex < root.count ? root.items[cell.cellIndex] : ""
                textFormat: Text.PlainText
                color: cell.current ? root.colors.color0 : root.colors.color7
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 15
                fontSizeMode: Text.Fit
                minimumPixelSize: 9
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                // positionChanged (not entered): a window that appears under
                // a resting cursor must not steal the selection.
                onPositionChanged: root.currentIndex = cell.cellIndex
                onClicked: {
                    root.currentIndex = cell.cellIndex
                    root.choose()
                }
            }
        }
    }
}
