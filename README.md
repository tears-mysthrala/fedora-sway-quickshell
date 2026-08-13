# Fedora Sway + Quickshell Demo

A small, auditable desktop layer for Fedora Server 44. Fedora remains in
charge of the operating system; this repository adds Sway, an event-driven
Quickshell UI, independent idle/lock/polkit processes, and validation tools.

The v0.1 priority is performance and laptop efficiency. It configures no
animations, visual effects, recurring subprocess polling, external package
repositories, autologin, SELinux changes, or firewall changes.

## Observed Fedora 44 VM

These images are direct `grim` captures from the Fedora Server 44 acceptance
VM, using the configuration in this repository.

### Desktop and bar

![Minimal Sway desktop with Quickshell bar](docs/screenshots/01-desktop.png)

### Launcher

![Keyboard-driven Quickshell application launcher](docs/screenshots/02-launcher.png)

### Notification popup

![Immediate notification popup without animation](docs/screenshots/03-notification.png)

### Brightness OSD

![One-shot brightness OSD](docs/screenshots/04-osd.png)

## From a clean Fedora Server 44 installation

```bash
sudo dnf upgrade --refresh
git clone <repo> fedora-sway-quickshell-demo
cd fedora-sway-quickshell-demo
./install.sh --dry-run
./install.sh
```

The installer verifies every declared package's selected repository before
mutating RPM state. Enabled third-party repositories are left untouched, but
a project package resolving from one causes a clear failure. Conflicting
configuration is backed up below
`~/.local/state/fedora-sway-quickshell-demo/` before repository-owned symlinks
are created.

Run `./install.sh` again to confirm convergence. `./install.sh --check` performs
platform/package checks without changing configuration.

## Start the session

Log out, select the packaged **Sway** session in a display manager if one is
installed, or start it from a TTY with:

```bash
exec dbus-run-session sway
```

The default terminal binding is `Super+Enter`; the launcher is `Super+D`.
`Super+Shift+R` restarts Quickshell without restarting Sway.

Inside a Wayland VM viewer, the host compositor may consume `Super` and other
modifier combinations. The demo also provides `F9` for the terminal, `F10` for
the launcher, `F11` to restart Quickshell, and `F12` to lock. Click once inside
the display to focus it; virt-manager's default release chord is `Ctrl+Alt`.

Run `./doctor.sh` inside the graphical session. It distinguishes installed
software from active processes, services, D-Bus integration, and checks that
require manual interaction. Run `./benchmark.sh ab` only when ready to leave
the machine untouched for two ten-minute measurement intervals.

## Removal

```bash
./uninstall.sh
```

This removes only managed links and project user units, restores safe backups,
and lists packages added by the demo. It never removes shared packages.

See [architecture](docs/ARCHITECTURE.md), [dependencies](docs/DEPENDENCIES.md),
[performance](docs/PERFORMANCE.md), and
[troubleshooting](docs/TROUBLESHOOTING.md).
