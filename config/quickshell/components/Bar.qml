import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3

PanelWindow {
    id: root
    signal launcherRequested()
    anchors { top: true; left: true; right: true }
    implicitHeight: 34
    color: "#111318"
    exclusiveZone: implicitHeight
    property string activeTitle: ""
    property int activeContainerId: -1

    I3IpcListener {
        subscriptions: ["window"]
        onIpcEvent: event => {
            const payload = JSON.parse(event.data)
            if (payload.change === "focus" && payload.container) {
                root.activeContainerId = payload.container.id
                root.activeTitle = payload.container.name || payload.container.app_id || ""
            } else if (payload.change === "title" && payload.container && payload.container.focused) {
                root.activeTitle = payload.container.name || ""
            } else if (payload.change === "close" && payload.container && payload.container.id === root.activeContainerId) {
                root.activeContainerId = -1
                root.activeTitle = ""
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12
        Rectangle {
            implicitWidth: appsText.implicitWidth + 14
            implicitHeight: 24
            radius: 3
            color: "#24283b"
            Text { id: appsText; anchors.centerIn: parent; text: "Apps"; color: "#c0caf5" }
            MouseArea { anchors.fill: parent; onClicked: root.launcherRequested() }
        }
        WorkspaceList {}
        Text {
            Layout.fillWidth: true
            text: root.activeTitle
            color: "#a9b1d6"
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
        NetworkStatus {}
        AudioStatus {}
        BatteryStatus {}
        Clock {}
    }
}
