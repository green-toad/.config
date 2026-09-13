import QtQuick

// Universal dropdown drawer: a self-contained, positioned container
// that animates its own height open/closed and can be filled with any
// content. Doesn't know anything about Panel, bars, other dropdowns,
// or colors - drop as many of these into any parent as you like.
//
// Open/close is fully self-managed: hovering the dropdown itself keeps
// it open, and it closes itself after `closeDelay` once the mouse
// leaves. Whatever should *summon* it (a bar icon, a button...) just
// calls requestOpen()/requestClose() on it from the outside.
Item {
    id: root

    // --- geometry -------------------------------------------------
    // y-offset where the dropdown starts (typically the bar's height)
    property real originY: 0
    property real dropdownX: 0
    property real dropdownWidth: 500
    property real dropdownHeight: 320   // target height when expanded
    property int contentMargins: 10

    // --- behavior ---------------------------------------------------
    property bool expanded: false
    property int openAnimDuration: 180
    property int closeDelay: 800

    // Purely visual animation value - drives QML painting only.
    // Consumers (e.g. NotchShape) should read this, never dropdownHeight,
    // when they need the *current* height.
    property real animHeight: expanded ? dropdownHeight : 0
    Behavior on animHeight {
        NumberAnimation { duration: root.openAnimDuration; easing.type: Easing.OutCubic }
    }

    // Any children placed inside `DropDown { ... }` land here instead
    // of directly on root, so the content never has to care about
    // margins/positioning - just `anchors.fill: parent`.
    default property alias content: contentContainer.data

    function requestOpen() {
        closeTimer.stop()
        expanded = true
    }
    function requestClose() {
        closeTimer.restart()
    }

    Timer {
        id: closeTimer
        interval: root.closeDelay
        onTriggered: root.expanded = false
    }

    x: dropdownX
    y: originY
    width: dropdownWidth
    height: animHeight
    clip: true
    visible: expanded || opacity > 0
    opacity: expanded ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 140 } }

    HoverHandler {
        onHoveredChanged: hovered ? root.requestOpen() : root.requestClose()
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.contentMargins
    }
}
