# pillarius-desktop (metapackage)

Installable packaging for the **Pillarius desktop environment**. This is a
[metapackage](https://wiki.debian.org/Metapackages): it ships no binaries,
only dependencies, so the whole environment installs with one command.

```
sudo apt install pillarius-desktop
```

## Contents

| Relationship | Package | Purpose |
| --- | --- | --- |
| Depends | `pillarium` | lightweight X11 window manager (desktop shell) |
| Depends | `spacer-greeter` | LightDM greeter |
| Depends | `cadet` | companion toolkit / applications |
| Depends | `rocky` | office suite (RockyWrite, RockyWrite+, RockyGraphite, RockyGraphite+, RockySheet, RockyPresent) |
| Recommends | `planet` | graphical package manager |
| Recommends | `planet-control-center` | settings application |

## Build

```sh
./build_deb.sh
```

Writes `pillarius-desktop_1.1.0-1_all.deb` to the repository root
(`../..`, i.e. `pt-apt-repo/`). Publish it with the repo tooling:

```sh
cd ../..
./publish.sh pillarius-desktop_1.1.0-1_all.deb
```

Requires `dpkg-deb`. `debian/control`, `debian/changelog` and
`debian/copyright` mirror the metadata baked into `build_deb.sh` for
reference; keep them in sync when bumping the version.
