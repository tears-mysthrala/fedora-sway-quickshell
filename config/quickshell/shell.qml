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
        }
    }
    Launcher { id: launcher }
    Osd {}
    Notifications {}
}
