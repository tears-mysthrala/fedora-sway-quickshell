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

To keep both intervals comparable, the tool temporarily stops only the
project's swayidle unit; otherwise its five-minute lock and ten-minute output
power-off would put A and B in different render states. The prior idle and
Quickshell service states are restored on normal exit, error or interruption.

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
| RAM after login | 672620 KiB used from `/proc/meminfo`; measured after a clean boot/login, including the minimal OS and session |
| Desktop processes after login | 12; estimated by the documented process-set matcher |
| Sway RSS | A: 132084 -> 132068 KiB; B: 132240 -> 132240 KiB |
| Quickshell RSS | 179132 -> 179132 KiB; no growth over B |
| Network event listener RSS | 11372 -> 11372 KiB; no growth over B |
| Idle CPU time A/B | 600 s A: Sway 0 ticks. 600 s B: Sway 0, Quickshell 0, NetworkManager listener 0 ticks. Measured sequentially; no threshold assigned. |
| Context switches | A Sway: 0 voluntary, 0 involuntary. B Sway: 0/0; Quickshell: 10/0; NetworkManager listener: 0/0. |
| Wakeups | Unavailable unless a reliable source is found |
| GPU activity | Unavailable: this VM has no reliable accelerated GPU metric |
| Project polling | Static scan: none; one blocking `nmcli monitor` NetworkManager D-Bus listener is resident with Quickshell |
| Project timers | Clock minute boundary; one-shot notification/OSD timeouts |

The observed signed total `B-A` was 0 ticks. Sequential intervals and scheduler
tick quantization dominate at this activity level, so this is recorded but not
treated as a performance threshold. The tool reports Quickshell's directly
measured ticks separately and labels the signed total comparison as estimated.

Session-to-shell-ready time is currently `unavailable`: v1 has no trustworthy
compositor-ready marker, and service activation timestamps become misleading after a
Quickshell restart. No value is preferable to a false measurement.
