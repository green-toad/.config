pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Выбор "активного" MPRIS-плеера: играющий в приоритете, иначе тот,
// что был активным последним, иначе первый в списке.
Singleton {
    id: root

    readonly property var all: Mpris.players.values
    property var _last: null

    readonly property var active: {
        const list = root.all
        for (let i = 0; i < list.length; i++) {
            if (list[i].playbackState === MprisPlaybackState.Playing)
                return list[i]
        }
        if (root._last && list.indexOf(root._last) !== -1)
            return root._last
        return list.length > 0 ? list[0] : null
    }

    // Некоторые источники (YouTube в браузере) отдают в mpris:length не
    // длительность видео, а длину буфера - она растёт по мере загрузки.
    // Если длина у одного и того же трека выросла дважды - считаем её
    // недостоверной и не рисуем по ней прогресс.
    property real _lastLen: 0
    property int _growth: 0
    readonly property bool lengthUnreliable: _growth >= 2
    readonly property bool lengthKnown: active !== null && active.lengthSupported
                                        && active.length > 0 && !lengthUnreliable

    function _resetLength() {
        _growth = 0
        _lastLen = active ? active.length : 0
    }

    onActiveChanged: {
        if (active) _last = active
        _resetLength()
    }

    Connections {
        target: root.active
        ignoreUnknownSignals: true
        function onTrackTitleChanged() { root._resetLength() }
        function onLengthChanged() {
            const len = root.active ? root.active.length : 0
            if (root._lastLen > 0 && len > root._lastLen + 1) root._growth++
            root._lastLen = len
        }
    }

    // Перемотка на offset секунд (отрицательное = назад)
    function seekBy(offset) {
        const p = root.active
        if (p && p.canSeek) p.seek(offset)
    }
}
