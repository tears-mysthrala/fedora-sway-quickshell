#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$ROOT/scripts/lib/metrics.sh"
duration=${METRIC_INTERVAL_SECONDS:-600}
stabilize=${METRIC_STABILIZE_SECONDS:-30}

snapshot_process() {
  local label=$1 pid=$2 phase=$3 cpu rss voluntary involuntary
  cpu=$(proc_cpu_ticks "$pid"); rss=$(proc_rss_kib "$pid")
  read -r voluntary involuntary < <(proc_context_switches "$pid")
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$label" "$pid" "$phase" "$cpu" "$rss" "$voluntary" "$involuntary"
}

run_interval() {
  local label=$1 pid=$2 start end
  [[ -r /proc/$pid/stat ]] || { printf 'process unavailable: %s\n' "$pid" >&2; return 1; }
  start=$(snapshot_process "$label" "$pid" T0)
  sleep "$duration"
  [[ -r /proc/$pid/stat ]] || { printf 'process ended during interval: %s\n' "$pid" >&2; return 1; }
  end=$(snapshot_process "$label" "$pid" T_END)
  emit_delta "$label" "$duration" "$start" "$end"
}

emit_delta() {
  local label=$1 seconds=$2 start=$3 end=$4
  local _ spid _ scpu srss sv si _ epid _ ecpu erss ev ei
  IFS=$'\t' read -r _ spid _ scpu srss sv si <<<"$start"
  IFS=$'\t' read -r _ epid _ ecpu erss ev ei <<<"$end"
  printf 'classification\tmeasured\n'
  printf 'label\t%s\ninterval_seconds\t%s\npid\t%s\n' "$label" "$seconds" "$spid"
  printf 'metric\tcpu_ticks_delta\t%s\n' "$((ecpu - scpu))"
  printf 'metric\trss_initial_kib\t%s\nmetric\trss_final_kib\t%s\nmetric\trss_delta_kib\t%s\n' "$srss" "$erss" "$((erss - srss))"
  printf 'metric\tvoluntary_context_switches_delta\t%s\nmetric\tinvoluntary_context_switches_delta\t%s\n' "$((ev - sv))" "$((ei - si))"
  printf 'wakeups\tunavailable\tno reliable generic non-invasive source\n'
  printf 'gpu_idle\tunavailable\thardware-specific collector not selected\n'
  printf 'project_timers\testimated\tclock minute boundary and one-shot UI expiry timers\n'
  printf 'event_listeners\tmeasured\tSway IPC, PipeWire, NetworkManager, UPower, notifications\n'
}

run_pair_interval() {
  local label_one=$1 pid_one=$2 label_two=$3 pid_two=$4 start_one start_two end_one end_two
  start_one=$(snapshot_process "$label_one" "$pid_one" T0)
  start_two=$(snapshot_process "$label_two" "$pid_two" T0)
  sleep "$duration"
  end_one=$(snapshot_process "$label_one" "$pid_one" T_END)
  end_two=$(snapshot_process "$label_two" "$pid_two" T_END)
  emit_delta "$label_one" "$duration" "$start_one" "$end_one"
  emit_delta "$label_two" "$duration" "$start_two" "$end_two"
}

run_ab() {
  command -v systemctl >/dev/null
  local processes_a processes_b
  printf 'A: stopping Quickshell; stabilizing for %ss\n' "$stabilize"
  systemctl --user stop fedora-sway-quickshell.service
  sleep "$stabilize"
  processes_a=$(desktop_processes)
  local sway_pid report_a report_b a_cpu b_sway_cpu b_qs_cpu
  sway_pid=$(pgrep -xo sway)
  report_a=$(run_interval A_sway_only "$sway_pid")
  printf '%s\n' "$report_a"
  printf 'B: starting Quickshell; stabilizing for %ss\n' "$stabilize"
  systemctl --user start fedora-sway-quickshell.service
  sleep "$stabilize"
  processes_b=$(desktop_processes)
  sway_pid=$(pgrep -xo sway)
  local quickshell_pid
  quickshell_pid=$(systemctl --user show -p MainPID --value fedora-sway-quickshell.service)
  [[ $quickshell_pid =~ ^[1-9][0-9]*$ ]] || { printf 'Quickshell service has no live MainPID\n' >&2; return 1; }
  report_b=$(run_pair_interval B_sway "$sway_pid" B_quickshell "$quickshell_pid")
  printf '%s\n' "$report_b"
  a_cpu=$(awk -F '\t' '$2=="cpu_ticks_delta" {print $3; exit}' <<<"$report_a")
  b_sway_cpu=$(awk -F '\t' '$2=="cpu_ticks_delta" {print $3; exit}' <<<"$report_b")
  b_qs_cpu=$(awk -F '\t' '$2=="cpu_ticks_delta" {n++; if (n==2) {print $3; exit}}' <<<"$report_b")
  printf 'comparison\tmeasured\tquickshell_cpu_ticks\t%s\n' "$b_qs_cpu"
  printf 'comparison\testimated\ttotal_cpu_ticks_B_minus_A\t%s\tsequential intervals; scheduler quantization may dominate\n' "$((b_sway_cpu + b_qs_cpu - a_cpu))"
  printf 'process_set_A\tmeasured\t%s\n' "$(tr '\n' ';' <<<"$processes_a")"
  printf 'process_set_B\tmeasured\t%s\n' "$(tr '\n' ';' <<<"$processes_b")"
  printf 'process_set_change\tmeasured\t'
  diff --new-line-format='+ %L' --old-line-format='- %L' --unchanged-line-format='' \
    <(printf '%s\n' "$processes_a") <(printf '%s\n' "$processes_b") || true
}

session_startup_metric() {
  printf 'session_to_shell_ready_ms\tunavailable\tno compositor-ready marker in v0.1; service restarts make unit timestamps misleading\n'
}

case ${1:-snapshot} in
  snapshot)
    printf 'classification\tmeasured\n'
    memory_snapshot
    processes=$(desktop_processes)
    printf 'desktop_process_count\testimated\t%s\n' "$(grep -c . <<<"$processes")"
    printf '%s\n' "$processes"
    session_startup_metric
    ;;
  interval) run_interval "${2:-process}" "${3:-$(pgrep -xo "${2:-sway}")}" ;;
  ab) run_ab ;;
  *) printf 'Usage: %s {snapshot|interval [label] [pid]|ab}\n' "$0" >&2; exit 2 ;;
esac
