//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

Scope {
    Variants {
        model: Quickshell.screens;

        PanelWindow {
            id: mainWindow 
            required property var modelData
            screen: modelData

            implicitHeight: 27
            implicitWidth: 800

            color: Qt.rgba(0.2, 0.2, 0.2)

            anchors {
                top: true
            }

            // рабочие столы
            MyWorkspaceRow {}

            MyTrayRow {
                mainWindow: mainWindow 
            }
        }
    }
}