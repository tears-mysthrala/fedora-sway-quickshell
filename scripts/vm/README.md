# Fedora 44 acceptance VM

The harness owns only `.vm/fedora-sway-demo-f44.qcow2` and the libvirt domain
`fedora-sway-demo-f44`. It refuses to overwrite either. It does not embed a
password or automate account creation. It uses the unprivileged
`qemu:///session` connection and user-mode networking, so it does not create a
host bridge or change host firewall configuration.

```bash
./scripts/vm/fetch-media.sh
./scripts/vm/prepare-kickstart.sh
./scripts/vm/create.sh
./scripts/vm/run.sh
```

The generated kickstart creates the unprivileged `demo` account with a random
password and dedicated SSH key stored only in ignored `.vm/` files. It keeps
SELinux enforcing and firewalld enabled. After first boot, copy this repository
into the VM and run `./install.sh` as that desktop user.

The baseline VM uses an unaccelerated virtio display. For visual acceptance,
start Sway with `WLR_RENDERER=pixman` and Quickshell with
`QT_QUICK_BACKEND=software`; these are harness-only settings and are not part of
the installed laptop configuration.
