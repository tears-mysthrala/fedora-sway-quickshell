import QtQuick

Rectangle {
    id: root
    signal activated()
    implicitWidth: 28; implicitHeight: 28; radius: 8
    color: mouse.containsMouse ? "#45475a" : "transparent"
    Text { anchors.centerIn: parent; text: "󰒓"; color: "#cba6f7"; font.family: "Cascadia Mono NF"; font.pixelSize: 12 }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.activated() }
}
