import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: root
    title: "Clipboard"
    visible: false
    implicitWidth: 620
    implicitHeight: 480
    color: "transparent"
    property var entries: []

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.toggle() }
    }

    function toggle(): void {
        if (visible) visible = false
        else {
            visible = true
            search.text = ""
            history.running = true
            search.forceActiveFocus()
        }
    }

    function loadEntries(raw: string): void {
        const lines = raw.trim().length ? raw.trim().split("\n") : []
        entries = lines.map(line => {
            const tab = line.indexOf("\t")
            return { id: tab >= 0 ? line.slice(0, tab) : line, preview: tab >= 0 ? line.slice(tab + 1) : line }
        })
        rebuild()
    }

    function rebuild(): void {
        const needle = search.text.toLowerCase()
        filtered.values = entries.filter(entry => !needle || entry.preview.toLowerCase().includes(needle))
    }

    function paste(id: string): void {
        if (!/^\d+$/.test(id)) return
        root.visible = false
        pasteAction.command = ["sh", "-c", "cliphist decode " + id + " | wl-copy; wtype -d 120 -M ctrl -P v -p v -m ctrl"]
        pasteAction.running = true
    }

    Process {
        id: history
        command: ["cliphist", "list"]
        stdout: StdioCollector { id: historyOutput }
        onExited: root.loadEntries(historyOutput.text)
    }
    Process { id: pasteAction }
    ScriptModel { id: filtered; values: [] }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#181825"
        border.width: 1
        border.color: "#45475a"

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Text { text: "󰅇  Portapapeles"; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 17; font.bold: true }

            Rectangle {
                width: parent.width; height: 44; radius: 10; color: "#313244"
                border.width: search.activeFocus ? 1 : 0; border.color: "#cba6f7"
                Text { anchors.left: parent.left; anchors.leftMargin: 13; anchors.verticalCenter: parent.verticalCenter; text: "󰍉"; color: "#cba6f7"; font.family: "Cascadia Mono NF"; font.pixelSize: 16 }
                TextInput {
                    id: search
                    anchors.left: parent.left; anchors.leftMargin: 42; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                    color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 14; clip: true
                    onTextChanged: root.rebuild()
                    Keys.onEscapePressed: root.visible = false
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onReturnPressed: if (list.currentItem) list.currentItem.choose()
                }
                Text { visible: !search.text.length; anchors.left: parent.left; anchors.leftMargin: 42; anchors.verticalCenter: parent.verticalCenter; text: "Buscar en el historial…"; color: "#6c7086"; font.family: "Cascadia Mono NF"; font.pixelSize: 13 }
            }

            ListView {
                id: list
                width: parent.width; height: parent.height - 93
                model: filtered; clip: true; spacing: 5
                currentIndex: count ? 0 : -1
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: ListView.view.width; height: 52; radius: 10
                    color: ListView.isCurrentItem || rowMouse.containsMouse ? "#313244" : "transparent"
                    function choose(): void { root.paste(modelData.id) }
                    Text { anchors.left: parent.left; anchors.leftMargin: 13; anchors.verticalCenter: parent.verticalCenter; text: row.modelData.preview.startsWith("[[ binary data") ? "󰋩" : "󰅇"; color: "#89b4fa"; font.family: "Cascadia Mono NF"; font.pixelSize: 16 }
                    Text { anchors.left: parent.left; anchors.leftMargin: 44; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: row.modelData.preview.replace(/\s+/g, " "); color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 12; elide: Text.ElideRight }
                    MouseArea { id: rowMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: list.currentIndex = row.index; onClicked: row.choose() }
                }
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            }
        }
    }
}
