//@ pragma UseQApplication
import Quickshell
import "components"

ShellRoot {
    // Compositor state shared by the bar and settings. Dormant on Sway.
    NiriState { id: niriState }
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
            niri: niriState
            onLauncherRequested: launcher.toggle()
            onQuickSettingsRequested: section => quickSettings.toggle(section)
            onNotificationsRequested: notifications.toggleCenter()
            onSystemSettingsRequested: systemSettings.toggle()
        }
    }
    Launcher { id: launcher }
    Clipboard { id: clipboard }
    QuickSettings { id: quickSettings }
    SystemSettings { id: systemSettings; niri: niriState }
    Osd {}
    Notifications { id: notifications }
}
