//@ pragma UseQApplication
import Quickshell
import "components"

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
            onLauncherRequested: launcher.toggle()
            onQuickSettingsRequested: section => quickSettings.toggle(section)
            onNotificationsRequested: notifications.toggleCenter()
            onSystemSettingsRequested: systemSettings.toggle()
        }
    }
    Launcher { id: launcher }
    Clipboard { id: clipboard }
    QuickSettings { id: quickSettings }
    SystemSettings { id: systemSettings }
    Osd {}
    Notifications { id: notifications }
}
