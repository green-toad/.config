import Quickshell
import Quickshell.Io
import QtQuick

Scope
{
    readonly property string time: {
        Qt.formatDateTime(clock.date, "hh\nmm")
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}