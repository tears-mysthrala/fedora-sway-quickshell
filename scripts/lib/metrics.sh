#!/usr/bin/env bash

proc_cpu_ticks() {
  local stat rest
  stat=$(<"/proc/$1/stat")
  rest=${stat##*) }
  set -- $rest
  printf '%s\n' $(( ${12} + ${13} ))
}

proc_rss_kib() {
  awk '/^VmRSS:/ {print $2; found=1} END {if (!found) print 0}' "/proc/$1/status"
}

proc_context_switches() {
  awk '
    /^voluntary_ctxt_switches:/ {v=$2}
    /^nonvoluntary_ctxt_switches:/ {n=$2}
    END {printf "%d %d\n", v, n}
  ' "/proc/$1/status"
}

desktop_processes() {
  ps -u "$(id -u)" -o pid=,comm= | awk '$2 ~ /^(sway|swayidle|swaylock|qs|nmcli|Xwayland|wireplumber|pipewire|lxqt-policykit-|xdg-desktop-)/'
}

memory_snapshot() {
  awk '
    /^MemTotal:/ {total=$2}
    /^MemAvailable:/ {available=$2}
    END {
      printf "memory_total_kib\tmeasured\t%d\n", total
      printf "memory_used_kib\tmeasured\t%d\n", total-available
    }
  ' /proc/meminfo
}
