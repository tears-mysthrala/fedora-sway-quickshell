import QtQuick
import Quickshell.Io

Rectangle {
    id: root
    signal activated()
    property bool connected: false
    implicitWidth: label.implicitWidth + 14
    implicitHeight: 28
    radius: 8
    color: mouse.containsMouse ? "#45475a" : "transparent"
    Behavior on color { ColorAnimation { duration: 200 } }
    Text { id: label; anchors.centerIn: parent; text: root.connected ? "󰤨  online" : "󰤭  offline"; color: root.connected ? "#a6e3a1" : "#f38ba8"; font.family: "Cascadia Mono NF"; font.pixelSize: 13 }
    Process { id: editor; command: ["nm-connection-editor"] }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor; onClicked: event => { if (event.button === Qt.RightButton) editor.running = true; else root.activated() } }

    function refresh(): void {
        if (!query.running)
            query.running = true
    }

    Component.onCompleted: refresh()

    // Fedora 44's Quickshell 0.2.1 NetworkManager backend initializes but
    // exposes no Ethernet rows in the acceptance VM. `nmcli monitor` is a
    // persistent D-Bus event listener, not a polling loop. Each real NM event
    // triggers one bounded status query.
    Process {
        id: monitor
        command: ["nmcli", "monitor"]
        environment: ({ "LC_ALL": "C" })
        running: true
        stdout: SplitParser { onRead: root.refresh() }
    }

    Process {
        id: query
        command: ["nmcli", "-t", "-f", "STATE", "general", "status"]
        environment: ({ "LC_ALL": "C" })
        stdout: StdioCollector { id: queryOutput }
        onExited: (exitCode, exitStatus) => {
            root.connected = exitCode === 0 && queryOutput.text.trim() === "connected"
        }
    }

    IpcHandler {
        target: "network"
        function snapshot(): string {
            return "source=NetworkManager-events;monitorPid=" + monitor.processId + ";connected=" + root.connected + ";label=" + label.text
        }
    }
}
