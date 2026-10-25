pragma Singleton
import QtQuick
import Quickshell

// Общее состояние, которым делятся виджеты и сама панель.
Singleton {
    // Сколько контекстных меню трея открыто сейчас: пока > 0 панель
    // не сворачивается (иначе меню пропадёт вместе с иконкой).
    property int openTrayMenus: 0
}
