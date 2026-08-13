# Explicit dependencies

All packages below come from Fedora 44's official repositories. Fedora-owned
transitive RPM dependencies are intentionally omitted.

| Package | Function and necessity | Alternatives considered |
|---|---|---|
| `sway` | Wayland compositor, window manager, workspaces, and IPC. | Other compositors add no v0.1 benefit over Fedora's maintained Sway package. |
| `quickshell` | QML shell for the bar, launcher, OSD, and notification popup. | Waybar and external launchers would split the UI and do not test the requested Quickshell layer. |
| `swayidle`, `swaylock` | Independent idle policy and PAM-backed locking. | Keeping these in Quickshell would make the visual shell security-critical. |
| `xdg-desktop-portal`, `xdg-desktop-portal-wlr`, `xdg-desktop-portal-gtk` | Portal frontend, wlroots capture, and general GTK portal interfaces. All three have distinct roles. | A GNOME/KDE backend would pull in a broader desktop stack. |
| `pipewire`, `pipewire-pulseaudio`, `wireplumber` | Fedora audio graph, PulseAudio compatibility, and session policy. | No custom audio server is justified. |
| `NetworkManager` | Fedora network service and event source. | Repeated `nmcli` polling is prohibited. |
| `dbus-daemon` | Provides `dbus-run-session`, used to create an isolated D-Bus session when Sway is started directly from a Fedora Server TTY. | `dbus-broker` remains Fedora's system implementation but does not provide this launcher utility. |
| `upower` | Event-driven power and battery state. | Direct sysfs polling would add custom hardware logic. |
| `polkit`, `lxqt-policykit` | System authorization and an independent maintained graphical agent. | Quickshell's agent support is deliberately excluded from the critical path. |
| `xorg-x11-server-Xwayland` | Compatibility for X11-only applications. | Pure Wayland cannot meet the XWayland acceptance criterion. |
| `alacritty` | Conventional GPU-accelerated terminal and recovery surface, selected for a familiar single launcher entry. | Foot is smaller and Wayland-native but exposed confusing client/server launcher entries; Kitty and WezTerm add broader feature surfaces. |
| `grim`, `slurp` | Wayland screenshot capture and region selection. | Portal screenshots alone are awkward for keybindings. |
| `wl-clipboard` | Wayland clipboard CLI and screenshot-to-clipboard support. | Quickshell clipboard access requires focus and is unsuitable as the general clipboard mechanism. |
| `brightnessctl` | Bounded backlight adjustment when supported by hardware. | Direct sysfs writes would require custom permission handling. |
| `libnotify` | Supplies `notify-send` for testing and user feedback. | A bespoke D-Bus sender would be less readable. |
| `firefox` | Normal browser workload and the primary interactive portal/screen-sharing test client. | A browser is required to validate workstation behavior; adding several would not improve v0.1. |
| `Thunar`, `mousepad` | Lightweight conventional file manager and graphical text editor. | Larger desktop suites are outside scope. |
| `pavucontrol` | Maintained graphical PipeWire/PulseAudio diagnostic and control surface. | The shell widget remains intentionally small and is not an audio routing UI. |
| `imv` | Small Wayland-capable image viewer for screenshots and local images. | Browser-only viewing would weaken the basic offline application set. |
| `git`, `git-lfs` | MKDL source control, large-file pointers, and Forgejo/GitHub interoperability. | Both are used by the existing repositories. |
| `gcc`, `gcc-c++`, `make`, `cmake`, `openssl-devel` | Native compilation surface for BEAM NIFs and other project dependencies. | Installing compilers only after a dependency fails makes setup non-reproducible. |
| `podman`, `podman-compose`, `buildah`, `skopeo` | Rootless OCI development, Compose-compatible labs, image building and inspection. | Docker would require a third-party repository and a privileged daemon. |
| `postgresql` | PostgreSQL client tools used by Kurogane development and diagnostics. | The server is deliberately not enabled or initialized by the workstation installer. |
| `nodejs22`, `nodejs22-bin`, `nodejs22-npm` | Governed JavaScript tests require `node`; npm is retained only as OpenAI's official Codex CLI distribution mechanism. | Kurogane application dependencies still must not use npm. |
| `@openai/codex` | Official Linux coding agent used to inspect and refine this repository from inside the target VM. Installed in a project-owned user prefix; version and registry SHA-512 integrity are pinned. | The new ChatGPT desktop app is not currently published for Linux. |
| `python3`, `python3-devel`, `python3-pip` | Existing repository checks and native Python extension builds. | Fedora's system Python remains authoritative; pip is not invoked by the installer. |
| `rust`, `cargo` | Rust/NIF development and auditing. | The Fedora toolchain is sufficient for the workstation baseline. |
| `neovim`, `ripgrep`, `ShellCheck` | Editor, fast code search, and shell validation. | They cover the common terminal workflow without installing an IDE ecosystem. |

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
Podman. The image reference is centralized in `config/mkdl-toolchain.conf` and
pinned by SHA-256 digest. It is fetched only when the developer invokes the
script, never during desktop login or as a resident service. This OCI image is
an explicit development input, not a Fedora package or package repository.

BlueZ packages are optional because neither VMs nor all laptops expose a
Bluetooth adapter.

`jq` was evaluated but omitted: v0.1 does not consume JSON, and DNF's explicit
`--qf '%{repoid}'` query gives the one field needed without parsing prose.
