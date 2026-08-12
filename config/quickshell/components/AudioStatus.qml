import QtQuick
import Quickshell.Services.Pipewire

Text {
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    text: !sink || !sink.audio ? "audio —" : (sink.audio.muted ? "muted" : "vol " + Math.round(sink.audio.volume * 100) + "%")
    color: "#c0caf5"
}

