# Troubleshooting

Start with `./doctor.sh` and the current boot's user journal:

```bash
journalctl --user -b --no-pager
```

## greetd login does not appear

Switch to a TTY and inspect `systemctl status greetd`. Validate
`/etc/greetd/config.toml` against `config/greetd/config.toml` and run
`sudo scripts/system-setup.sh check`. The installer never enables autologin.
If another display manager was already configured, system setup deliberately
refuses to replace it.

## Sway does not start

From a TTY, run `dbus-run-session sway -d 2>sway.log`. Check graphics support,
permissions on `/dev/dri`, and `journalctl -b`. Do not disable SELinux; inspect
`ausearch -m AVC -ts recent` if an AVC exists.

## Quickshell does not appear

Run `systemctl --user status fedora-sway-quickshell.service` and `journalctl
--user -b -u fedora-sway-quickshell.service`. Validate QML with `qmllint`.
Sway and `Super+Enter` remain usable. Restart with `Super+Shift+R`.

## Portal or screen sharing is broken

Run `scripts/check-portals.sh`, inspect all three portal user units, and verify
that `WAYLAND_DISPLAY`, `SWAYSOCK`, and `XDG_CURRENT_DESKTOP=sway` reached the
systemd user environment. Restarting portal user units ends active shares.
Check PipeWire with `wpctl status` before testing browser/Electron sharing.

An unaccelerated QEMU virtio display may turn solid red after a GPU-rendered
Firefox or Electron/T3 window opens or exits. The acceptance VM reproduced
this as a virtual-GPU scanout failure, not a Quickshell layout failure. Restart
the disposable VM. For Firefox portal diagnosis, create a separate test profile with
`user_pref("gfx.webrender.software", true)`, and repeat the portal test there.
Mozilla uses the same preference for its software-WebRender test path in
[Bug 1752113](https://bugzilla.mozilla.org/show_bug.cgi?id=1752113). Do not put
that override in the repository's laptop configuration; inspect
`about:support` and the real GPU driver first.

## Audio is broken

Check `systemctl --user status pipewire wireplumber` and `wpctl status`. Do not
replace Fedora's audio stack or launch a second PipeWire instance.

## Polkit prompt does not appear

Check the system `polkit.service` and user `fedora-sway-polkit.service`. Ensure
only one graphical authentication agent owns the session role.

## Keyring or stored application credentials do not work

Run `busctl --user status org.freedesktop.secrets` after logging in through
greetd. Fedora's `/etc/pam.d/greetd` starts and unlocks gnome-keyring; the
project does not replace that PAM policy. A session started manually with
`dbus-run-session sway` may not unlock the login keyring.

## Codex or T3 Code does not work

Run `codex --version`, `codex login status`,
`scripts/install-t3code.sh check`, and launch `t3code` from Alacritty to retain
the Electron log. T3 must see `CODEX_CLI_PATH=~/.local/bin/codex`; the managed
wrapper sets it. Do not solve an Electron failure with `--no-sandbox`.
If AppImage reports that it cannot execute `fusermount`, rerun the installer
and verify the Fedora `fuse` package; `fuse-libs` alone is insufficient. T3's
mutable URL-handler registration is isolated below its project-owned XDG data
tree so it cannot replace the repository launcher symlink.

## Mix/Elixir cannot reach local PostgreSQL

The managed commands run in the pinned rootless OCI image with host networking.
Set normal variables such as `DATABASE_URL`, `PGHOST` or `MIX_ENV` before
running `mix`; the wrapper forwards only the documented allowlist. Confirm the
container image with `podman images` and `elixir --version`.

## Power profile unavailable

Check `systemctl status tuned` and `tuned-adm active`. Fedora 44 uses
`tuned-ppd` for the Power Profiles D-Bus API; do not install TLP or
power-profiles-daemon alongside it.

## XWayland does not work

XWayland starts on demand. Confirm `DISPLAY` exists after launching an X11
client, then inspect `pgrep -a Xwayland` and the Sway log.

## Locked or blank session

Type the password and press Enter. If the display stayed powered off, switch
to a TTY and run `swaymsg 'output * power on'` with the correct `SWAYSOCK`.

## Recover from a TTY

Log in, then stop only project units:

```bash
systemctl --user stop fedora-sway-session.target
./uninstall.sh
```

Backups are below `~/.local/state/fedora-sway-quickshell-demo/backups/`.
Inspect them before any manual restoration. The uninstaller will not overwrite
a path changed after installation and will not remove RPM packages.
