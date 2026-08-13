#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
source "$ROOT/scripts/lib/metrics.sh"

ticks=$(proc_cpu_ticks $$)
[[ $ticks =~ ^[0-9]+$ ]]
rss=$(proc_rss_kib $$)
[[ $rss =~ ^[0-9]+$ ]]
read -r voluntary involuntary < <(proc_context_switches $$)
[[ $voluntary =~ ^[0-9]+$ && $involuntary =~ ^[0-9]+$ ]]

report=$(METRIC_INTERVAL_SECONDS=1 "$ROOT/benchmark.sh" interval self $$)
grep -Fq $'classification\tmeasured' <<<"$report"
grep -Fq $'metric\tcpu_ticks_delta' <<<"$report"
grep -Fq $'metric\trss_delta_kib' <<<"$report"
grep -Fq $'wakeups\tunavailable' <<<"$report"
grep -Fq 'session_to_shell_ready_ms' "$ROOT/benchmark.sh"
grep -Fq 'process_set_change' "$ROOT/benchmark.sh"
grep -Fq 'quickshell_cpu_ticks' "$ROOT/benchmark.sh"
grep -Fq 'scheduler quantization may dominate' "$ROOT/benchmark.sh"
grep -Fq 'systemctl --user show -p MainPID --value fedora-sway-quickshell.service' "$ROOT/benchmark.sh"
grep -Fq 'memory_used_kib' "$ROOT/scripts/lib/metrics.sh"
grep -Fq 'desktop_process_count' "$ROOT/benchmark.sh"
echo 'benchmark contract: PASS'
