# Fedora Sway + Quickshell Workstation

A small, auditable personal development layer for Fedora Server 44. Fedora remains in
charge of the operating system; this repository adds Sway, an event-driven
Quickshell UI, independent idle/lock/polkit processes, and validation tools.

Version 1.1 captures the complete daily setup: an interactive Quickshell bar,
clipboard history, system settings, short bounded transitions, rotating Raiju
wallpapers, a themed GTK greet, dark GTK/Qt defaults and practical floating
window rules. It does not enable autologin, weaken SELinux/firewalld or grant
privileged group membership. Zen, T3 Code and Codex are explicit pinned
artifacts and do not add DNF repositories.

## Observed Fedora 44 VM

These are observed Fedora Server 44 acceptance-VM images using this repository.
The login is a VM framebuffer capture; desktop images are direct `grim`
captures from inside the Sway session.

### Login

![greetd login without autologin](docs/screenshots/00-login.png)

### Desktop and bar

![Minimal Sway desktop with Quickshell bar](docs/screenshots/01-desktop.png)

### Launcher

![Keyboard-driven Quickshell application launcher](docs/screenshots/02-launcher.png)

### Notification popup

![Immediate notification popup without animation](docs/screenshots/03-notification.png)

### Brightness OSD

![One-shot brightness OSD](docs/screenshots/04-osd.png)

### Development terminal and T3 Code

![Alacritty development terminal](docs/screenshots/05-alacritty.png)

![T3 Code running natively on Wayland](docs/screenshots/06-t3code.png)

## From a clean Fedora Server 44 installation

```bash
sudo dnf upgrade --refresh
git clone https://github.com/tears-mysthrala/fedora-sway-quickshell.git
cd fedora-sway-quickshell
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

Reboot after the first installation. The official Fedora greetd package offers
the packaged **Sway** session and never performs autologin. TTY recovery remains:

```bash
exec dbus-run-session sway
```

The default terminal binding is `Super+Enter`; the launcher is `Super+D`, Zen
is `Super+B`, T3 Code is `Super+A`, Neovim is `Super+N`, and clipboard history
is `Super+V`.
`Super+Shift+R` restarts Quickshell without restarting Sway, and
`Super+Shift+E` opens a confirmation before logging out.

Inside a Wayland VM viewer, the host compositor may consume `Super`. No
conflict-free keyboard fallback proved reliable with this VNC backend: F9 is
host dictation, F10 is GTK's menubar, and `Ctrl+Alt` releases the viewer. Use
the clickable `Apps` button in the bar to open the launcher without keyboard
capture. No host/viewer shortcut is reassigned by the demo.

Run `./doctor.sh` inside the graphical session. It distinguishes installed
software from active processes, services, D-Bus integration, and checks that
require manual interaction. Run `./benchmark.sh ab` only when ready to leave
the machine untouched for two ten-minute measurement intervals.

## MKDL development toolchain

The default install includes the small native development surface used by MKDL:
Git/LFS, rootless Podman and Compose tooling, C/C++, Rust, Python, PostgreSQL
client tools, Node 22, Neovim, ripgrep, ShellCheck and Codex CLI.

Do not install Fedora 44's native `elixir` RPM for Kurogane Hub: it is older
than the repository's runtime floor. Use the digest-pinned CI-compatible
toolchain instead:

```bash
cd ~/Work/kurogane-hub
/path/to/fedora-sway-demo/scripts/mkdl-elixir.sh elixir --version
/path/to/fedora-sway-demo/scripts/mkdl-elixir.sh mix test
```

The first invocation downloads a pinned OCI image. Inside Kurogane Hub it
automatically honors that repository's `.forgejo/release-ci-image.txt`, giving
the same Node/Python/Chromium/PostgreSQL/native-build surface as CI; generic
Mix directories use the smaller pinned fallback. It runs rootless, mounts the
working directory plus a dedicated tool cache, and leaves no Elixir service
resident.

Kurogane's registry is private. Authenticate it once with the owner's Forgejo
registry credentials before the first repository-local command:

```bash
podman login herrementari.mkdl.jp
```

The VM confirms that anonymous access is rejected and that the wrapper stops
with this instruction instead of silently substituting the smaller generic
image. Registry credentials are never copied by this repository.

### Zen, Codex CLI and T3 Code

Zen is installed from its official release tarball with a pinned SHA-256. npm
is retained solely for the pinned Codex artifact; the installer puts both
payloads below a project-owned user data directory. T3 Code is likewise a
pinned official AppImage. Authentication and personal profiles are never put
in this repository.

The native ChatGPT RPM is intentionally not mirrored in this repository.
Follow OpenAI's official [ChatGPT desktop app for Linux guide](https://learn.chatgpt.com/docs/linux/linux-app)
to select the current Fedora package for the machine architecture, install it
and keep it updated through OpenAI's signed package repository. `doctor.sh`
detects the app, while the desktop remains fully usable without it.

After installation, authenticate interactively without putting credentials in
this repository:

```bash
codex login
codex --version
```

T3 Code is installed from its official Linux AppImage with a pinned SHA-256.
Launch it from `Apps`, with `Super+A`, or from a terminal:

```bash
t3code
```

## Machine-specific storage

The doctor reports whether an optional `/develop` mount is healthy, but the
installer deliberately does not copy a disk UUID, resize LVM or format a disk.
Those operations are hardware-specific. Configure the mount once with Cockpit
or `/etc/fstab`; keep source code and replaceable build data there, and keep
credentials and irreplaceable data backed up separately.

## Removal

```bash
./uninstall.sh
```

This removes only managed links and project user units, restores safe backups,
and lists packages added by the demo. It never removes shared packages.

See [architecture](docs/ARCHITECTURE.md), [dependencies](docs/DEPENDENCIES.md),
[performance](docs/PERFORMANCE.md), and
[troubleshooting](docs/TROUBLESHOOTING.md). Version 1.0 gates and migration
boundaries are in [acceptance](docs/ACCEPTANCE.md),
[migration](docs/MIGRATION.md), and [updates](docs/UPDATES.md).
