# Migration from the current Omarchy workstation

This project reproduces the owner's useful workflow, not Omarchy itself.

| Current capability | Fedora Sway 1.0 |
|---|---|
| Hyprland workspaces/window control | Small Sway configuration, immediate state changes |
| Omarchy shell | Repository-owned Quickshell bar, launcher, popup and OSD |
| Foot/other terminals | Alacritty |
| Omarchy idle/lock | Independent swayidle and swaylock units |
| Power profiles | Fedora TuneD with the PPD compatibility API |
| Network/Bluetooth/audio menus | NetworkManager editor, Blueman and pavucontrol |
| Nautilus/removable media | Thunar, GVfs, UDisks and archive integration |
| Docker development | Rootless Podman plus the Fedora `podman-docker` compatibility CLI |
| QEMU/virt-manager | Fedora QEMU/KVM and `qemu:///session`; no privileged group |
| mise-managed Elixir/OTP | Digest-pinned OCI toolchain exposed as `mix`, `elixir`, `iex` |
| Codex and T3 Code | Pinned Codex npm artifact and pinned upstream T3 AppImage |
| Screenshots | grim/slurp, copied to the Wayland clipboard |

Not migrated into 1.0: Omarchy effects, theme marketplace, notification
history, background rotation, global transparent-window tricks, hundreds of
menus/keybindings, automatic crash-to-AI services and host-wide Docker daemon.
They are not required for the measured MKDL workflow and would enlarge idle or
security surface.

## Data boundary

The installer never copies browser profiles, SSH keys, Git credentials,
Codex tokens, customer data or project worktrees. Move those separately with
their owning application's documented export/restore process. Test the Fedora
VM first, back up the laptop, and keep the old encrypted installation until the
manual acceptance gates pass.
