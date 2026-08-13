import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    property string capture: ""
    visible: capture.length > 0
    implicitWidth: visible ? label.implicitWidth + 14 : 0
    implicitHeight: 28; radius: 8
    color: "#45475a"

    Text {
        id: label; anchors.centerIn: parent
        text: root.capture === "both" ? "󰍬  󰄀" : root.capture === "audio" ? "󰍬  MIC" : "󰄀  LIVE"
        color: "#f38ba8"; font.family: "Cascadia Mono NF"; font.pixelSize: 11; font.bold: true
    }

    function refresh(): void { if (!query.running) query.running = true }
    Component.onCompleted: refresh()

    Process {
        id: monitor
        command: ["pw-mon"]
        running: true
        stdout: SplitParser { onRead: root.refresh() }
    }
    Process {
        id: query
        command: ["sh", "-c", "pw-dump | jq -r '[.[] | select(.type == \"PipeWire:Interface:Node\" and .info.state == \"running\") | .info.props[\"media.class\"] // \"\"] | (if (any(.[]; . == \"Stream/Input/Audio\")) then \"audio\" else \"\" end) + (if (any(.[]; . == \"Stream/Input/Video\")) then \" video\" else \"\" end)' "]
        stdout: StdioCollector { id: queryOutput }
        onExited: {
            const value = queryOutput.text.trim()
            root.capture = value.indexOf("audio") >= 0 && value.indexOf("video") >= 0 ? "both" : value.indexOf("audio") >= 0 ? "audio" : value.indexOf("video") >= 0 ? "video" : ""
        }
    }
}
