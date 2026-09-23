import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

FloatingWindow {
    id: root
    title: "Ajustes del sistema"
    visible: false
    implicitWidth: 780
    implicitHeight: 540
    color: "transparent"

    property string page: "overview"
    property string systemInfo: "Cargando…"
    property string displayInfo: "Pantalla integrada"
    // Shared Niri state from shell.qml; null on the Sway session.
    property var niri: null
    readonly property bool useNiri: niri !== null && niri.active
    property string powerProfile: "balanced"
    property int brightness: 50
    property bool inhibitActive: false
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var battery: UPower.displayDevice
    readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    function toggle(): void {
        visible = !visible
        if (visible) refresh()
    }
    function refresh(): void {
        infoQuery.running = true
        displayQuery.running = true
        profileQuery.running = true
        brightnessQuery.running = true
        inhibitQuery.running = true
    }
    function run(command: var): void { action.command = command; action.running = true }
    function setProfile(profile: string): void {
        powerProfile = profile
        run(["tuned-adm", "profile", profile])
        profileRefresh.restart()
    }
    function toggleInhibit(): void {
        run(["systemctl", "--user", inhibitActive ? "stop" : "start", "fedora-sway-inhibit.service"])
        inhibitActive = !inhibitActive
        inhibitRefresh.restart()
    }

    IpcHandler {
        target: "systemSettings"
        function toggle(): void { root.toggle() }
        function open(page: string): void { root.page = page; root.visible = true; root.refresh() }
    }
    Process { id: action }
    Process {
        id: infoQuery
        command: ["sh", "-c", "printf '%s\\n' \"$(hostnamectl hostname)\" \"$(uname -r)\"; free -h | awk '/Mem:/ {print $3 \" usados de \" $2}'; df -h / | awk 'NR==2 {print $3 \" usados de \" $2 \" · \" $5}'"]
        stdout: StdioCollector { id: infoOutput }
        onExited: root.systemInfo = infoOutput.text.trim()
    }
    Process {
        id: displayQuery
        command: root.useNiri ? ["sh", "-c", "niri msg --json outputs | jq -r 'to_entries[] | \"\\(.key) · \\(.value.logical.width)×\\(.value.logical.height) · escala \\(.value.logical.scale)\"' | head -1"] : ["sh", "-c", "swaymsg -t get_outputs -r | jq -r '.[] | select(.active) | .name + \" · \" + (.current_mode.width|tostring) + \"×\" + (.current_mode.height|tostring) + \" · escala \" + (.scale|tostring)' | head -1"]
        stdout: StdioCollector { id: displayOutput }
        onExited: root.displayInfo = displayOutput.text.trim() || "Pantalla integrada"
    }
    Process {
        id: profileQuery
        command: ["sh", "-c", "tuned-adm active | sed 's/.*: //' "]
        stdout: StdioCollector { id: profileOutput }
        onExited: root.powerProfile = profileOutput.text.trim() || "balanced"
    }
    Process {
        id: brightnessQuery
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%' "]
        stdout: StdioCollector { id: brightnessOutput }
        onExited: root.brightness = parseInt(brightnessOutput.text.trim()) || 0
    }
    Process {
        id: inhibitQuery
        command: ["systemctl", "--user", "is-active", "fedora-sway-inhibit.service"]
        stdout: StdioCollector { id: inhibitOutput }
        onExited: root.inhibitActive = inhibitOutput.text.trim() === "active"
    }
    Timer { id: profileRefresh; interval: 900; onTriggered: profileQuery.running = true }
    Timer { id: inhibitRefresh; interval: 500; onTriggered: inhibitQuery.running = true }

    Rectangle {
        anchors.fill: parent; radius: 18; color: "#181825"; border.width: 1; border.color: "#45475a"

        Rectangle {
            id: sidebar
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
            width: 190; color: "#1e1e2e"; radius: 18
            Rectangle { anchors.right: parent.right; width: 18; height: parent.height; color: parent.color }
            Column {
                anchors.fill: parent; anchors.margins: 14; spacing: 7
                Text { text: "󰒓  Ajustes"; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 17; font.bold: true; leftPadding: 8; bottomPadding: 12 }
                Repeater {
                    model: [
                        { id: "overview", icon: "󰋜", label: "Resumen" },
                        { id: "network", icon: "󰤨", label: "Conectividad" },
                        { id: "sound", icon: "󰕾", label: "Sonido" },
                        { id: "power", icon: "󰂄", label: "Energía" },
                        { id: "display", icon: "󰍹", label: "Pantalla" },
                        { id: "system", icon: "󰍛", label: "Sistema" }
                    ]
                    Rectangle {
                        id: navRow
                        required property var modelData
                        width: parent.width; height: 42; radius: 10
                        color: root.page === modelData.id ? "#45475a" : (navMouse.containsMouse ? "#313244" : "transparent")
                        Text { anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: navRow.modelData.icon; color: root.page === navRow.modelData.id ? "#cba6f7" : "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 14 }
                        Text { anchors.left: parent.left; anchors.leftMargin: 42; anchors.verticalCenter: parent.verticalCenter; text: navRow.modelData.label; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 12; font.bold: root.page === navRow.modelData.id }
                        MouseArea { id: navMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.page = navRow.modelData.id }
                    }
                }
            }
        }

        Item {
            anchors.left: sidebar.right; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
            anchors.margins: 22

            Text {
                id: heading; anchors.left: parent.left; anchors.top: parent.top
                text: root.page === "overview" ? "Resumen" : root.page === "network" ? "Conectividad" : root.page === "sound" ? "Sonido" : root.page === "power" ? "Energía" : root.page === "display" ? "Pantalla" : "Sistema"
                color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 21; font.bold: true
            }
            Text { anchors.right: parent.right; anchors.top: parent.top; text: "󰅖"; color: closeMouse.containsMouse ? "#f38ba8" : "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 14; MouseArea { id: closeMouse; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.visible = false } }

            Column {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: heading.bottom; anchors.topMargin: 20; spacing: 12

                Column {
                    width: parent.width; spacing: 12; visible: root.page === "overview"
                    Rectangle {
                        width: parent.width; height: 150; radius: 14; color: "#313244"
                        Text { anchors.left: parent.left; anchors.leftMargin: 18; anchors.top: parent.top; anchors.topMargin: 16; text: "󰌢  Este equipo"; color: "#cba6f7"; font.family: "Cascadia Mono NF"; font.pixelSize: 14; font.bold: true }
                        Text { anchors.left: parent.left; anchors.leftMargin: 18; anchors.top: parent.top; anchors.topMargin: 48; text: root.systemInfo; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 12; lineHeight: 1.55 }
                    }
                    Row { width: parent.width; spacing: 10; SettingsButton { width: (parent.width - 20) / 3; icon: "󰖟"; label: "Cockpit"; accent: "#89b4fa"; onClicked: root.run(["zen", "--new-window", "https://localhost:9090"]) } SettingsButton { width: (parent.width - 20) / 3; icon: "󰍛"; label: "btop"; accent: "#cba6f7"; onClicked: root.run(["alacritty", "-e", "btop"]) } SettingsButton { width: (parent.width - 20) / 3; icon: "󰏧"; label: "Impresoras"; accent: "#a6e3a1"; onClicked: root.run(["system-config-printer"]) } }
                }

                Column {
                    width: parent.width; spacing: 12; visible: root.page === "network"
                    SettingsCard { width: parent.width; icon: "󰤨"; title: "Red"; detail: "Configurar Wi-Fi, Ethernet, VPN y DNS"; button: "Administrar"; onClicked: root.run(["nm-connection-editor"]) }
                    SettingsCard { width: parent.width; icon: "󰂯"; title: "Bluetooth"; detail: "Emparejar y administrar dispositivos"; button: "Dispositivos"; onClicked: root.run(["blueman-manager"]) }
                    SettingsCard { width: parent.width; icon: "󰖟"; title: "Red avanzada"; detail: "Firewall, interfaces y estadísticas en Cockpit"; button: "Cockpit"; onClicked: root.run(["zen", "--new-window", "https://localhost:9090/network"]) }
                }

                Column {
                    width: parent.width; spacing: 12; visible: root.page === "sound"
                    Rectangle {
                        width: parent.width; height: 110; radius: 14; color: "#313244"
                        Text { anchors.left: parent.left; anchors.leftMargin: 16; anchors.top: parent.top; anchors.topMargin: 14; text: "󰕾  Salida  " + root.volume + "%"; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 13; font.bold: true }
                        Slider { id: settingsVolume; anchors.left: parent.left; anchors.leftMargin: 16; anchors.right: parent.right; anchors.rightMargin: 16; anchors.top: parent.top; anchors.topMargin: 45; from: 0; to: 1; value: root.sink && root.sink.audio ? root.sink.audio.volume : 0; onMoved: if (root.sink && root.sink.audio) root.sink.audio.volume = value }
                    }
                    Row { width: parent.width; spacing: 10; SettingsButton { width: (parent.width - 10) / 2; icon: root.sink && root.sink.audio && root.sink.audio.muted ? "󰖁" : "󰕾"; label: "Silenciar salida"; accent: "#89b4fa"; onClicked: root.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]) } SettingsButton { width: (parent.width - 10) / 2; icon: root.source && root.source.audio && root.source.audio.muted ? "󰍭" : "󰍬"; label: "Silenciar micrófono"; accent: "#f38ba8"; onClicked: root.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]) } }
                    SettingsCard { width: parent.width; icon: "󰓃"; title: "Mezclador avanzado"; detail: "Aplicaciones, dispositivos y niveles individuales"; button: "Abrir"; onClicked: root.run(["pavucontrol"]) }
                }

                Column {
                    width: parent.width; spacing: 12; visible: root.page === "power"
                    Row { width: parent.width; spacing: 8; Repeater { model: [{p:"powersave",i:"󰌪",l:"Eco"},{p:"balanced",i:"󰾅",l:"Equilibrado"},{p:"throughput-performance",i:"󰓅",l:"Potencia"}]; Rectangle { id: powerChoice; required property var modelData; width: (parent.width - 16) / 3; height: 74; radius: 14; color: root.powerProfile === modelData.p ? "#45475a" : "#313244"; border.width: root.powerProfile === modelData.p ? 1 : 0; border.color: "#cba6f7"; Column { anchors.centerIn: parent; spacing: 5; Text { anchors.horizontalCenter: parent.horizontalCenter; text: powerChoice.modelData.i; color: "#cba6f7"; font.family: "Cascadia Mono NF"; font.pixelSize: 18 } Text { anchors.horizontalCenter: parent.horizontalCenter; text: powerChoice.modelData.l; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 11; font.bold: true } } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setProfile(powerChoice.modelData.p) } } } }
                    SettingsCard { width: parent.width; icon: root.inhibitActive ? "󰅶" : "󰒲"; title: root.inhibitActive ? "Suspensión bloqueada" : "Suspensión normal"; detail: "Evita suspensión durante tareas largas"; button: root.inhibitActive ? "Desactivar" : "No suspender"; onClicked: root.toggleInhibit() }
                    Text { text: Math.round(root.battery.percentage * 100) + "% de batería" + (root.battery.state === 1 ? " · cargando" : ""); color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 11 }
                }

                Column {
                    width: parent.width; spacing: 12; visible: root.page === "display"
                    SettingsCard { width: parent.width; icon: "󰍹"; title: "Pantalla activa"; detail: root.displayInfo; button: "Detectar"; onClicked: displayQuery.running = true }
                    Rectangle { width: parent.width; height: 105; radius: 14; color: "#313244"; Text { anchors.left: parent.left; anchors.leftMargin: 16; anchors.top: parent.top; anchors.topMargin: 14; text: "󰃠  Brillo  " + root.brightness + "%"; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 13; font.bold: true } Slider { id: settingsBrightness; anchors.left: parent.left; anchors.leftMargin: 16; anchors.right: parent.right; anchors.rightMargin: 16; anchors.top: parent.top; anchors.topMargin: 43; from: 5; to: 100; value: root.brightness; onMoved: { root.brightness = Math.round(value); root.run(["brightnessctl", "set", root.brightness + "%"]) } } }
                    SettingsCard { width: parent.width; icon: "󰸉"; title: "Fondo de pantalla"; detail: "Rotación automática cada 15 minutos"; button: "Siguiente"; onClicked: root.run(["systemctl", "--user", "start", "fedora-sway-wallpaper.service"]) }
                }

                Column {
                    width: parent.width; spacing: 12; visible: root.page === "system"
                    SettingsCard { width: parent.width; icon: "󰏔"; title: "Actualizaciones"; detail: "Paquetes, firmware y reinicios pendientes"; button: "Cockpit"; onClicked: root.run(["zen", "--new-window", "https://localhost:9090/system"] ) }
                    SettingsCard { width: parent.width; icon: "󰋊"; title: "Almacenamiento"; detail: "Discos, volúmenes y estado SMART"; button: "Gestionar"; onClicked: root.run(["zen", "--new-window", "https://localhost:9090/storage"] ) }
                    SettingsCard { width: parent.width; icon: "󰡨"; title: "Contenedores y máquinas"; detail: "Podman y virtualización"; button: "Cockpit"; onClicked: root.run(["zen", "--new-window", "https://localhost:9090/machines"] ) }
                }
            }
        }
    }

    component SettingsButton: Rectangle {
        id: buttonRoot
        property string icon: ""; property string label: ""; property color accent: "#cba6f7"
        signal clicked()
        height: 76; radius: 14; color: buttonMouse.containsMouse ? "#3b3d51" : "#313244"
        Column { anchors.centerIn: parent; spacing: 6; Text { anchors.horizontalCenter: parent.horizontalCenter; text: buttonRoot.icon; color: buttonRoot.accent; font.family: "Cascadia Mono NF"; font.pixelSize: 18 } Text { anchors.horizontalCenter: parent.horizontalCenter; text: buttonRoot.label; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 11; font.bold: true } }
        MouseArea { id: buttonMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: buttonRoot.clicked() }
    }
    component SettingsCard: Rectangle {
        id: cardRoot
        property string icon: ""; property string title: ""; property string detail: ""; property string button: "Abrir"
        signal clicked()
        height: 78; radius: 14; color: "#313244"
        Text { anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: cardRoot.icon; color: "#cba6f7"; font.family: "Cascadia Mono NF"; font.pixelSize: 20 }
        Column { anchors.left: parent.left; anchors.leftMargin: 54; anchors.right: actionButton.left; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 4; Text { width: parent.width; text: cardRoot.title; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight } Text { width: parent.width; text: cardRoot.detail; color: "#a6adc8"; font.family: "Cascadia Mono NF"; font.pixelSize: 10; elide: Text.ElideRight } }
        Rectangle { id: actionButton; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; width: 94; height: 34; radius: 10; color: actionMouse.containsMouse ? "#585b70" : "#45475a"; Text { anchors.centerIn: parent; text: cardRoot.button; color: "#cdd6f4"; font.family: "Cascadia Mono NF"; font.pixelSize: 10; font.bold: true } MouseArea { id: actionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cardRoot.clicked() } }
    }
}
