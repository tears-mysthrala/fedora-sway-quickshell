import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

FloatingWindow {
    id: root
    title: "Applications"
    visible: false
    implicitWidth: 600
    implicitHeight: 480
    color: "transparent"

    function toggle(): void {
        root.visible = !root.visible
        if (root.visible) { search.text = ""; root.rebuild(); search.forceActiveFocus() }
    }

    function rebuild(): void {
        const needle = search.text.trim().toLowerCase()
        apps.values = DesktopEntries.applications.values.filter(entry => {
            const haystack = (entry.name + " " + (entry.comment || "") + " " + (entry.genericName || "")).toLowerCase()
            return needle.length === 0 || haystack.includes(needle)
        }).sort((a, b) => a.name.localeCompare(b.name))
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
    }

    ScriptModel { id: apps; values: DesktopEntries.applications.values }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        radius: 14
        border.width: 1
        border.color: "#45475a"

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            Rectangle {
                width: parent.width
                height: 46
                radius: 10
                color: "#313244"
                border.width: search.activeFocus ? 1 : 0
                border.color: "#cba6f7"
                Behavior on border.color { ColorAnimation { duration: 140 } }
                Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "󰍉"; color: "#cba6f7"; font.family: "Cascadia Mono NF"; font.pixelSize: 18 }
                TextInput {
                    id: search
                    anchors.left: parent.left
                    anchors.leftMargin: 46
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#cdd6f4"
                    font.family: "Cascadia Mono NF"
                    font.pixelSize: 16
                    clip: true
                    onTextChanged: root.rebuild()
                    Keys.onEscapePressed: root.visible = false
                    Keys.onDownPressed: results.incrementCurrentIndex()
                    Keys.onUpPressed: results.decrementCurrentIndex()
                    Keys.onReturnPressed: { if (results.currentItem) results.currentItem.launch() }
                }
                Text { visible: search.text.length === 0; anchors.left: parent.left; anchors.leftMargin: 46; anchors.verticalCenter: parent.verticalCenter; text: "Buscar aplicaciones…"; color: "#6c7086"; font.family: "Cascadia Mono NF"; font.pixelSize: 15 }
            }
            Item {
                width: parent.width
                height: parent.height - 58
                ListView {
                    id: results
                    anchors.fill: parent
                    clip: true
                    spacing: 4
                    model: apps
                    currentIndex: count > 0 ? 0 : -1
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: 54
                        radius: 9
                        color: ListView.isCurrentItem || rowMouse.containsMouse ? "#313244" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        function launch(): void { modelData.execute(); root.visible = false }
                        IconImage { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; implicitSize: 32; source: Quickshell.iconPath(row.modelData.icon, "application-x-executable") }
                        Column {
                            anchors.left: parent.left; anchors.leftMargin: 54; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                            Text { width: parent.width; text: row.modelData.name; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight }
                            Text { width: parent.width; visible: text.length > 0; text: row.modelData.comment || row.modelData.genericName || ""; color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 11; elide: Text.ElideRight }
                        }
                        MouseArea { id: rowMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: results.currentIndex = row.index; onClicked: row.launch() }
                    }
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                }
                Text { anchors.centerIn: parent; visible: results.count === 0; text: "󰅖  Sin resultados"; color: "#6c7086"; font.family: "Cascadia Mono NF"; font.pixelSize: 15 }
            }
        }
    }
}
