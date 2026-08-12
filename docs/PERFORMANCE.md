# Performance baseline

No target or pass/fail threshold exists before measurement. Every result must
be labeled `measured`, `estimated`, or `unavailable`.

## Procedure

Use an otherwise idle logged-in Sway session on AC power first, then repeat on
battery if useful. Close workload applications and record hardware and VM
details. Run:

```bash
./benchmark.sh snapshot
./benchmark.sh ab | tee .evidence/performance-ab.tsv
```

The A/B command stabilizes and measures:

1. Sway without Quickshell for ten minutes;
2. Sway and Quickshell together for ten minutes.

It records CPU ticks, initial/final RSS, RSS delta, voluntary and involuntary
context-switch deltas, project timers and event listeners. Generic wakeups and
GPU idle utilization remain unavailable unless a reliable, non-invasive,
hardware-specific source is detected. The script runs only on demand and
installs no daemon.

## First baseline

| Field | Value |
|---|---|
| Hardware | Pending Fedora 44 VM run |
| Fedora | 44 |
| Sway | Pending |
| Quickshell | Pending |
| Idle RAM | Pending |
| Sway RSS | Pending |
| Quickshell RSS | Pending |
| Idle CPU time A/B | Pending |
| Context switches | Pending |
| Wakeups | Unavailable unless a reliable source is found |
| GPU activity | Unavailable unless a reliable source is found |
| Project polling | Static scan: none |
| Project timers | Clock minute boundary; one-shot notification/OSD timeouts |

These pending fields are not acceptance evidence. They must be replaced by
observed VM output before v0.1 is called runtime-verified.

