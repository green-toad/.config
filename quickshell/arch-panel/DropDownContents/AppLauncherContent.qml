import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property var colors

    signal appLaunched()

    property string searchText: ""

    property var filteredApps: {
        var q = root.searchText.toLowerCase().trim()
        var all = DesktopEntries.applications.values
        if (q.length === 0)
            return all
        var out = []
        for (var i = 0; i < all.length; i++) {
            var e = all[i]
            var hay = ((e.name || "") + " " + (e.genericName || "") + " " +
                       (e.comment || "") + " " + (e.keywords || []).join(" ")).toLowerCase()
            if (hay.indexOf(q) !== -1)
                out.push(e)
        }
        return out
    }

    onFilteredAppsChanged: appList.currentIndex = filteredApps.length > 0 ? 0 : -1

    function launch(entry) {
        if (!entry)
            return
        entry.execute()
        root.appLaunched()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.filteredApps
            highlightMoveDuration: 80

            delegate: Rectangle {
                width: appList.width
                height: 44
                radius: 8
                color: ListView.isCurrentItem ? root.colors.color4 : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    IconImage {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        source: modelData.icon ? Quickshell.iconPath(modelData.icon) : ""
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: root.colors.color7
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: modelData.genericName
                            color: root.colors.color7
                            opacity: 0.6
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: appList.currentIndex = index
                    onClicked: root.launch(modelData)
                }
            }
        }

        TextField {
            id: searchField
            Layout.fillWidth: true
            focus: true
            placeholderText: "Искать приложение..."

            onTextChanged: root.searchText = text
            onAccepted: root.launch(root.filteredApps[appList.currentIndex])

            onActiveFocusChanged: if (activeFocus) text = ""

            Keys.onDownPressed: appList.currentIndex =
                Math.min(appList.currentIndex + 1, root.filteredApps.length - 1)
            Keys.onUpPressed: appList.currentIndex =
                Math.max(appList.currentIndex - 1, 0)
        }
    }
}
