# Updates

Fedora remains responsible for system updates:

```bash
sudo dnf upgrade --refresh
./update-check.sh
```

`update-check.sh` is read-only. It reports Fedora updates and compares the
Codex/T3 upstream versions with the repository pins. It does not edit files,
install packages, restart the session or update itself.

Codex and T3 Code updates require a reviewed repository change:

1. update the version and integrity/hash in `config/project.conf`;
2. verify the upstream release and provenance;
3. run static tests;
4. install in the Fedora VM;
5. validate Codex discovery, T3 native Wayland startup and a disposable agent
   thread;
6. rerun failure isolation, portal checks and the performance snapshot;
7. commit the pin and evidence together.

The MKDL Elixir image follows Kurogane Hub's controlled CI image. Update
`config/mkdl-toolchain.conf` only with the corresponding repository toolchain
change and validate a clean Mix project plus Kurogane's own suite.

T3 Code's built-in updater is deliberately disabled by the launcher. The
desktop application would otherwise check its update feed every four minutes;
that adds avoidable wakeups and can bypass the version and SHA-256 pin in
`config/project.conf`. Use `./update-check.sh`, review the upstream release,
change both pin values, and rerun `./install.sh` instead.
The setting is upstream's
[`T3CODE_DISABLE_AUTO_UPDATE`](https://github.com/pingdotgg/t3code/blob/v0.0.42/apps/desktop/src/app/DesktopConfig.ts),
not a binary patch.
