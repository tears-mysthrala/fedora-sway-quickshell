import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3

PanelWindow {
    id: root
    signal launcherRequested()
    signal quickSettingsRequested(string section)
    signal notificationsRequested()
    signal systemSettingsRequested()
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    color: "#1e1e2e"
    exclusiveZone: implicitHeight
    property string activeTitle: ""
    property int activeContainerId: -1
    // Shared Niri state from shell.qml; null on the Sway session.
    property var niri: null
    readonly property bool useNiri: niri !== null && niri.active

    // The i3 listener is Sway-only; on Niri the title comes from NiriState.
    Loader {
        active: !root.useNiri
        sourceComponent: Component {
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
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 14
        spacing: 14
        Rectangle {
            implicitWidth: appsText.implicitWidth + 20
            implicitHeight: 28
            radius: 8
            color: appsMouse.containsMouse ? "#45475a" : "#313244"
            Behavior on color { ColorAnimation { duration: 140 } }
            Text { id: appsText; anchors.centerIn: parent; text: "󰀻  Apps"; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 13; font.weight: Font.DemiBold }
            MouseArea { id: appsMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.launcherRequested() }
        }
        WorkspaceList { niri: root.niri }
        Text {
            Layout.fillWidth: true
            text: root.useNiri ? root.niri.activeTitle : root.activeTitle
            color: "#a6adc8"
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font.family: "Cascadia Mono NF"
            font.pixelSize: 12
        }
        MediaStatus {}
        SystemTrayStatus {}
        PrivacyStatus {}
        UtilitiesStatus { onActivated: root.systemSettingsRequested() }
        MicrophoneStatus {}
        Rectangle {
            implicitWidth: 28; implicitHeight: 28; radius: 8; color: bellMouse.containsMouse ? "#45475a" : "transparent"
            Text { anchors.centerIn: parent; text: "󰂚"; color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 12 }
            MouseArea { id: bellMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.notificationsRequested() }
        }
        NetworkStatus { onActivated: root.quickSettingsRequested("network") }
        AudioStatus { onActivated: root.quickSettingsRequested("audio") }
        BatteryStatus { onActivated: root.quickSettingsRequested("battery") }
        Clock { onActivated: root.quickSettingsRequested("clock") }
    }
}
