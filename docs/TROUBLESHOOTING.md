# Troubleshooting

Start with `./doctor.sh` and the current boot's user journal:

```bash
journalctl --user -b --no-pager
```

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

## Audio is broken

Check `systemctl --user status pipewire wireplumber` and `wpctl status`. Do not
replace Fedora's audio stack or launch a second PipeWire instance.

## Polkit prompt does not appear

Check the system `polkit.service` and user `fedora-sway-polkit.service`. Ensure
only one graphical authentication agent owns the session role.

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
