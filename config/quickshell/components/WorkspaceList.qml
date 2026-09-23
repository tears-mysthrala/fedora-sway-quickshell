import QtQuick
import QtQuick.Layouts
import Quickshell.I3

RowLayout {
    id: root
    // Set by Bar on the Niri session; null on Sway. The i3 import stays for
    // the Sway session, where it is the native workspace source.
    property var niri: null
    readonly property bool useNiri: niri !== null && niri.active
    spacing: 5
    Repeater {
        model: root.useNiri ? root.niri.workspaces : I3.workspaces
        delegate: Rectangle {
            required property var modelData
            implicitWidth: modelData.focused ? 30 : 24
            implicitHeight: 24
            radius: 7
            color: modelData.focused ? "#cba6f7" : (modelData.urgent ? "#f38ba8" : workspaceMouse.containsMouse ? "#45475a" : "#313244")
            Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
            Text {
                anchors.centerIn: parent
                text: modelData.name
                color: modelData.focused ? "#1e1e2e" : "#cdd6f4"
                font.family: "Cascadia Mono NF"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            MouseArea {
                id: workspaceMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.useNiri ? root.niri.focusWorkspace(modelData.ref) : modelData.activate()
            }
        }
    }
}
