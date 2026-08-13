import QtQuick
import Quickshell.Io

Text {
    id: root
    property bool connected: false
    text: connected ? "online" : "offline"
    color: connected ? "#9ece6a" : "#f7768e"

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
            return "source=NetworkManager-events;monitorPid=" + monitor.processId + ";connected=" + root.connected + ";label=" + root.text
        }
    }
}
