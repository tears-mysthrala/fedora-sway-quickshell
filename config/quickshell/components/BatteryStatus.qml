import QtQuick
import Quickshell.Services.UPower

Text {
    readonly property var battery: UPower.displayDevice
    visible: battery.ready && battery.isLaptopBattery && battery.isPresent
    text: "bat " + Math.round(battery.percentage) + "%"
    color: battery.percentage < 15 ? "#f7768e" : "#c0caf5"
}

