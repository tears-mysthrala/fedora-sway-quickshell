#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
QML="$ROOT/config/quickshell"

! grep -Rqs 'DropExpensiveFonts' "$QML"

for component in Bar WorkspaceList Launcher AudioStatus NetworkStatus BatteryStatus Clock Osd Notifications; do
  [[ -f $QML/components/$component.qml ]]
done
grep -Fq 'import Quickshell.I3' "$QML/components/WorkspaceList.qml"
grep -Fq 'import Quickshell.Services.Pipewire' "$QML/components/AudioStatus.qml"
grep -Fq 'import Quickshell.Networking' "$QML/components/NetworkStatus.qml"
grep -Fq 'import Quickshell.Services.UPower' "$QML/components/BatteryStatus.qml"
grep -Fq 'NotificationServer' "$QML/components/Notifications.qml"
grep -Fq 'IpcHandler' "$QML/components/Launcher.qml"
grep -Fq 'signal launcherRequested()' "$QML/components/Bar.qml"
grep -Fq 'onLauncherRequested: launcher.toggle()' "$QML/shell.qml"
grep -Fq 'env -u WAYLAND_DISPLAY qs ipc' "$ROOT/scripts/qs-ipc.sh"

! grep -RniE '\b(Behavior|NumberAnimation|PropertyAnimation|SpringAnimation|SequentialAnimation|ParallelAnimation)\b' "$QML"
! grep -RniE 'while[[:space:]]*\(|while[[:space:]]+true|interval:[[:space:]]*(100|[1-9][0-9]?[[:space:]]*$)' "$QML"
! grep -RniE 'history|database|sqlite|JsonAdapter|PersistentProperties' "$QML"

echo 'quickshell policy: PASS'
