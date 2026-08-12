# Explicit dependencies

All packages below come from Fedora 44's official repositories. Fedora-owned
transitive RPM dependencies are intentionally omitted.

| Package | Function and necessity | Alternatives considered |
|---|---|---|
| `sway` | Wayland compositor, window manager, workspaces, and IPC. | Hyprland was rejected because Fedora 44 does not package the required stack and the project needs no effects. |
| `quickshell` | QML shell for the bar, launcher, OSD, and notification popup. | Waybar and external launchers would split the UI and do not test the requested Quickshell layer. |
| `swayidle`, `swaylock` | Independent idle policy and PAM-backed locking. | Keeping these in Quickshell would make the visual shell security-critical. |
| `xdg-desktop-portal`, `xdg-desktop-portal-wlr`, `xdg-desktop-portal-gtk` | Portal frontend, wlroots capture, and general GTK portal interfaces. All three have distinct roles. | A GNOME/KDE backend would pull in a broader desktop stack. |
| `pipewire`, `pipewire-pulseaudio`, `wireplumber` | Fedora audio graph, PulseAudio compatibility, and session policy. | No custom audio server is justified. |
| `NetworkManager` | Fedora network service and event source. | Repeated `nmcli` polling is prohibited. |
| `upower` | Event-driven power and battery state. | Direct sysfs polling would add custom hardware logic. |
| `polkit`, `lxqt-policykit` | System authorization and an independent maintained graphical agent. | Quickshell's agent support is deliberately excluded from the critical path. |
| `xorg-x11-server-Xwayland` | Compatibility for X11-only applications. | Pure Wayland cannot meet the XWayland acceptance criterion. |
| `foot` | Small native Wayland terminal and recovery surface. | A heavier terminal brings no v0.1 advantage. |
| `grim`, `slurp` | Wayland screenshot capture and region selection. | Portal screenshots alone are awkward for keybindings. |
| `wl-clipboard` | Wayland clipboard CLI and screenshot-to-clipboard support. | Quickshell clipboard access requires focus and is unsuitable as the general clipboard mechanism. |
| `brightnessctl` | Bounded backlight adjustment when supported by hardware. | Direct sysfs writes would require custom permission handling. |
| `libnotify` | Supplies `notify-send` for testing and user feedback. | A bespoke D-Bus sender would be less readable. |

BlueZ packages are optional because neither VMs nor all laptops expose a
Bluetooth adapter.

`jq` was evaluated but omitted: v0.1 does not consume JSON, and DNF's explicit
`--qf '%{repoid}'` query gives the one field needed without parsing prose.
