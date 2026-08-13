import QtQuick
import Quickshell.Services.Mpris

Rectangle {
    id: root
    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var player: players.length > 0 ? players[0] : null
    readonly property bool hasMedia: player !== null && (player.trackTitle || player.trackArtist)
    visible: hasMedia
    implicitWidth: hasMedia ? Math.min(210, mediaRow.implicitWidth + 16) : 0
    implicitHeight: 28
    radius: 8
    color: mediaMouse.containsMouse ? "#45475a" : "transparent"

    Row {
        id: mediaRow
        anchors.centerIn: parent
        spacing: 6
        Text { text: root.player && root.player.isPlaying ? "󰏤" : "󰐊"; color: "#cba6f7"; font.family: "Cascadia Mono NF"; font.pixelSize: 12 }
        Text {
            width: Math.min(166, implicitWidth)
            text: root.player ? (root.player.trackTitle || root.player.trackArtist || "Multimedia") : ""
            color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mediaMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (!root.player) return
            if (mouse.button === Qt.MiddleButton && root.player.canGoNext) root.player.next()
            else if (mouse.button === Qt.RightButton && root.player.canGoPrevious) root.player.previous()
            else if (root.player.canTogglePlaying) root.player.togglePlaying()
        }
        onWheel: wheel => {
            if (!root.player) return
            if (wheel.angleDelta.y > 0 && root.player.canGoPrevious) root.player.previous()
            else if (wheel.angleDelta.y < 0 && root.player.canGoNext) root.player.next()
        }
    }
}
