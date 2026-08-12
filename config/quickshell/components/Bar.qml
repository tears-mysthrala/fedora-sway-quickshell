import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3

PanelWindow {
    id: root
    anchors { top: true; left: true; right: true }
    implicitHeight: 34
    color: "#111318"
    exclusiveZone: implicitHeight
    property string activeTitle: ""

    I3IpcListener {
        subscriptions: ["window"]
        onIpcEvent: event => {
            const payload = JSON.parse(event.data)
            if (payload.change === "focus" && payload.container)
                root.activeTitle = payload.container.name || payload.container.app_id || ""
            else if (payload.change === "title" && payload.container && payload.container.focused)
                root.activeTitle = payload.container.name || ""
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12
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

