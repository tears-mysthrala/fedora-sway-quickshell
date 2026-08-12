#!/usr/bin/env bash
set -euo pipefail

busctl --user status org.freedesktop.portal.Desktop >/dev/null
busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.FileChooser >/dev/null
busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.OpenURI >/dev/null
busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.Screenshot >/dev/null
busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.ScreenCast >/dev/null
systemctl --user is-active --quiet xdg-desktop-portal.service
systemctl --user is-active --quiet xdg-desktop-portal-wlr.service
systemctl --user is-active --quiet xdg-desktop-portal-gtk.service
printf 'Portal interfaces and backends are active. Interactive chooser/share tests remain required.\n'

