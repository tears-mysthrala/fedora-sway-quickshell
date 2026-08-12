import QtQuick
import Quickshell.Networking

Text {
    readonly property var connectedDevices: Networking.devices.values.filter(device => device.connected)
    text: connectedDevices.length === 0 ? "offline" : connectedDevices.map(device => device.name).join(", ")
    color: connectedDevices.length === 0 ? "#f7768e" : "#9ece6a"
}

