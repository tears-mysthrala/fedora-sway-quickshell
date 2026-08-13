#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
QML="$ROOT/config/quickshell"

if grep -Rqs 'DropExpensiveFonts' "$QML"; then exit 1; fi

for component in Bar WorkspaceList Launcher AudioStatus NetworkStatus BatteryStatus Clock Osd Notifications \
  Clipboard MediaStatus MicrophoneStatus PrivacyStatus QuickSettings SystemSettings SystemTrayStatus UtilitiesStatus; do
  [[ -f $QML/components/$component.qml ]]
done
grep -Fq 'import Quickshell.I3' "$QML/components/WorkspaceList.qml"
grep -Fq 'import Quickshell.Services.Pipewire' "$QML/components/AudioStatus.qml"
grep -Fq 'command: ["nmcli", "monitor"]' "$QML/components/NetworkStatus.qml"
grep -Fq 'stdout: SplitParser' "$QML/components/NetworkStatus.qml"
if grep -Eq 'Timer|sleep|while[[:space:]]*\(' "$QML/components/NetworkStatus.qml"; then
  echo 'network widget must remain event driven' >&2
  exit 1
fi
grep -Fq 'import Quickshell.Services.UPower' "$QML/components/BatteryStatus.qml"
grep -Fq 'NotificationServer' "$QML/components/Notifications.qml"
if grep -Fq 'expireTimeout * 1000' "$QML/components/Notifications.qml"; then
  echo 'notification protocol timeout is already in milliseconds' >&2
  exit 1
fi
grep -Fq 'IpcHandler' "$QML/components/Launcher.qml"
grep -Fq 'signal launcherRequested()' "$QML/components/Bar.qml"
grep -Fq 'onLauncherRequested: launcher.toggle()' "$QML/shell.qml"
grep -Fq 'onQuickSettingsRequested: section => quickSettings.toggle(section)' "$QML/shell.qml"
grep -Fq 'onSystemSettingsRequested: systemSettings.toggle()' "$QML/shell.qml"
grep -Fq 'qs ipc --any-display' "$ROOT/scripts/qs-ipc.sh"

# Short transitions are intentional; continuous or long-running animations are not.
if grep -RniE 'loops:[[:space:]]*Animation\.Infinite|duration:[[:space:]]*([5-9][0-9]{2}|[1-9][0-9]{3,})' "$QML"; then exit 1; fi
if grep -RniE 'while[[:space:]]*\(|while[[:space:]]+true|interval:[[:space:]]*(100|[1-9][0-9]?[[:space:]]*$)' "$QML"; then exit 1; fi
grep -Fq 'command: ["cliphist", "list"]' "$QML/components/Clipboard.qml"

echo 'quickshell policy: PASS'
