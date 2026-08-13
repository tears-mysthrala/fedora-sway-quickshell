import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Row {
    id: root
    spacing: 2
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items.values
        Rectangle {
            id: trayItem
            required property var modelData
            width: modelData.status === Status.Passive ? 0 : 26
            height: 28
            visible: modelData.status !== Status.Passive
            radius: 7
            color: trayMouse.containsMouse ? "#45475a" : "transparent"
            Image { anchors.centerIn: parent; width: 16; height: 16; source: trayItem.modelData.icon; fillMode: Image.PreserveAspectFit }
            MouseArea {
                id: trayMouse
                anchors.fill: parent; hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu)
                        trayItem.modelData.display(parent.QsWindow.window, mouse.x, mouse.y)
                    else trayItem.modelData.activate()
                }
            }
        }
    }
}
