# Fedora 44 acceptance VM

The harness owns only `.vm/fedora-sway-demo-f44.qcow2` and the libvirt domain
`fedora-sway-demo-f44`. It refuses to overwrite either. A generated kickstart
automates only the disposable `demo` account and keeps its random password in
the ignored `.vm/demo-password` file. It uses the unprivileged
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

The baseline VM uses an unaccelerated virtio display, so Mesa/Qt may fall back
to software rendering and emit non-fatal EGL/VA-API warnings. No software
renderer override is installed on the laptop configuration. Fedora Firefox's
hardware WebRender path and Electron GPU clients can corrupt this VM's scanout
into a solid red frame. For browser screen-share acceptance only, use a
disposable Firefox profile
containing:

```javascript
user_pref("gfx.webrender.software", true);
```

Restart the graphical VM session after a red frame. This workaround must not
be copied into the normal Sway environment without first reproducing the
driver issue on the target hardware.
