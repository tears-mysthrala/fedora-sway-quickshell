# Fedora Sway + Quickshell Demo v0.1 Design

## Purpose

Build an auditable repository that converts an updated, clean Fedora Server 44 installation into a small Wayland workstation for laptops. Fedora remains responsible for the operating system, packages, security controls, and core services. The repository owns only the selected packages, user configuration, user services, diagnostics, and test tooling.

The project is not a distribution, an Omarchy replica, or a general desktop framework. It supports Fedora 44 only and uses Fedora's official repositories exclusively.

## Priorities

The design optimizes in this order:

1. performance;
2. energy efficiency;
3. simplicity;
4. maintainability;
5. auditability;
6. robustness;
7. comfort;
8. aesthetics.

Visual polish must not introduce continuous CPU or GPU activity. Project configuration contains no workspace transitions, window animations, fades, blur, glow, expensive shadows, wallpaper transitions, launcher animations, notification animations, OSD animations, or spring effects.

## Supported Platform

- Fedora Server 44, updated from official Fedora repositories.
- x86_64 is the first validated architecture because the acceptance VM runs under QEMU/KVM on the development host.
- systemd-logind user sessions with Sway's packaged Wayland session.
- SELinux remains enforcing and firewalld remains enabled.
- The installer does not configure autologin, a display manager, firewall rules, SELinux policy, privileged groups, repositories, or system upgrades.

The development host runs Omarchy rather than Fedora. Static checks run on the host; installation, login, portal, screen-sharing, failure-isolation, and performance acceptance tests run in a Fedora Server 44 QEMU/KVM VM.

## Architecture and Ownership

### Fedora system layer

Fedora owns DNF repositories and RPM state, systemd, logind, NetworkManager, PipeWire, WirePlumber, BlueZ when installed, UPower, polkit, SELinux, firewalld, kernel, graphics drivers, and the XWayland server.

### Session layer

Sway owns outputs, inputs, window management, focus, workspaces, and keybindings. It starts independent session processes for Quickshell, swayidle, and the LXQt polkit agent. A Quickshell crash therefore cannot stop Sway, locking, idle handling, authentication, or terminal access.

swayidle invokes swaylock before sleep and after the configured idle timeout. swaylock relies on Fedora's packaged PAM configuration. Quickshell never implements authentication, locking, or idle policy.

### Shell layer

Quickshell owns only the visible shell:

- top bar: workspaces, active window, network, audio, battery when present, and clock;
- keyboard-driven application launcher using desktop entries;
- volume and brightness OSD;
- simple notification popups.

The implementation uses Quickshell's event-oriented integrations: I3/Sway IPC, PipeWire, UPower, desktop entries, and the notification service. Network state uses a persistent NetworkManager event source or direct supported integration, never repeated `nmcli` execution. If no reasonable event-driven source exists, the corresponding informational widget is omitted. The clock updates once per minute, aligned to a minute boundary. OSD and notification dismissal use one-shot timeouts. These are the only project-created periodic or timed activities unless a later measured requirement is documented.

Notifications in v0.1 consist only of a notification daemon and immediate popup. A popup disappears after its one-shot timeout without animation. There is no history, notification center, persistence, database, complex state model, or non-trivial action handling.

QML must not contain `Behavior`, `NumberAnimation`, `PropertyAnimation`, `SpringAnimation`, `SequentialAnimation`, or `ParallelAnimation` in v0.1.

## Fedora Package Surface

The mandatory explicit package set uses real Fedora names:

- compositor/session: `sway`, `xorg-x11-server-Xwayland`;
- shell: `quickshell`;
- idle/lock: `swayidle`, `swaylock`;
- portals: `xdg-desktop-portal`, `xdg-desktop-portal-wlr`, `xdg-desktop-portal-gtk`;
- audio/session services: `pipewire`, `pipewire-pulseaudio`, `wireplumber`;
- system integration: `NetworkManager`, `upower`, `polkit`, `lxqt-policykit`;
- workstation tools: `foot`, `grim`, `slurp`, `wl-clipboard`, `brightnessctl`;
- diagnostics and scripting: `bash`, `coreutils`, `findutils`, `grep`, `procps-ng`, `systemd`, `util-linux` and, only if its actual use materially improves safe JSON parsing, `jq`.

BlueZ is optional because not every VM or target has Bluetooth. GPU measurement tools are optional and hardware-specific. Every explicit dependency and considered alternative is documented in `docs/DEPENDENCIES.md`; RPM transaction dependencies are not duplicated as project choices.

Package availability is checked at runtime with DNF before installation. Fedora 44 is a hard requirement for v0.1 because it supplies Quickshell in the official repository. The supported release is defined once in a shared project constants file and consumed by the installer, doctor, tests, VM harness, and documentation checks. Project packages must resolve from the allowed official Fedora repositories.

## Portal Selection

The project uses Fedora's packaged Sway portal selection:

- `xdg-desktop-portal-wlr` supplies wlroots screenshot and screencast interfaces and exports screen capture through PipeWire;
- `xdg-desktop-portal-gtk` supplies general GTK-backed interfaces such as file chooser and URI opening;
- `xdg-desktop-portal` is the D-Bus frontend.

The session imports `WAYLAND_DISPLAY`, `SWAYSOCK`, and the appropriate desktop identity into the systemd user and D-Bus activation environments. Diagnostics query D-Bus ownership and user-unit state, not merely installed binaries.

Acceptance exercises file chooser, URI opening, screenshot, screencast, PipeWire screen sharing, a browser, and an Electron application where one is available from the agreed package set. Browser or Electron installation used only for validation belongs in the optional test package set, not the minimal runtime.

## Repository Layout

```text
fedora-sway-quickshell-demo/
├── README.md
├── install.sh
├── uninstall.sh
├── doctor.sh
├── benchmark.sh
├── packages/
│   ├── base.txt
│   ├── desktop.txt
│   └── optional.txt
├── config/
│   ├── sway/
│   ├── quickshell/
│   ├── swayidle/
│   ├── swaylock/
│   ├── systemd/user/
│   └── environment.d/
├── scripts/
│   ├── lib/
│   └── vm/
├── tests/
│   ├── static/
│   └── vm/
└── docs/
    ├── ARCHITECTURE.md
    ├── DEPENDENCIES.md
    ├── PERFORMANCE.md
    └── TROUBLESHOOTING.md
```

VM provisioning remains under `scripts/vm/` and is never called by `install.sh`.

## Installation and Dotfile Safety

`install.sh` supports normal, `--check`, and `--dry-run` modes. It:

1. verifies Fedora and version 44;
2. checks repository metadata access without changing repository configuration;
3. resolves every requested package before changing RPM state and verifies that the selected package origin is an allowed Fedora repository;
4. permits unrelated third-party repositories to remain enabled but aborts if a project-managed package would resolve from an unauthorized origin;
5. records which packages were absent before installation;
6. installs only the declared package set;
7. creates backups before replacing conflicting user paths;
8. creates repository-to-`~/.config` symlinks;
9. enables only project-owned user units where needed;
10. reports checks and required logout/login actions.

Managed state is recorded below `~/.local/state/fedora-sway-quickshell-demo/`. Repeated execution converges without duplicate configuration or backups.

`uninstall.sh` removes only managed links and project-owned user units. It restores a backup only when the destination is still project-managed and restoration cannot overwrite newer user data. It lists packages installed during bootstrap but never removes them automatically.

Repository configuration is outside project ownership. No script enables, disables, adds, removes, or edits a user's repositories.

## Sway Configuration

The Sway configuration is intentionally small. It defines:

- terminal, launcher, close, fullscreen, floating toggle, lock, and Quickshell restart;
- focus movement;
- workspaces 1 through 9 and moving containers to them;
- screenshot selection and full-output capture;
- clipboard tools;
- PipeWire volume and mute controls;
- brightness control when a backlight interface exists;
- startup of independent session components;
- `swaybar_command` disabled because Quickshell provides the bar.

Keybindings invoke small scripts only when hardware detection, OSD signaling, or safe error reporting justifies them. Scripts perform one bounded action per input event and contain no polling loops.

## Diagnostics

`doctor.sh` reports distinct states for:

- Fedora identity and version;
- package installation;
- Wayland/Sway IPC functionality;
- Quickshell IPC/process functionality;
- XWayland socket/process availability;
- portal frontend and selected backends through systemd/D-Bus;
- PipeWire graph responsiveness and WirePlumber user service;
- LXQt polkit agent process and polkit D-Bus service;
- swayidle process and swaylock executable plus an explicit non-disruptive/manual lock test distinction;
- NetworkManager service and D-Bus connectivity;
- UPower D-Bus availability and battery presence.

Unavailable hardware is `[INFO]`, degraded integration is `[WARN]`, and a failed required runtime is `[FAIL]`. `[OK]` is never based solely on `command -v`.

## Performance Baseline

`benchmark.sh` collects measurements without claiming universal thresholds. Every reported field is labeled `measured`, `estimated`, or `unavailable`:

- hardware and virtualization information;
- Fedora, Sway, and Quickshell versions;
- total used memory after login;
- proportional or resident memory for Sway and Quickshell, clearly labeled;
- sampled desktop CPU at idle;
- approximate process count associated with the desktop session;
- session-to-usable time using monotonic timestamps recorded by project user units;
- project periodic timers and known long-lived event listeners;
- GPU idle utilization only when a reliable, non-invasive hardware interface exists.

The primary idle measurement is a controlled interval: wait for the session to stabilize, record T0, leave the session untouched for ten minutes, then record T+10m. The comparison records cumulative CPU time for Sway and Quickshell, initial and final RSS, RSS change, voluntary and involuntary context switches, process creation or disappearance, project timers, long-lived event listeners, and approximate wakeups only when a reliable non-invasive source exists.

The VM acceptance run performs two matched ten-minute intervals:

- A: Sway without Quickshell;
- B: Sway with the complete v0.1 Quickshell configuration.

The report compares CPU time, memory, context switches or wakeup estimates, processes, and GPU activity where available. The incremental shell cost is reported as B minus A without an invented pass/fail threshold.

`docs/PERFORMANCE.md` contains the measurement procedure and a template. Generated machine results are timestamped and ignored by Git unless deliberately promoted into documentation. A first committed baseline is added only after the Fedora VM reaches a stable idle state.

## Testing Strategy

### Static host tests

- shell syntax and ShellCheck when available;
- package-list format, uniqueness, and forbidden-package checks;
- idempotency model tests using a temporary HOME and mocked DNF/systemctl commands;
- QML forbidden-animation and polling-pattern scans;
- configuration ownership and symlink safety tests;
- documentation completeness checks.

### Fedora VM tests

The QEMU/KVM harness creates a disposable Fedora Server 44 VM with a dedicated disk image. It never modifies an existing VM or image. Credentials are local test credentials supplied interactively or through a non-versioned environment file.

VM acceptance verifies:

1. clean installation and a second idempotent run;
2. Sway login and usable terminal;
3. Quickshell bar, launcher, workspaces, audio, clipboard, screenshots, XWayland, lock, idle, and polkit;
4. portal file chooser, URI opening, screenshot, screencast, and PipeWire sharing;
5. terminate Quickshell while Sway, applications, swayidle, swaylock, polkit, and terminal keybinding remain functional;
6. restart Quickshell without ending the session;
7. collect the first A/B ten-minute performance baseline;
8. confirm SELinux enforcing and firewalld active.

Checks requiring visual or security-sensitive interaction are explicitly marked manual and accompanied by commands and expected evidence. Results are not reported as verified until observed in the VM.

## Failure Handling and Recovery

- Package resolution fails before any installation if a required Fedora package is unavailable.
- Conflicting dotfiles are backed up and reported; arbitrary files are never overwritten.
- Quickshell failure leaves Sway and independent security/session processes alive.
- Portal failures are diagnosable through user-unit state, D-Bus names, environment, and journal commands.
- TTY recovery instructions cover disabling project user units, restoring managed backups, checking logs, and starting Sway manually.
- No script disables SELinux, firewalld, authentication, or access controls, uses remote scripts, or assigns privileged groups.

## v0.1 Completion Criteria

Completion requires both repository verification and observed Fedora 44 VM evidence for every runtime criterion. The project is not complete merely because files exist or static tests pass. Any untestable hardware-specific item is reported as unavailable with its manual verification procedure; it is not silently promoted to success.
