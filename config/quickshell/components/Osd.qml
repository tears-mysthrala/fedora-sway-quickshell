import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

PanelWindow {
    id: root
    anchors { bottom: true }
    margins.bottom: 80
    implicitWidth: 260
    implicitHeight: 56
    visible: false
    color: "#313244"
    property string label: ""

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    IpcHandler {
        target: "osd"
        function volume(): void {
            const sink = Pipewire.defaultAudioSink
            root.label = !sink || !sink.audio ? "󰖁  Audio unavailable" : (sink.audio.muted ? "󰖁  Muted" : "󰕾  Volume " + Math.round(sink.audio.volume * 100) + "%")
            root.visible = true
            hide.restart()
        }
        function brightness(): void {
            root.label = "󰃠  Brightness changed"
            root.visible = true
            hide.restart()
        }
    }
    Timer { id: hide; interval: 1200; repeat: false; onTriggered: root.visible = false }
    Text { anchors.centerIn: parent; text: root.label; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 14; font.weight: Font.DemiBold }
}
