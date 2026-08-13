# Explicit dependencies

All packages below come from Fedora 44's official repositories. Fedora-owned
transitive RPM dependencies are intentionally omitted.

For already-installed packages, DNF's `anaconda` origin is also accepted: it
is the label Fedora's official installer records for RPMs laid down from its
installation media. Missing packages must still resolve from `fedora`,
`updates`, or Fedora's Cisco OpenH264 repository; an enabled third-party
repository is never modified and cannot supply a declared project package.

| Package | Function and necessity | Alternatives considered |
|---|---|---|
| `sway` | Wayland compositor, window manager, workspaces, and IPC. | Other compositors add no v1 benefit over Fedora's maintained Sway package. |
| `quickshell` | QML shell for the bar, launcher, OSD, and notification popup. | Waybar and external launchers would split the UI and do not test the requested Quickshell layer. |
| `swayidle`, `swaylock` | Independent idle policy and PAM-backed locking. | Keeping these in Quickshell would make the visual shell security-critical. |
| `xdg-desktop-portal`, `xdg-desktop-portal-wlr`, `xdg-desktop-portal-gtk` | Portal frontend, wlroots capture, and general GTK portal interfaces. All three have distinct roles. | A GNOME/KDE backend would pull in a broader desktop stack. |
| `xdg-utils` | Supplies `xdg-open` for URL and file dispatch through the desktop association/portal path. | Browser-specific launch commands would bypass normal desktop integration. |
| `pipewire`, `pipewire-pulseaudio`, `wireplumber` | Fedora audio graph, PulseAudio compatibility, and session policy. | No custom audio server is justified. |
| `NetworkManager` | Fedora network service and event source. The Fedora 44 Quickshell build exposes no Ethernet rows in QEMU, so the widget uses one long-lived `nmcli monitor` D-Bus listener and a bounded query only on actual events. | Repeated `nmcli` polling is prohibited; the packaged direct model remains the preferred replacement once it reports the device. |
| `dbus-daemon` | Provides `dbus-run-session`, used to create an isolated D-Bus session when Sway is started directly from a Fedora Server TTY. | `dbus-broker` remains Fedora's system implementation but does not provide this launcher utility. |
| `upower` | Event-driven power and battery state. | Direct sysfs polling would add custom hardware logic. |
| `polkit`, `lxqt-policykit` | System authorization and an independent maintained graphical agent. | Quickshell's agent support is deliberately excluded from the critical path. |
| `xorg-x11-server-Xwayland` | Compatibility for X11-only applications. | Pure Wayland cannot meet the XWayland acceptance criterion. |
| `alacritty` | Conventional GPU-accelerated terminal and recovery surface, selected for a familiar single launcher entry. | Foot is smaller and Wayland-native but exposed confusing client/server launcher entries; Kitty and WezTerm add broader feature surfaces. |
| `grim`, `slurp` | Wayland screenshot capture and region selection. | Portal screenshots alone are awkward for keybindings. |
| `wl-clipboard` | Wayland clipboard CLI and screenshot-to-clipboard support. | Quickshell clipboard access requires focus and is unsuitable as the general clipboard mechanism. |
| `brightnessctl` | Bounded backlight adjustment when supported by hardware. | Direct sysfs writes would require custom permission handling. |
| `libnotify` | Supplies `notify-send` for testing and user feedback. | A bespoke D-Bus sender would be less readable. |
| `firefox` | Normal browser workload and the primary interactive portal/screen-sharing test client. | A browser is required to validate workstation behavior; adding several would not improve v1. |
| `Thunar`, `mousepad` | Lightweight conventional file manager and graphical text editor. | Larger desktop suites are outside scope. |
| `pavucontrol` | Maintained graphical PipeWire/PulseAudio diagnostic and control surface. | The shell widget remains intentionally small and is not an audio routing UI. |
| `imv` | Small Wayland-capable image viewer for screenshots and local images. | Browser-only viewing would weaken the basic offline application set. |
| `git`, `git-lfs` | MKDL source control, large-file pointers, and Forgejo/GitHub interoperability. | Both are used by the existing repositories. |
| `gcc`, `gcc-c++`, `make`, `cmake`, `openssl-devel` | Native compilation surface for BEAM NIFs and other project dependencies. | Installing compilers only after a dependency fails makes setup non-reproducible. |
| `podman`, `podman-compose`, `buildah`, `skopeo` | Rootless OCI development, Compose-compatible labs, image building and inspection. | Docker would require a third-party repository and a privileged daemon. |
| `postgresql` | PostgreSQL client tools used by Kurogane development and diagnostics. | The server is deliberately not enabled or initialized by the workstation installer. |
| `nodejs22`, `nodejs22-bin`, `nodejs22-npm` | Governed JavaScript tests require `node`; npm is retained only as OpenAI's official Codex CLI distribution mechanism. | Kurogane application dependencies still must not use npm. |
| `@openai/codex` | Official Linux coding agent used to inspect and refine this repository from inside the target VM. Installed in a project-owned user prefix; version and registry SHA-512 integrity are pinned. | OpenAI's ChatGPT Linux preview RPM enables an external repository; Codex plus T3 covers the required workflow without adding it. |
| `python3`, `python3-devel`, `python3-pip` | Existing repository checks and native Python extension builds. | Fedora's system Python remains authoritative; pip is not invoked by the installer. |
| `rust`, `cargo` | Rust/NIF development and auditing. | The Fedora toolchain is sufficient for the workstation baseline. |
| `neovim`, `ripgrep`, `ShellCheck` | Editor, fast code search, and shell validation. | They cover the common terminal workflow without installing an IDE ecosystem. |
| `greetd`, `tuigreet`, `greetd-selinux` | Small PAM login path and Fedora SELinux policy for starting the packaged Sway session. | A full GNOME/KDE display manager is unnecessary; autologin is deliberately excluded. |
| `gnome-keyring`, `gnome-keyring-pam`, `libsecret` | PAM-unlocked Secret Service used by T3 Code and other desktop applications. | Plain-text credential storage and sandbox-disabling flags are unacceptable. |
| `gvfs`, `gvfs-mtp`, `gvfs-smb`, `udisks2`, `tumbler`, Thunar plugins | Maintained removable-media, network-filesystem, phone, thumbnail and archive integration. | Reimplementing these desktop protocols would be larger and less auditable. |
| `tuned-ppd`, `fwupd` | Fedora's power-profile API backed by TuneD and supported firmware updates. | A custom power daemon would conflict with Fedora ownership; `power-profiles-daemon` is superseded by this Fedora integration. |
| `bluez`, `blueman`, NetworkManager applets | Bluetooth and interactive network control when hardware exists. Services remain event-driven. | Shell polling and custom pairing UI are outside scope. |
| CUPS, Avahi and SANE packages | Socket-activated printing/discovery and scanning for a usable personal workstation. | No project print daemon or permanently polling helper is introduced. |
| `qemu-kvm`, `virt-manager`, `edk2-ovmf`, `swtpm` | VM development and repeatable acceptance on the same workstation. | System-mode libvirt groups are not required; the user session URI works without privilege changes. |
| `jq`, `yq` | Readable JSON/YAML inspection in doctor, VM acceptance, Sway-tree and update checks. | Shell-only parsing made protocol tests brittle; these tools are actively exercised. |
| `fuse` | Supplies `fusermount`, required to mount the verified T3 Code AppImage. | Extracting the AppImage on every update duplicates upstream layout and complicates integrity cleanup. |
| `curl`, `file` | TLS download of pinned artifacts and deterministic artifact/screenshot type checks. | Piped execution is never used; downloads are files verified before execution. |
| `gh`, `ansible-core`, `opentofu`, `rclone`, `restic`, `tailscale`, `wireguard-tools` | Personal MKDL/Forgejo, infrastructure, backup/sync and private-network development surfaces observed on the source workstation. | They are inert command-line tools until invoked; no project cloud account or resident telemetry is configured. |

The installer disables weak dependencies for its DNF transaction. This avoids
offline Node documentation, full locale data and cross-architecture emulators.
npm is explicit because Codex officially uses it; it is not used for Kurogane
application dependencies.

### Elixir and Erlang

Fedora 44 currently resolves `elixir` 1.19.5 and Erlang/OTP 26, while Kurogane
Hub requires Elixir 1.20.1 or newer and its current CI image uses OTP 29.
Installing those RPMs would create a plausible-looking but incompatible native
toolchain. The demo therefore installs no host Elixir/Erlang RPM.

`scripts/mkdl-elixir.sh` runs the current Kurogane CI toolchain through rootless
Podman. In a Kurogane checkout it consumes the repository-authoritative
`.forgejo/release-ci-image.txt`, which includes the compiler, Node, Python,
Chromium and PostgreSQL tooling used by CI. Other Mix projects use the minimal
fallback image centralized in `config/mkdl-toolchain.conf`. Both references are
SHA-256 pinned and fetched only when invoked, never at desktop login or as a
resident service. OCI images are explicit development inputs, not Fedora
packages or package repositories.

BlueZ is installed because the v1 target is a laptop workstation, but lack of
an adapter is informational and does not fail the VM doctor.

### Pinned non-RPM applications

T3 Code is the one upstream desktop artifact: the official x86_64 AppImage is
versioned in `config/project.conf`, verified with SHA-256 before execution and
stored below the user's XDG data directory. `fuse` mounts it with Electron's
sandbox intact. Codex CLI follows OpenAI's official npm distribution, but its
version and registry integrity are pinned into a project-owned user prefix.
Neither mechanism adds a DNF repository or writes system package state.

## Primary upstream references

- [Fedora 44 Quickshell package](https://packages.fedoraproject.org/pkgs/quickshell/quickshell/fedora-44.html)
- [Fedora 44 xdg-desktop-portal-wlr package](https://packages.fedoraproject.org/pkgs/xdg-desktop-portal-wlr/xdg-desktop-portal-wlr/fedora-44.html)
- [XDG portal backend selection](https://flatpak.github.io/xdg-desktop-portal/docs/portals.conf.html)
- [T3 Code upstream and releases](https://github.com/pingdotgg/t3code/releases)
- [OpenAI Codex CLI documentation](https://developers.openai.com/codex/cli)
- [ChatGPT Linux preview documentation](https://learn.chatgpt.com/docs/linux/linux-app)
