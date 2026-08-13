import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire

Rectangle {
    id: root
    signal activated()
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    implicitWidth: label.implicitWidth + 14
    implicitHeight: 28
    radius: 8
    color: mouse.containsMouse ? "#45475a" : "transparent"
    Behavior on color { ColorAnimation { duration: 160 } }
    Text {
        id: label
        anchors.centerIn: parent
        text: !root.sink || !root.sink.audio ? "󰖁  —" : (root.sink.audio.muted ? "󰖁  muted" : "󰕾  " + Math.round(root.sink.audio.volume * 100) + "%")
        color: root.sink && root.sink.audio && root.sink.audio.muted ? "#f38ba8" : "#cdd6f4"
        font.family: "Cascadia Mono NF"
        font.pixelSize: 13
    }
    Process { id: volumeAction }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton) {
                volumeAction.command = ["pavucontrol"]
                volumeAction.running = true
            } else root.activated()
        }
        onWheel: wheel => {
            volumeAction.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", wheel.angleDelta.y > 0 ? "5%+" : "5%-"]
            volumeAction.running = true
        }
    }
}
