# Version 1.0 acceptance

Version 1.0 is a personal Fedora 44 development workstation, not a general
distribution. Acceptance is evidence-based and is run on a clean Fedora Server
VM before the same repository is used on a laptop.

## Automated gates

```bash
tests/static/run.sh
tests/vm/acceptance.sh
security-check.sh
benchmark.sh ab
```

The VM gate requires Fedora 44, SELinux Enforcing and active firewalld. It runs
the installer twice, `--check`, the doctor, direct and portal capture checks,
the security check, the Quickshell failure-isolation test, the MKDL BEAM smoke
project, Codex/T3 discovery and a performance snapshot.

## Observed QEMU result

On 2026-08-13 the Fedora Server 44 acceptance VM completed a real greetd/PAM
login into Sway. The isolation test opened two terminals, stopped Quickshell,
changed workspaces, opened another terminal, retained the original swayidle and
polkit-agent processes, started an observable foreground swaylock, and then
restarted Quickshell without restarting Sway. XWayland managed a forced X11
Alacritty client; the Wayland clipboard round trip, direct screenshot, portal
services, a Firefox-to-`xdg-desktop-portal-wlr` PipeWire screen stream, T3
native-Wayland window, Codex discovery, and a generated Elixir 1.20.1/OTP 29
Mix test all passed. `wpctl` showed Firefox consuming the active
`xdg-desktop-portal-wlr:capture_1` stream. The exact raw evidence remains local
to the disposable VM rather than embedding machine state or credentials in
Git.

Firefox's normal hardware WebRender path corrupted the unaccelerated QEMU
virtio scanout during this test. A disposable Firefox profile with
`gfx.webrender.software=true` rendered correctly and completed the portal
test. This is a VM-only test workaround: the project does not force software
rendering on a real laptop.

## Session and laptop

- greetd offers the packaged Sway session without autologin;
- Spanish keyboard, Caps Compose and touchpad tap/natural scrolling work;
- Sway provides terminal, browser, file manager, editor, T3 Code, workspaces,
  focus, move, close, fullscreen, floating, lock, media, volume and brightness;
- TuneD exposes Fedora power profiles and suspend/lock remains independent;
- NetworkManager, BlueZ, UPower, CUPS and removable storage have maintained
  control surfaces;
- gnome-keyring supplies the Secret Service through Fedora's greetd PAM stack.

## Development

- Codex CLI is version/integrity pinned and authentication remains interactive;
- T3 Code's upstream AppImage is SHA-256 pinned, runs on native Wayland and can
  discover the managed Codex CLI without `--no-sandbox`;
- `mix`, `elixir` and `iex` transparently enter the digest-pinned MKDL OCI
  toolchain; a generated Mix project compiles and tests;
- Git/LFS, SSH, `gh`, Node, Python, Rust, PostgreSQL client, rootless Podman,
  Docker compatibility, QEMU session mode and infrastructure tools respond;
- no project action adds the user to `docker`, `libvirt`, `wheel` or another
  privileged group.

## Manual gates before replacing a laptop

- authenticate Codex and create a T3 Code thread in a disposable repository;
- authenticate Podman to `herrementari.mkdl.jp` and pull Kurogane's exact
  digest-pinned CI image (anonymous access is intentionally rejected);
- select a file in Firefox through the GTK portal;
- repeat Firefox screen sharing on the laptop GPU and retain the portal/PipeWire
  journal;
- pair one Bluetooth device, test speakers/microphone and suspend/resume;
- connect the real external display(s), printer and removable storage used by
  the owner;
- run the 20-minute A/B benchmark on AC and battery and record the hardware row
  in `PERFORMANCE.md`.

These hardware/account gates cannot be truthfully simulated by QEMU. Their
absence does not authorize disabling SELinux, firewalld or sandboxing.
