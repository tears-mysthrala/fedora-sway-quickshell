import QtQuick
import Quickshell

Rectangle {
    id: root
    signal activated()
    SystemClock { id: clock; precision: SystemClock.Minutes }
    implicitWidth: label.implicitWidth + 14
    implicitHeight: 28
    radius: 8
    color: mouse.containsMouse ? "#45475a" : "transparent"
    Behavior on color { ColorAnimation { duration: 160 } }
    Text { id: label; anchors.centerIn: parent; text: "󰥔  " + Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm"); color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 13; font.weight: Font.Medium }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.activated() }
}
