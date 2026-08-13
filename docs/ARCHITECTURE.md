# Architecture

Fedora owns RPM repositories and installed package state, the kernel and
drivers, systemd/logind, NetworkManager, PipeWire/WirePlumber, UPower, BlueZ,
polkit, PAM, SELinux, and firewalld. The repository does not replace or weaken
those facilities.

Sway is the session boundary. It controls displays, input, focus, windows,
workspaces, and keybindings. Quickshell is only the visible shell: bar,
launcher, audio/network/battery display, transient notifications, and OSD.
Its inputs are Sway IPC, PipeWire objects, NetworkManager events, UPower
signals, desktop-entry changes, and notification D-Bus messages.

swayidle, swaylock, and the LXQt polkit agent run independently under systemd
user units. Quickshell has no authentication or safety responsibility. If it
fails, Sway retains its terminal binding and existing applications, while
idle, locking, and authorization processes continue.

Portals use Fedora's Sway selection: `xdg-desktop-portal-wlr` implements
wlroots screenshot/screencast and PipeWire screen capture;
`xdg-desktop-portal-gtk` supplies general interfaces including file chooser
and URI opening. The generic `xdg-desktop-portal` process is their D-Bus
frontend.

Fedora greetd and its packaged PAM stack provide login and keyring startup.
The repository supplies only the greetd session-selection configuration and
backs up the Fedora file before replacing it. There is no autologin. TuneD,
BlueZ, CUPS and Avahi remain ordinary Fedora services with socket/D-Bus
activation where applicable.

The only non-RPM application artifacts are Codex CLI and T3 Code. They are
explicit development requirements, installed under a project-owned user data
directory and pinned by registry integrity/SHA-256. They add no repository and
never run as a daemon. T3 receives the Codex path explicitly and retains the
Electron sandbox.

No project code changes DNF repository configuration, SELinux policy,
firewall state, PAM files or privileged groups. The supported Fedora release
and application pins are defined once in `config/project.conf`.
