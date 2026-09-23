import QtQuick
import Quickshell.Io

// Niri compositor state for the bar, following the same event-driven pattern
// as the NetworkStatus `nmcli monitor` listener: one long-lived
// `niri msg --json event-stream` process plus one bounded query per real
// event. No polling. Inactive on the Sway session (the probe fails there
// and the stream never starts).
QtObject {
    id: root
    property bool active: false
    property string activeTitle: ""
    property ListModel workspaces: ListModel {}

    function focusWorkspace(ref: string): void {
        focusTarget = String(ref)
        if (!focusProc.running)
            focusProc.running = true
    }

    property string focusTarget: ""

    function refreshTitle(): void {
        if (root.active && !titleQuery.running)
            titleQuery.running = true
    }

    function rebuildWorkspaces(items: var): void {
        workspaces.clear()
        for (const item of items || []) {
            // Unnamed workspaces fall back to the 1-based position because
            // `focus-workspace` addresses workspaces by 1-based position
            // while IPC `idx` is 0-based. Label and ref stay identical so
            // the bar activates exactly the workspace it displays.
            const label = item.name ?? String((item.idx ?? 0) + 1)
            workspaces.append({
                name: label,
                focused: item.is_focused === true,
                urgent: item.is_urgent === true,
                ref: label,
                wsId: item.id ?? -1
            })
        }
        refreshTitle()
    }

    function markFocused(wsId: number): void {
        for (let i = 0; i < workspaces.count; i++)
            workspaces.setProperty(i, "focused", workspaces.get(i).wsId === wsId)
        refreshTitle()
    }

    function markUrgent(wsId: number, urgent: boolean): void {
        for (let i = 0; i < workspaces.count; i++) {
            if (workspaces.get(i).wsId === wsId) {
                workspaces.setProperty(i, "urgent", urgent)
                break
            }
        }
    }

    function handleEvent(line: string): void {
        let event = null
        try {
            event = JSON.parse(line)
        } catch (e) {
            return
        }
        if (!event)
            return
        if (event.WorkspacesChanged)
            rebuildWorkspaces(event.WorkspacesChanged.workspaces)
        else if (event.WorkspaceActivated && event.WorkspaceActivated.focused === true)
            markFocused(event.WorkspaceActivated.id ?? -1)
        else if (event.WorkspaceUrgencyChanged)
            markUrgent(event.WorkspaceUrgencyChanged.id ?? -1, event.WorkspaceUrgencyChanged.urgent === true)
        else if (event.WindowFocusChanged || event.WindowsChanged || event.WindowOpenedOrChanged || event.WorkspaceActiveWindowChanged)
            refreshTitle()
    }

    // Probe: succeeds only inside a Niri session.
    Process {
        id: probe
        command: ["niri", "msg", "--json", "outputs"]
        running: true
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            root.active = exitCode === 0
        }
    }

    Process {
        id: stream
        command: ["niri", "msg", "--json", "event-stream"]
        running: root.active
        stdout: SplitParser {
            onRead: data => root.handleEvent(data)
        }
    }

    Process {
        id: titleQuery
        command: ["niri", "msg", "--json", "focused-window"]
        stdout: StdioCollector { id: titleOutput }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                return
            let focused = null
            try {
                focused = JSON.parse(titleOutput.text)
            } catch (e) {
                return
            }
            root.activeTitle = (focused && (focused.title || focused.app_id)) || ""
        }
    }

    Process {
        id: focusProc
        command: ["niri", "msg", "action", "focus-workspace", root.focusTarget]
        stdout: StdioCollector {}
    }
}
