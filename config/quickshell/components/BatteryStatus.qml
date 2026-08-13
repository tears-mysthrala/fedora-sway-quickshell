import QtQuick
import Quickshell.Services.UPower

Rectangle {
    id: root
    signal activated()
    readonly property var battery: UPower.displayDevice
    visible: battery.ready && battery.isLaptopBattery && battery.isPresent
    readonly property int level: Math.round(battery.percentage * 100)
    implicitWidth: label.implicitWidth + 14
    implicitHeight: 28
    radius: 8
    color: mouse.containsMouse ? "#45475a" : "transparent"
    Behavior on color { ColorAnimation { duration: 200 } }
    Text {
        id: label
        anchors.centerIn: parent
        text: (battery.state === 1 ? "󰂄" : root.level > 80 ? "󰁹" : root.level > 55 ? "󰂀" : root.level > 30 ? "󰁾" : "󰁺") + "  " + root.level + "%"
        color: root.level < 15 ? "#f38ba8" : root.level < 30 ? "#fab387" : "#cdd6f4"
        font.family: "Cascadia Mono NF"
        font.pixelSize: 13
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.activated() }
}
