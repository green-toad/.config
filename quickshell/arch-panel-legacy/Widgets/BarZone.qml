import QtQuick

// Зона бара (left / center / right): ряд виджетов из списка конфига.
Row {
    id: root

    property var model: []
    property string zone: "left"
    property int barHeight: 30

    signal openDropdown(string name, Item anchorItem, string zone)

    height: barHeight

    Repeater {
        model: root.model
        delegate: BarWidget {
            required property var modelData
            spec: modelData
            barHeight: root.barHeight
            onOpenDropdown: (name, item) => root.openDropdown(name, item, root.zone)
        }
    }
}
