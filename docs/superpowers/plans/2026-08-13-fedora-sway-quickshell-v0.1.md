# Fedora Sway + Quickshell Demo v0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert a clean Fedora Server 44 VM into a minimal, event-driven Sway workstation with a non-critical Quickshell visual shell.

**Architecture:** Fedora owns the base system and RPM services; repository-managed user configuration supplies Sway, independent lock/idle/polkit processes, Quickshell, portals, diagnostics, and measurement tooling. Shell scripts share one constants/library layer, while QML consumes native event sources and contains no animation or recurring subprocess polling.

**Tech Stack:** Bash, systemd user units, Sway configuration, QML/Quickshell 0.2.1, QEMU/KVM, Fedora RPM packages.

**Spec:** `docs/superpowers/specs/2026-08-13-fedora-sway-quickshell-v0.1-design.md`

## Global Constraints

- Fedora Server 44 only; define `SUPPORTED_FEDORA_RELEASE=44` once.
- Official Fedora repositories only for project-managed packages; unrelated enabled repositories are allowed.
- SELinux enforcing and firewalld active; never weaken either.
- No external package repositories, animation primitives, or avoidable polling.
- Quickshell must remain non-critical to Sway, swayidle, swaylock, polkit, and terminal access.
- `install.sh` is idempotent and preserves conflicting user data with backups.
- Runtime acceptance evidence comes from a disposable Fedora 44 QEMU/KVM VM.

---

### Task 1: Package contract and shared shell interfaces

**Files:**
- Create: `config/project.conf`
- Create: `packages/base.txt`
- Create: `packages/desktop.txt`
- Create: `packages/optional.txt`
- Create: `scripts/lib/common.sh`
- Create: `tests/static/test-package-contract.sh`

**Interfaces:**
- Produces: `SUPPORTED_FEDORA_RELEASE`, `PROJECT_ID`, `PROJECT_STATE_DIR`, `load_packages()`, `is_allowed_repo()`.

- [ ] Write `test-package-contract.sh` to require one release definition, unique valid package names, only the declared Sway stack, and required Sway packages.
- [ ] Run `bash tests/static/test-package-contract.sh` and confirm it fails because the contract files do not exist.
- [ ] Add the constants, package manifests, and common functions; retain `jq` only if a later implementation consumes it.
- [ ] Re-run the test and `bash -n scripts/lib/common.sh`; expect success.
- [ ] Commit with `git commit -m "feat: define Fedora package contract"`.

### Task 2: Idempotent installer and managed state

**Files:**
- Create: `install.sh`
- Create: `uninstall.sh`
- Create: `scripts/lib/install-state.sh`
- Create: `tests/static/test-install-state.sh`
- Create: `tests/fixtures/bin/dnf`
- Create: `tests/fixtures/bin/systemctl`

**Interfaces:**
- Consumes: Task 1 constants and manifests.
- Produces: `ensure_managed_link SOURCE DEST`, package-origin preflight, managed state manifest, `--check`, and `--dry-run`.

- [ ] Write tests using a temporary HOME to prove conflicting paths are backed up once, repeated linking converges, third-party repositories alone are accepted, and a project package selected from an unauthorized repo fails.
- [ ] Run the installer tests and confirm expected missing-function failures.
- [ ] Implement preflight-before-mutation, DNF repo-origin validation, package recording, safe links, and conservative uninstall restoration.
- [ ] Run tests twice, ShellCheck when installed, and `bash -n` on every shell file.
- [ ] Commit with `git commit -m "feat: add safe idempotent installer"`.

### Task 3: Minimal Sway session and independent security processes

**Files:**
- Create: `config/sway/config`
- Create: `config/swayidle/config`
- Create: `config/swaylock/config`
- Create: `config/environment.d/10-fedora-sway-demo.conf`
- Create: `config/systemd/user/fedora-sway-session.target`
- Create: `config/systemd/user/fedora-sway-quickshell.service`
- Create: `config/systemd/user/fedora-sway-idle.service`
- Create: `config/systemd/user/fedora-sway-polkit.service`
- Create: `scripts/volume.sh`
- Create: `scripts/brightness.sh`
- Create: `scripts/screenshot.sh`
- Create: `tests/static/test-session-config.sh`

**Interfaces:**
- Produces: Sway keybindings and independent systemd user service lifecycle.

- [ ] Write static assertions for required keybindings, disabled swaybar, independent units, lock-before-sleep, bounded helper scripts, and absence of loops.
- [ ] Run the test and observe failure for missing configuration.
- [ ] Implement the smallest configs and one-action helper scripts.
- [ ] Run static tests, shell syntax checks, and `systemd-analyze --user verify` when the host supports it.
- [ ] Commit with `git commit -m "feat: add minimal independent Sway session"`.

### Task 4: Event-driven Quickshell shell

**Files:**
- Create: `config/quickshell/shell.qml`
- Create: `config/quickshell/components/Bar.qml`
- Create: `config/quickshell/components/WorkspaceList.qml`
- Create: `config/quickshell/components/Launcher.qml`
- Create: `config/quickshell/components/AudioStatus.qml`
- Create: `config/quickshell/components/NetworkStatus.qml`
- Create: `config/quickshell/components/BatteryStatus.qml`
- Create: `config/quickshell/components/Clock.qml`
- Create: `config/quickshell/components/Osd.qml`
- Create: `config/quickshell/components/Notifications.qml`
- Create: `tests/static/test-quickshell.sh`

**Interfaces:**
- Consumes: Sway/I3 IPC, PipeWire, UPower, NetworkManager events, desktop entries, notification D-Bus protocol.
- Produces: `qs ipc call launcher toggle`, `qs ipc call shell restart`, immediate bar/launcher/OSD/popups.

- [ ] Write a failing scan for required modules/components and forbidden animation classes, polling loops, repeated subprocess timers, history, and persistence.
- [ ] Implement reusable QML components with event sources, a minute-aligned clock timer, and one-shot popup/OSD timers.
- [ ] Run static tests and `qmllint` against the Fedora package in the VM when available.
- [ ] Commit with `git commit -m "feat: add event-driven Quickshell shell"`.

### Task 5: Portal and diagnostics implementation

**Files:**
- Create: `doctor.sh`
- Create: `scripts/check-portals.sh`
- Create: `tests/static/test-doctor.sh`
- Create: `tests/vm/test-portals.sh`

**Interfaces:**
- Produces: `[OK]`, `[INFO]`, `[WARN]`, `[FAIL]` diagnostic lines based on functional evidence.

- [ ] Write tests ensuring binary presence alone cannot produce runtime `[OK]` and portal checks inspect user units plus D-Bus.
- [ ] Implement Fedora, Wayland, Sway IPC, Quickshell IPC, XWayland, PipeWire, WirePlumber, polkit, idle, lock, NetworkManager, UPower, and portal checks.
- [ ] Add VM portal probes for file chooser, URI opening, screenshot, screencast, and PipeWire node evidence.
- [ ] Run static tests and shell validation.
- [ ] Commit with `git commit -m "feat: add functional desktop doctor"`.

### Task 6: Failure isolation acceptance test

**Files:**
- Create: `tests/vm/test-quickshell-isolation.sh`
- Create: `docs/TROUBLESHOOTING.md`

**Interfaces:**
- Consumes: installed logged-in Sway session.
- Produces: timestamped evidence showing required processes and IPC before, during, and after Quickshell termination.

- [ ] Write the acceptance script to open two test applications, capture Sway tree/process state, terminate only Quickshell, exercise Sway IPC/lock availability, restart Quickshell, and capture final evidence.
- [ ] Validate script syntax and safe process targeting.
- [ ] Document TTY recovery and every required troubleshooting case.
- [ ] Run the script in the Fedora VM and retain observed output.
- [ ] Commit with `git commit -m "test: verify Quickshell failure isolation"`.

### Task 7: Controlled performance baseline

**Files:**
- Create: `benchmark.sh`
- Create: `scripts/lib/metrics.sh`
- Create: `tests/static/test-benchmark.sh`
- Create: `docs/PERFORMANCE.md`

**Interfaces:**
- Produces: labeled snapshots and A/B interval reports; default duration 600 seconds with an explicit test-only override.

- [ ] Write tests for measured/estimated/unavailable labels, procfs CPU/RSS/context-switch deltas, process-set changes, project timer/listener inventory, and A/B arithmetic.
- [ ] Implement on-demand snapshot/interval/A/B modes without a resident daemon or invented thresholds.
- [ ] Run tests with a short interval override and validate report structure.
- [ ] Run matched ten-minute A and B measurements in the stabilized VM and record the first baseline.
- [ ] Commit with `git commit -m "feat: measure incremental Quickshell cost"`.

### Task 8: QEMU/KVM Fedora 44 acceptance harness

**Files:**
- Create: `scripts/vm/create.sh`
- Create: `scripts/vm/run.sh`
- Create: `scripts/vm/README.md`
- Create: `tests/vm/acceptance.sh`
- Create: `.gitignore`

**Interfaces:**
- Produces: a uniquely named disposable VM and an evidence directory ignored by Git.

- [ ] Write dry-run tests that reject existing disk/VM targets and require an explicitly provided Fedora 44 ISO checksum.
- [ ] Implement non-destructive VM creation separate from installation, with KVM, SPICE display, virtio devices, and no embedded credentials.
- [ ] Verify harness dry-run and shell syntax.
- [ ] Download Fedora only from an official Fedora URL, verify its published checksum, create the VM, and install Fedora Server 44.
- [ ] Run full acceptance twice for installer idempotency and retain evidence.
- [ ] Commit with `git commit -m "test: add Fedora 44 VM acceptance harness"`.

### Task 9: User documentation and release verification

**Files:**
- Create: `README.md`
- Create: `docs/ARCHITECTURE.md`
- Create: `docs/DEPENDENCIES.md`
- Create: `tests/static/run.sh`
- Modify: all prior files only for verified defects.

**Interfaces:**
- Produces: complete operator documentation and one static test entry point.

- [ ] Write documentation checks for install commands, session startup, package rationale, boundaries, security, recovery, and performance procedure.
- [ ] Write the README and focused architecture/dependency documents; document `jq` only if code actually uses it.
- [ ] Run all static tests, forbidden-pattern scans, shell syntax, `git diff --check`, and VM acceptance.
- [ ] Apply the verification-loop and record which claims are host-static versus VM-observed.
- [ ] Commit with `git commit -m "docs: complete Fedora Sway demo v0.1"`.
