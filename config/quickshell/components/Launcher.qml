import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: root
    title: "Applications"
    visible: false
    width: 520
    height: 420
    color: "#111318"

    function rebuild(): void {
        const needle = search.text.toLowerCase()
        apps.values = DesktopEntries.applications.values.filter(entry =>
            needle.length === 0 || entry.name.toLowerCase().includes(needle))
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.visible = !root.visible
            if (root.visible) { search.text = ""; root.rebuild(); search.forceActiveFocus() }
        }
    }

    ScriptModel { id: apps; values: DesktopEntries.applications.values }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10
        TextInput {
            id: search
            width: parent.width
            height: 34
            color: "#c0caf5"
            font.pixelSize: 18
            onTextChanged: root.rebuild()
            Keys.onEscapePressed: root.visible = false
            Keys.onDownPressed: results.incrementCurrentIndex()
            Keys.onUpPressed: results.decrementCurrentIndex()
            Keys.onReturnPressed: {
                if (results.currentItem) results.currentItem.launch()
            }
        }
        ListView {
            id: results
            width: parent.width
            height: parent.height - search.height - parent.spacing
            clip: true
            model: apps
            currentIndex: count > 0 ? 0 : -1
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 36
                color: ListView.isCurrentItem ? "#24283b" : "transparent"
                function launch(): void { modelData.execute(); root.visible = false }
                Text { anchors.verticalCenter: parent.verticalCenter; text: row.modelData.name; color: "#c0caf5" }
                MouseArea { anchors.fill: parent; onClicked: row.launch() }
            }
        }
    }
}

