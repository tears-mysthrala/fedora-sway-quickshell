//@ pragma UseQApplication
//@ pragma DropExpensiveFonts
import Quickshell
import "components"

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar { required property var modelData; screen: modelData }
    }
    Launcher {}
    Osd {}
    Notifications {}
}

