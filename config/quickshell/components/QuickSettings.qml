import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: root
    anchors { top: true; right: true }
    margins.top: 48
    margins.right: 10
    implicitWidth: 344
    implicitHeight: section === "network" ? 148 : section === "audio" ? 140 : section === "battery" ? 276 : section === "utilities" ? 222 : 318
    visible: false
    color: "transparent"

    property string section: ""
    property string memory: "—"
    property int brightness: 50
    property bool bluetoothPowered: false
    property string powerProfile: "balanced"
    property bool inhibitActive: false
    readonly property var battery: UPower.displayDevice
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property date now: panelClock.date

    SystemClock { id: panelClock; precision: SystemClock.Minutes }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    IpcHandler {
        target: "quickSettings"
        function toggle(section: string): void { root.toggle(section) }
    }

    function toggle(target: string): void {
        if (visible && section === target) {
            visible = false
        } else {
            section = target
            visible = true
            memoryQuery.running = true
            brightnessQuery.running = true
            bluetoothQuery.running = true
            profileQuery.running = true
            inhibitQuery.running = true
        }
    }

    function run(command: var): void {
        action.command = command
        action.running = true
    }

    function setProfile(profile: string): void {
        action.command = ["tuned-adm", "profile", profile]
        action.running = true
        powerProfile = profile
        profileRefresh.restart()
    }

    Process { id: action }
    Process {
        id: memoryQuery
        command: ["sh", "-c", "free -h | awk '/Mem:/ {print $3 \" / \" $2}'"]
        stdout: StdioCollector { id: memoryOutput }
        onExited: root.memory = memoryOutput.text.trim()
    }
    Process {
        id: inhibitQuery
        command: ["systemctl", "--user", "is-active", "fedora-sway-inhibit.service"]
        stdout: StdioCollector { id: inhibitOutput }
        onExited: root.inhibitActive = inhibitOutput.text.trim() === "active"
    }
    Timer { id: inhibitRefresh; interval: 500; onTriggered: inhibitQuery.running = true }

    function toggleInhibit(): void {
        run(["systemctl", "--user", inhibitActive ? "stop" : "start", "fedora-sway-inhibit.service"])
        inhibitActive = !inhibitActive
        inhibitRefresh.restart()
    }
    Process {
        id: brightnessQuery
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%' "]
        stdout: StdioCollector { id: brightnessOutput }
        onExited: root.brightness = parseInt(brightnessOutput.text.trim()) || 0
    }
    Process {
        id: bluetoothQuery
        command: ["sh", "-c", "bluetoothctl show | awk '/Powered:/ {print $2}'"]
        stdout: StdioCollector { id: bluetoothOutput }
        onExited: root.bluetoothPowered = bluetoothOutput.text.trim() === "yes"
    }
    Process {
        id: profileQuery
        command: ["sh", "-c", "tuned-adm active | sed 's/.*: //' "]
        stdout: StdioCollector { id: profileOutput }
        onExited: root.powerProfile = profileOutput.text.trim() || "balanced"
    }

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: "#181825"
        border.width: 1
        border.color: "#45475a"

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Item {
                width: parent.width
                height: 34

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Text {
                        text: root.section === "network" ? "Conectividad"
                            : root.section === "audio" ? "Sonido"
                            : root.section === "battery" ? "Energía"
                            : root.section === "utilities" ? "Herramientas"
                            : root.now.toLocaleDateString(Qt.locale("es_ES"), "MMMM 'de' yyyy")
                        color: "#cdd6f4"
                        font.family: "Cascadia Mono NF"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: root.section === "network" ? "Wi-Fi y Bluetooth"
                            : root.section === "audio" ? "Salida de audio"
                            : root.section === "battery" ? "Batería, brillo y perfil"
                            : root.section === "utilities" ? "Desarrollo y administración"
                            : root.now.toLocaleDateString(Qt.locale("es_ES"), "dddd, d 'de' MMMM") + "  ·  " + Qt.formatDateTime(root.now, "HH:mm")
                        color: "#a6adc8"
                        font.family: "Cascadia Mono NF"
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30; height: 30; radius: 15
                    color: closeMouse.containsMouse ? "#45475a" : "transparent"
                    Text { anchors.centerIn: parent; text: "󰅖"; color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 13 }
                    MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.visible = false }
                }
            }

            Row {
                width: parent.width
                spacing: 10
                visible: root.section === "network"

                Rectangle {
                    width: (parent.width - 10) / 2
                    height: 70
                    radius: 14
                    color: networkMouse.containsMouse ? "#3b3d51" : "#313244"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.top: parent.top; anchors.topMargin: 13; text: "󰤨"; color: "#a6e3a1"; font.family: "Cascadia Mono NF"; font.pixelSize: 18 }
                    Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; text: "Red"; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 13; font.bold: true }
                    Text { anchors.right: parent.right; anchors.rightMargin: 13; anchors.bottom: parent.bottom; anchors.bottomMargin: 13; text: "Conectada"; color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 10 }
                    MouseArea { id: networkMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.run(["nm-connection-editor"]) }
                }

                Rectangle {
                    width: (parent.width - 10) / 2
                    height: 70
                    radius: 14
                    color: root.muted ? "#45475a" : (audioMouse.containsMouse ? "#3b3d51" : "#313244")
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.top: parent.top; anchors.topMargin: 13; text: root.bluetoothPowered ? "󰂯" : "󰂲"; color: root.bluetoothPowered ? "#89b4fa" : "#6c7086"; font.family: "Cascadia Mono NF"; font.pixelSize: 18 }
                    Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; text: "Bluetooth"; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 13; font.bold: true }
                    Text { anchors.right: parent.right; anchors.rightMargin: 13; anchors.bottom: parent.bottom; anchors.bottomMargin: 13; text: root.bluetoothPowered ? "Activo" : "Apagado"; color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 10 }
                    MouseArea { id: audioMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: mouse => { if (mouse.button === Qt.RightButton) { root.run(["bluetoothctl", "power", root.bluetoothPowered ? "off" : "on"]); bluetoothRefresh.restart() } else root.run(["blueman-manager"]) } }
                }
            }

            Timer { id: bluetoothRefresh; interval: 700; onTriggered: bluetoothQuery.running = true }

            Row {
                width: parent.width; height: 70; spacing: 10
                visible: root.section === "utilities"
                Rectangle {
                    width: (parent.width - 10) / 2; height: 70; radius: 14
                    color: cockpitMouse.containsMouse ? "#3b3d51" : "#313244"
                    Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.top: parent.top; anchors.topMargin: 12; text: "󰖟"; color: "#89b4fa"; font.family: "Cascadia Mono NF"; font.pixelSize: 18 }
                    Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; text: "Cockpit"; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 12; font.bold: true }
                    MouseArea { id: cockpitMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.run(["zen", "--new-window", "https://localhost:9090"]) }
                }
                Rectangle {
                    width: (parent.width - 10) / 2; height: 70; radius: 14
                    color: root.inhibitActive ? "#45475a" : (inhibitMouse.containsMouse ? "#3b3d51" : "#313244")
                    border.width: root.inhibitActive ? 1 : 0; border.color: "#a6e3a1"
                    Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.top: parent.top; anchors.topMargin: 12; text: root.inhibitActive ? "󰅶" : "󰒲"; color: root.inhibitActive ? "#a6e3a1" : "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 18 }
                    Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; text: root.inhibitActive ? "No suspender" : "Suspensión"; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 11; font.bold: true }
                    MouseArea { id: inhibitMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleInhibit() }
                }
            }

            Rectangle {
                width: parent.width; height: 62; radius: 14
                visible: root.section === "utilities"
                color: btopMouse.containsMouse ? "#3b3d51" : "#313244"
                Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "󰍛"; color: "#cba6f7"; font.family: "Cascadia Mono NF"; font.pixelSize: 18 }
                Column { anchors.left: parent.left; anchors.leftMargin: 48; anchors.verticalCenter: parent.verticalCenter; spacing: 2; Text { text: "Monitor del sistema"; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 12; font.bold: true } Text { text: "Abrir btop en una terminal"; color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 9 } }
                MouseArea { id: btopMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.run(["alacritty", "-e", "btop"]) }
            }

            Row {
                width: parent.width
                height: 54
                spacing: 7
                visible: root.section === "battery"

                Repeater {
                    model: [
                        { profile: "powersave", label: "Eco", icon: "󰌪" },
                        { profile: "balanced", label: "Equilibrado", icon: "󰾅" },
                        { profile: "throughput-performance", label: "Potencia", icon: "󰓅" }
                    ]
                    Rectangle {
                        id: profileButton
                        required property var modelData
                        width: (parent.width - 14) / 3
                        height: 54
                        radius: 12
                        readonly property bool selected: root.powerProfile === modelData.profile
                        color: selected ? "#45475a" : (profileButtonMouse.containsMouse ? "#3b3d51" : "#313244")
                        border.width: selected ? 1 : 0
                        border.color: "#cba6f7"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Column {
                            anchors.centerIn: parent; spacing: 3
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: profileButton.modelData.icon; color: profileButton.selected ? "#cba6f7" : "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 15 }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: profileButton.modelData.label; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 9; font.bold: profileButton.selected }
                        }
                        MouseArea { id: profileButtonMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.setProfile(profileButton.modelData.profile) }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 62
                visible: root.section === "audio"
                radius: 14
                color: "#313244"

                Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.top: parent.top; anchors.topMargin: 10; text: root.muted ? "󰖁" : "󰕾"; color: "#89b4fa"; font.family: "Cascadia Mono NF"; font.pixelSize: 15 }
                Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.top: parent.top; anchors.topMargin: 10; text: root.volume + "%"; color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 11 }

                Slider {
                    id: volumeSlider
                    anchors.left: parent.left; anchors.leftMargin: 14
                    anchors.right: parent.right; anchors.rightMargin: 14
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                    height: 24
                    from: 0; to: 1.0
                    value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                    onMoved: if (root.sink && root.sink.audio) root.sink.audio.volume = value
                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        width: volumeSlider.availableWidth
                        height: 5; radius: 3; color: "#45475a"
                        Rectangle { width: volumeSlider.visualPosition * parent.width; height: parent.height; radius: 3; color: "#89b4fa" }
                    }
                    handle: Rectangle {
                        x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        width: 14; height: 14; radius: 7; color: "#cdd6f4"
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 58
                visible: root.section === "battery"
                radius: 14
                color: "#313244"
                Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.top: parent.top; anchors.topMargin: 9; text: "󰃠"; color: "#f9e2af"; font.family: "Cascadia Mono NF"; font.pixelSize: 14 }
                Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.top: parent.top; anchors.topMargin: 9; text: root.brightness + "%"; color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 10 }
                Slider {
                    id: brightnessSlider
                    anchors.left: parent.left; anchors.leftMargin: 14
                    anchors.right: parent.right; anchors.rightMargin: 14
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                    height: 23; from: 5; to: 100; value: root.brightness
                    onMoved: { root.brightness = Math.round(value); root.run(["brightnessctl", "set", root.brightness + "%"]) }
                    background: Rectangle {
                        x: brightnessSlider.leftPadding; y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                        width: brightnessSlider.availableWidth; height: 5; radius: 3; color: "#45475a"
                        Rectangle { width: brightnessSlider.visualPosition * parent.width; height: parent.height; radius: 3; color: "#f9e2af" }
                    }
                    handle: Rectangle {
                        x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                        y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                        width: 14; height: 14; radius: 7; color: "#cdd6f4"
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 62
                visible: root.section === "battery"
                radius: 14
                color: systemMouse.containsMouse ? "#3b3d51" : "#313244"
                Behavior on color { ColorAnimation { duration: 120 } }

                Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: root.battery.state === 1 ? "󰂄" : "󰁹"; color: "#f9e2af"; font.family: "Cascadia Mono NF"; font.pixelSize: 18 }
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 46; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    Text { text: Math.round(root.battery.percentage * 100) + "%  ·  " + (root.battery.state === 1 ? "Cargando" : "Batería"); color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 12; font.bold: true }
                    Text { text: "RAM  " + root.memory; color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 10 }
                }
                Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "󰍛"; color: "#cba6f7"; font.family: "Cascadia Mono NF"; font.pixelSize: 17 }
                MouseArea { id: systemMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.run(["alacritty", "-e", "btop"]) }
                Timer { id: profileRefresh; interval: 1600; onTriggered: profileQuery.running = true }
            }

            Rectangle {
                width: parent.width
                height: 240
                visible: root.section === "clock"
                radius: 14
                color: "#313244"

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 7

                    Grid {
                        width: parent.width
                        columns: 7
                        Repeater {
                            model: ["L", "M", "X", "J", "V", "S", "D"]
                            Item {
                                required property string modelData
                                width: 40; height: 22
                                Text { anchors.centerIn: parent; text: modelData; color: "#6c7086"; font.family: "Cascadia Mono NF"; font.pixelSize: 10; font.bold: true }
                            }
                        }
                    }

                    Grid {
                        id: calendarGrid
                        width: parent.width
                        columns: 7
                        property int year: root.now.getFullYear()
                        property int month: root.now.getMonth()
                        property int firstDay: (new Date(year, month, 1).getDay() + 6) % 7
                        property int days: new Date(year, month + 1, 0).getDate()

                        Repeater {
                            model: 42
                            Rectangle {
                                required property int index
                                readonly property int day: index - calendarGrid.firstDay + 1
                                readonly property bool valid: day >= 1 && day <= calendarGrid.days
                                readonly property bool today: valid && day === root.now.getDate()
                                width: 40; height: 30; radius: 9
                                color: today ? "#cba6f7" : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.valid ? parent.day : ""
                                    color: parent.today ? "#1e1e2e" : (parent.valid ? "#cdd6f4" : "transparent")
                                    font.family: "Cascadia Mono NF"; font.pixelSize: 11; font.bold: parent.today
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
