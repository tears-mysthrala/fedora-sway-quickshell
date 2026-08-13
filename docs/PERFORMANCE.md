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
| Hardware | QEMU/KVM, 2 vCPU, 2896040 KiB RAM, virtio-gpu, 1280x800; Pixman/Qt software rendering because the acceptance VM has no 3D acceleration |
| Fedora | 44 |
| Sway | 1.11-3.fc44 |
| Quickshell | 0.2.1 git snapshot dacfa9d, Fedora package |
| RAM after login | 610928 KiB used from `/proc/meminfo`; measured, including the minimal OS and session |
| Sway RSS | A: 23692 -> 27796 KiB; B: 27796 -> 27796 KiB |
| Quickshell RSS | 76288 -> 76292 KiB; +4 KiB over B |
| Idle CPU time A/B | 600 s A: Sway 2 ticks. 600 s B: Sway 0 ticks, Quickshell 1 tick. Measured sequentially; no threshold assigned. |
| Context switches | A Sway: 16 voluntary, 0 involuntary. B Sway: 0/0; Quickshell: 11/1. |
| Wakeups | Unavailable unless a reliable source is found |
| GPU activity | Unavailable: this VM has no reliable accelerated GPU metric |
| Project polling | Static scan: none |
| Project timers | Clock minute boundary; one-shot notification/OSD timeouts |

The first report's signed total `B-A` was -1 tick because sequential intervals
and scheduler tick quantization dominate at this activity level. It is retained
as raw evidence but is not interpreted as a negative cost. The corrected tool
reports Quickshell's directly measured ticks separately and labels the signed
total comparison as estimated.

Session-to-shell-ready time is currently `unavailable`: v0.1 has no compositor
ready marker, and service activation timestamps become misleading after a
Quickshell restart. No value is preferable to a false measurement.
