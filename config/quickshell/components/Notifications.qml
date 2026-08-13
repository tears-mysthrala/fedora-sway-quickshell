import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Scope {
    id: root
    property var current: null
    property var history: []
    property bool doNotDisturb: false

    function toggleCenter(): void { center.visible = !center.visible }
    function clearHistory(): void { history = [] }

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.toggleCenter() }
        function dnd(): void { root.doNotDisturb = !root.doNotDisturb }
    }

    NotificationServer {
        keepOnReload: true
        persistenceSupported: true
        actionsSupported: false
        bodyMarkupSupported: false
        onNotification: notification => {
            notification.tracked = true
            const snapshot = {
                summary: notification.summary || "Notificación",
                body: notification.body || "",
                appName: notification.appName || "Sistema",
                time: Qt.formatDateTime(new Date(), "HH:mm")
            }
            let next = root.history.slice()
            next.unshift(snapshot)
            root.history = next.slice(0, 30)

            if (root.doNotDisturb) {
                notification.tracked = false
                return
            }
            if (root.current) root.current.expire()
            root.current = notification
            expiry.interval = notification.expireTimeout > 0 ? notification.expireTimeout : 5000
            expiry.restart()
        }
    }

    Timer {
        id: expiry
        onTriggered: {
            if (root.current) root.current.expire()
            root.current = null
        }
    }

    PanelWindow {
        id: toast
        anchors { top: true; right: true }
        margins.top: 52; margins.right: 14
        implicitWidth: 380
        implicitHeight: root.current ? Math.max(84, toastContent.implicitHeight + 30) : 0
        visible: root.current !== null
        color: "#313244"
        Column {
            id: toastContent
            anchors.fill: parent; anchors.margins: 15; spacing: 6
            Text { width: parent.width - 30; text: root.current ? root.current.summary : ""; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 14; font.bold: true; wrapMode: Text.Wrap }
            Text { width: parent.width; text: root.current ? root.current.body : ""; color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 12; textFormat: Text.PlainText; wrapMode: Text.Wrap }
        }
        Text {
            anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 12
            text: "󰅖"; color: toastClose.containsMouse ? "#f38ba8" : "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 14
            MouseArea { id: toastClose; anchors.fill: parent; anchors.margins: -7; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (root.current) root.current.expire(); root.current = null } }
        }
    }

    PanelWindow {
        id: center
        anchors { top: true; right: true }
        margins.top: 48; margins.right: 10
        implicitWidth: 380; implicitHeight: 450
        visible: false; color: "transparent"
        Rectangle {
            anchors.fill: parent; radius: 18; color: "#181825"; border.width: 1; border.color: "#45475a"
            Column {
                anchors.fill: parent; anchors.margins: 16; spacing: 12
                Row {
                    width: parent.width; height: 34; spacing: 8
                    Text { width: parent.width - 154; anchors.verticalCenter: parent.verticalCenter; text: "󰂚  Notificaciones"; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 15; font.bold: true }
                    Rectangle {
                        width: 82; height: 30; radius: 9; color: root.doNotDisturb ? "#cba6f7" : "#313244"
                        Text { anchors.centerIn: parent; text: "󰂛  " + (root.doNotDisturb ? "Activo" : "Normal"); color: root.doNotDisturb ? "#1e1e2e" : "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 9; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.doNotDisturb = !root.doNotDisturb }
                    }
                    Rectangle {
                        width: 48; height: 30; radius: 9; color: clearMouse.containsMouse ? "#45475a" : "#313244"
                        Text { anchors.centerIn: parent; text: "󰃢"; color: "#f38ba8"; font.family: "Cascadia Mono NF"; font.pixelSize: 13 }
                        MouseArea { id: clearMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clearHistory() }
                    }
                }
                ListView {
                    width: parent.width; height: parent.height - 46; clip: true; spacing: 8
                    model: root.history
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width; height: Math.max(68, cardText.implicitHeight + 24); radius: 12; color: "#313244"
                        Column {
                            id: cardText; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                            Row { width: parent.width; Text { width: parent.width - 45; text: modelData.summary; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight } Text { text: modelData.time; color: "#6c7086"; font.family: "Cascadia Mono NF"; font.pixelSize: 9 } }
                            Text { width: parent.width; visible: text.length > 0; text: modelData.body; color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 10; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight }
                            Text { text: modelData.appName; color: "#89b4fa"; font.family: "Cascadia Mono NF"; font.pixelSize: 9 }
                        }
                    }
                    Text { anchors.centerIn: parent; visible: root.history.length === 0; text: "󰂜\nTodo tranquilo"; horizontalAlignment: Text.AlignHCenter; color: "#6c7086"; font.family: "Cascadia Mono NF"; font.pixelSize: 13 }
                }
            }
        }
    }
}
