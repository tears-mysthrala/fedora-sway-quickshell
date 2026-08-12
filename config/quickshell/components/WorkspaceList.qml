import QtQuick
import QtQuick.Layouts
import Quickshell.I3

RowLayout {
    spacing: 6
    Repeater {
        model: I3.workspaces
        delegate: Rectangle {
            required property var modelData
            implicitWidth: 24
            implicitHeight: 24
            radius: 3
            color: modelData.focused ? "#7aa2f7" : (modelData.urgent ? "#f7768e" : "#24283b")
            Text {
                anchors.centerIn: parent
                text: modelData.name
                color: modelData.focused ? "#111318" : "#c0caf5"
            }
            MouseArea { anchors.fill: parent; onClicked: modelData.activate() }
        }
    }
}

