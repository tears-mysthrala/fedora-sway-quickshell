#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)

source "$ROOT/config/project.conf"
[[ ${PROJECT_VERSION:-} == 1.1.0 ]]
[[ ${T3_CODE_VERSION:-} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ ${T3_CODE_SHA256:-} =~ ^[a-f0-9]{64}$ ]]
[[ ${ZEN_VERSION:-} =~ ^[0-9]+\.[0-9]+\.[0-9]+b$ ]]
[[ ${ZEN_SHA256:-} =~ ^[a-f0-9]{64}$ ]]

packages=$(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$ROOT"/packages/*.txt)
for required in greetd greetd-selinux gtkgreet gnome-keyring gvfs udisks2 \
  nm-connection-editor blueman bluez tuned-ppd fwupd fuse jetbrains-mono-fonts \
  cascadia-mono-nf-fonts cliphist swappy wtype qt6ct dnf5-plugin-automatic smartmontools \
  cockpit cockpit-machines cockpit-podman cockpit-storaged \
  gh openssh-clients podman-docker qemu-kvm virt-manager wireguard-tools; do
  grep -qx "$required" <<<"$packages"
done

grep -Fq 'xkb_layout es' "$ROOT/config/sway/config"
grep -Fq 'xkb_options compose:caps' "$ROOT/config/sway/config"
grep -Fq 'tap enabled' "$ROOT/config/sway/config"
grep -Fq 'LIBVIRT_DEFAULT_URI=qemu:///session' "$ROOT/config/environment.d/10-fedora-sway-demo.conf"
grep -Fq 'bindsym $mod+b exec zen' "$ROOT/config/sway/config"
grep -Fq 'bindsym $mod+e exec thunar' "$ROOT/config/sway/config"
grep -Fq 'bindsym $mod+w kill' "$ROOT/config/sway/config"
grep -Fq 'export T3CODE_DISABLE_AUTO_UPDATE=true' "$ROOT/scripts/t3code.sh"

[[ -f $ROOT/config/greetd/config.toml ]]
grep -Fq 'raiju-sway.conf' "$ROOT/config/greetd/config.toml"
grep -Fq 'gtkgreet' "$ROOT/config/greetd/raiju-sway.conf"
[[ -f $ROOT/config/niri/config.kdl ]]
[[ -f $ROOT/config/xdg-desktop-portal/niri-portals.conf ]]
grep -Fq 'ScreenCast=gnome' "$ROOT/config/xdg-desktop-portal/niri-portals.conf"
grep -Fq 'config/niri' "$ROOT/install.sh"
grep -Fq 'niri-portals.conf' "$ROOT/install.sh"
grep -Fq 'niri' "$ROOT/docs/DEPENDENCIES.md"
[[ -f $ROOT/config/sway/config-columns ]]
[[ -x $ROOT/config/system/fedora-sway-columns ]]
grep -Fq 'sway --config' "$ROOT/config/system/fedora-sway-columns"
[[ -f $ROOT/config/system/fedora-sway-columns.desktop ]]
grep -Fq 'DesktopNames=sway' "$ROOT/config/system/fedora-sway-columns.desktop"
[[ -f $ROOT/assets/backgrounds/raiju/raiju_guardian_under_crimson_lightning.png ]]
[[ -f $ROOT/config/applications/t3code.desktop ]]
[[ -x $ROOT/scripts/install-t3code.sh ]]
[[ -x $ROOT/scripts/install-zen.sh ]]
[[ -x $ROOT/scripts/t3code.sh ]]
grep -Fq 'sha256sum --check' "$ROOT/scripts/install-t3code.sh"
if grep -Fq -- '--no-sandbox' "$ROOT/scripts/t3code.sh"; then exit 1; fi
grep -Fq 'XDG_DATA_HOME=' "$ROOT/scripts/t3code.sh"
grep -Fq 'T3CODE_DISABLE_AUTO_UPDATE=true' "$ROOT/scripts/t3code.sh"

grep -Fq 'org.freedesktop.secrets' "$ROOT/doctor.sh"
[[ -x $ROOT/scripts/system-setup.sh ]]
grep -Fq 'greetd.service' "$ROOT/scripts/system-setup.sh"
grep -Fq 'bluetooth.service' "$ROOT/scripts/system-setup.sh"
grep -Fq 'tuned.service' "$ROOT/scripts/system-setup.sh"
grep -Fq -- '--network=host' "$ROOT/scripts/mkdl-elixir.sh"
grep -Fq 'for beam_command in mix elixir iex' "$ROOT/install.sh"
grep -Fq 'org.freedesktop.impl.portal.ScreenCast=wlr' "$ROOT/config/xdg-desktop-portal/sway-portals.conf"
grep -Fq 'default=gtk' "$ROOT/config/xdg-desktop-portal/sway-portals.conf"

[[ -f $ROOT/docs/ACCEPTANCE.md ]]
[[ -f $ROOT/docs/MIGRATION.md ]]
[[ -f $ROOT/docs/UPDATES.md ]]
[[ -x $ROOT/tests/vm/test-t3code.sh ]]
[[ -x $ROOT/tests/vm/test-mkdl-toolchain.sh ]]
[[ -x $ROOT/tests/vm/test-xwayland.sh ]]
grep -Fq 'test-t3code.sh' "$ROOT/tests/vm/acceptance.sh"
grep -Fq 'test-mkdl-toolchain.sh' "$ROOT/tests/vm/acceptance.sh"
grep -Fq 'test-xwayland.sh' "$ROOT/tests/vm/acceptance.sh"
echo 'v1 contract: PASS'
