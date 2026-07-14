import Quickshell
import Quickshell.Io
import QtQuick

Scope
{
    id: root
    property variant bars: []

    Process
    {
        id: cavaReader
        //command: ["cava", "-p", "/home/nyashka/.config/cava/config"]
        //command: ["cava"]
        command: ["sh", "-c", "while true; do echo '10;20;30;40;50;60;70;80;90;100'; sleep 0.2; done"]
        running: true

        stderr: StdioCollector {
        onStreamFinished: console.warn("Cava stderr:", this.text)
    }

        stdout: SplitParser 
        {
            splitMarker: "\n"
            onRead: (frameData) => 
            {
                console.debug("Cava frame:", frameData)
                var parts = frameData.split(";")
                var numbers = []
                for (var i = 0; i < parts.length; i++) {
                    var val = parseInt(parts[i])
                    if (!isNaN(val)) numbers.push(val)
                }

                root.bars = numbers
            }
        }
    }
}