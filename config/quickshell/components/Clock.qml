import QtQuick
import Quickshell

Text {
    SystemClock { id: clock; precision: SystemClock.Minutes }
    text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
    color: "#c0caf5"
}

