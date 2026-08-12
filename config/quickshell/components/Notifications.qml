import QtQuick
import Quickshell
import Quickshell.Services.Notifications

PanelWindow {
    id: root
    anchors { top: true; right: true }
    margins.top: 46
    margins.right: 12
    implicitWidth: 360
    implicitHeight: current ? content.implicitHeight + 24 : 0
    visible: current !== null
    color: "#24283b"
    property var current: null

    NotificationServer {
        keepOnReload: false
        persistenceSupported: false
        actionsSupported: false
        bodyMarkupSupported: false
        onNotification: notification => {
            if (root.current) root.current.expire()
            notification.tracked = true
            root.current = notification
            expiry.interval = notification.expireTimeout > 0 ? notification.expireTimeout * 1000 : 5000
            expiry.restart()
        }
    }
    Timer {
        id: expiry
        repeat: false
        onTriggered: {
            if (root.current) root.current.expire()
            root.current = null
        }
    }
    Column {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 4
        Text { width: parent.width; text: root.current ? root.current.summary : ""; color: "#c0caf5"; font.bold: true; wrapMode: Text.Wrap }
        Text { width: parent.width; text: root.current ? root.current.body : ""; color: "#a9b1d6"; textFormat: Text.PlainText; wrapMode: Text.Wrap }
    }
}
