import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Rectangle {
    id: root
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool muted: source && source.audio ? source.audio.muted : false
    implicitWidth: 28; implicitHeight: 28; radius: 8
    color: micMouse.containsMouse ? "#45475a" : "transparent"
    PwObjectTracker { objects: [Pipewire.defaultAudioSource] }
    Text { anchors.centerIn: parent; text: root.muted ? "󰍭" : "󰍬"; color: root.muted ? "#f38ba8" : "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 12 }
    Process { id: action }
    MouseArea {
        id: micMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: { action.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]; action.running = true }
    }
}
