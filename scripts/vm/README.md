# Fedora 44 acceptance VM

The harness owns only `.vm/fedora-sway-demo-f44.qcow2` and the libvirt domain
`fedora-sway-demo-f44`. It refuses to overwrite either. It does not embed a
password or automate account creation.

```bash
./scripts/vm/fetch-media.sh
./scripts/vm/create.sh
./scripts/vm/run.sh
```

Install Fedora Server normally in the graphical console. After first boot,
copy or clone this repository into the VM and run `./install.sh` as the target
desktop user.

