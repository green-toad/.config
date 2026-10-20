import QtQuick

// Universal dropdown drawer: a self-contained, positioned container
// that animates its own height open/closed and can be filled with any
// content. Doesn't know anything about Panel, bars, other dropdowns,
// or colors - drop as many of these into any parent as you like.
//
// Open/close is self-managed: hovering the dropdown keeps it open and
// (optionally) it closes itself after `closeDelay` once the mouse
// leaves. Whatever should *summon* it (a bar icon, an IPC call...)
// calls requestOpen()/requestClose()/toggle() on it from the outside.
// It's also a FocusScope, so Escape closes it and any child with
// `focus: true` (e.g. a search field) is refocused every time it opens.
FocusScope {
    id: root

    // --- geometry -------------------------------------------------
    // y-offset where the dropdown starts (typically the bar's height)
    property real originY: 0
    property real dropdownX: 0
    property real dropdownWidth: 500
    property real dropdownHeight: 1000
    property int contentMargins: 10

    // --- behavior ---------------------------------------------------
    property bool expanded: false
    property int openAnimDuration: 180
    property int closeDelay: 800
    // Whether losing mouse hover should schedule an auto-close.
    // Fine for a hover-triggered bar dropdown; turn off for something
    // opened via hotkey/IPC that's driven by the keyboard instead
    // (e.g. an app launcher) - it should only close on Escape/toggle.
    property bool closeOnHoverLeave: true
    // Открываться по наведению курсора на сам дропдаун (для лаунчера выключено)
    property bool hoverOpens: true
    // Забирать клавиатурный фокус при открытии (бар-дропдауны не должны
    // отбирать фокус у поля поиска лаунчера, когда рисуются поверх него)
    property bool takeFocus: true
    // При открытии подниматься над соседями: открывающийся дропдаун
    // всегда рисуется поверх закрывающегося
    property bool raiseOnOpen: true

    // --- внешний вид (по умолчанию ничего не рисуем) ---------------------
    // Непрозрачная подложка нужна, чтобы дропдаун полностью перекрывал то,
    // что лежит под ним (другой дропдаун, лаунчер).
    property color backgroundColor: "transparent"
    property color borderColor: "transparent"
    property bool showBorder: false
    property real cornerRadius: 14

    // Purely visual animation value - drives QML painting only.
    // Consumers (e.g. NotchShape) should read this, never dropdownHeight,
    // when they need the *current* height.
    // NOTE: must NOT be `readonly` - Behavior needs to assign to it on
    // every change (that's literally how it animates the transition).
    property real animHeight: expanded ? dropdownHeight : 0
    Behavior on animHeight {
        NumberAnimation { duration: root.openAnimDuration; easing.type: Easing.OutCubic }
    }

    default property alias content: contentContainer.data

    function raise() {
        var sib = root.parent ? root.parent.children : []
        var m = 0
        for (var i = 0; i < sib.length; i++) {
            if (sib[i] !== root && sib[i].z > m) m = sib[i].z
        }
        root.z = m + 1
    }
    function requestOpen() {
        closeTimer.stop()
        if (!expanded && raiseOnOpen) raise()
        expanded = true
    }
    function requestClose() {
        closeTimer.restart()
    }
    function requestHardClose(){
        root.expanded = false
    }
    function toggle() {
        if (expanded) {
            closeTimer.stop()
            expanded = false
        } else {
            requestOpen()
        }
    }

    onExpandedChanged: if (expanded && root.takeFocus) root.forceActiveFocus()
    Keys.onEscapePressed: root.requestClose()

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

    // Подложка: верх прямой (уходит под бар за clip), низ скруглён
    Rectangle {
        z: -1
        x: 0
        y: -root.cornerRadius
        width: parent.width
        height: parent.height + root.cornerRadius
        radius: root.cornerRadius
        color: root.backgroundColor
        border.width: root.showBorder ? 1 : 0
        border.color: root.borderColor
    }

    HoverHandler {
        enabled: root.hoverOpens
        onHoveredChanged: {
            if (hovered)
                root.requestOpen()
            else if (root.closeOnHoverLeave)
                root.requestClose()
        }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.contentMargins
    }
}
