# goonbox-overlay

[![pkgcheck](https://github.com/polskiftw/goonbox-overlay/actions/workflows/pkgcheck.yml/badge.svg)](https://github.com/polskiftw/goonbox-overlay/actions/workflows/pkgcheck.yml)

A personal Gentoo Portage repository for source-built packages, local packaging fixes, and software that is not available in `::gentoo` in the form wanted on goonbox.

This is an unofficial overlay. Packages are maintained independently from the Gentoo project and their upstream projects.

## Add the repository

Create `/etc/portage/repos.conf/goonbox-overlay.conf` as root:

```ini
[goonbox-overlay]
location = /var/db/repos/goonbox-overlay
sync-type = git
sync-uri = https://github.com/polskiftw/goonbox-overlay.git
auto-sync = yes
```

Then sync normally:

```sh
emerge --sync
```

Packages from this repository will appear as `::goonbox-overlay`.

## Packages

| Package | Description |
| --- | --- |
| `games-action/ship-of-harkinian` | Native Linux source build of Ship of Harkinian |
| `media-video/stremio` | Native Stremio Linux shell with a Portage-managed pinned Web UI, system GTK/WebKitGTK, libmpv, and Node.js |
| `app-emulation/86Box-9999` | Live upstream 86Box emulator with Gentoo 6.0 USE defaults and an optional ROM dependency |
| `app-emulation/86Box-roms-9999` | Live firmware ROM collection installed into the system ROM search path |

## Ship of Harkinian

The current package is `games-action/ship-of-harkinian-9.2.3`.

The ebuild fetches versioned source from Git because Shipwright's release source has
nested submodules and additional CMake-managed source dependencies. Every repository
is pinned to an exact commit, and all network activity is confined to Portage's
fetch/unpack phase. CMake is run with FetchContent disconnected.

Ship of Harkinian is currently keyworded `~amd64`, so amd64 users can opt in
through the normal Gentoo testing-keyword mechanism:

```sh
mkdir -p /etc/portage/package.accept_keywords
echo 'games-action/ship-of-harkinian ~amd64' > \
    /etc/portage/package.accept_keywords/ship-of-harkinian

mkdir -p /etc/portage/package.license
echo 'games-action/ship-of-harkinian all-rights-reserved' > \
    /etc/portage/package.license/ship-of-harkinian
```

The per-package license acceptance is intentional: Shipwright does not currently
publish a repository-wide license, so the ebuild records that source conservatively
instead of guessing a license.

Then install normally:

```sh
emerge -av games-action/ship-of-harkinian
```

### Rolling develop build

A live `games-action/ship-of-harkinian-9999` ebuild is also available. It tracks
upstream Shipwright's `develop` branch and follows the gitlink revisions selected
there for libultraship and Torch. FetchContent dependencies are fetched during
`src_unpack` from the revisions declared by the checked-out source, while CMake
remains fully disconnected from the network.

As a normal Gentoo live ebuild it has no `KEYWORDS`. Opt in explicitly:

```sh
echo '=games-action/ship-of-harkinian-9999 **' >> \
    /etc/portage/package.accept_keywords/ship-of-harkinian

emerge -av =games-action/ship-of-harkinian-9999
```

The stable and live ebuilds coexist in the repository but both use `SLOT="0"`,
so only one is installed at a time. Once `9999` is accepted it sorts newer than
9.2.3 and normal world updates may keep the live version installed. To return to
stable, remove the `9999 **` accept-keywords line and emerge 9.2.3 explicitly.

Optional USE flags:

- `remote-control` — SDL2_net remote-control support.
- `tts` — Linux text-to-speech support through eSpeak NG.

The package builds upstream's `NON_PORTABLE` configuration. Read-only application
files are managed by Portage under `/usr/libexec/ship-of-harkinian`; writable
configuration, saves, mods, and ROM-derived game-data archives remain in the user's
application-data directory.

The repository never contains an Ocarina of Time ROM or Nintendo-derived game
assets.

## 86Box: live emulator and ROM set

The overlay provides `app-emulation/86Box-9999`, adapted from Gentoo's
official 6.0 ebuild to track 86Box's `master` branch through `git-r3`.
It preserves all original USE defaults. The only additional USE flag is
`roms` (disabled by default), which adds a runtime dependency on the
separate `app-emulation/86Box-roms-9999` ebuild.

The ROM package tracks `86Box/roms` `master`, fetches the original
collection directly during Portage's Git unpack phase, and installs it into
`/usr/share/86Box/roms`. Each rebuild replaces the Portage-managed ROM
files, including tracking additions, renames, and removals. ROM binaries
are **not** stored in this overlay.

Both packages are unkeyworded live ebuilds. To opt in, add to
`/etc/portage/package.accept_keywords/86box`:

```text
=app-emulation/86Box-9999::goonbox-overlay **
=app-emulation/86Box-roms-9999::goonbox-overlay **
```

To enable the experimental hardware and install ROMs automatically, add
to `/etc/portage/package.use/86box`:

```text
app-emulation/86Box experimental roms
```

The ROMs have no single permissive redistribution license: upstream
notes that the files belong to their respective copyright holders.
Accept this license only for the ROM package, for local use, in
`/etc/portage/package.license/86box`:

```text
app-emulation/86Box-roms all-rights-reserved
```

Then install the emulator and its optional ROM dependency:

```sh
emerge --sync
emerge -av =app-emulation/86Box-9999
```

`emerge --sync` updates the **overlay**, not automatically the installed
source revisions from upstream. To explicitly refresh both live packages
and remove outdated Portage-owned ROMs:

```sh
emerge -1av =app-emulation/86Box-9999 =app-emulation/86Box-roms-9999
```

Alternatively, `app-portage/smart-live-rebuild` can detect which
installed Git-backed live packages have new upstream commits and rebuild
only those. It does not run automatically unless you schedule it.

Since upstream 7.0 development defaults to SDL3, the ebuild explicitly
keeps the SDL2 frontend used by Gentoo 6.0; the original SDL2 dependency
therefore remains valid. Current upstream CMake installs desktop assets
itself, unlike the released 6.0 tree. Changes to upstream dependencies or
build options may require future updates to this live ebuild.

## Repository policy

- Prefer source builds over repackaged binaries.
- Pin upstream source revisions used by versioned packages.
- Do not permit network access during configure, compile, or install phases.
- Keep writable user data out of Portage-managed system paths.
- Use existing Gentoo system libraries where practical.
- Use thin Manifests and inherit `::gentoo` as the repository master.
- New packages should pass `pkgcheck scan` before being considered ready.
- Nintendo ROMs, extracted copyrighted game assets, credentials, and other private data do not belong in this repository.

## Local development

A convenient workflow is to keep a writable clone in your home directory while Portage syncs its own copy:

```text
~/src/goonbox-overlay
        |
        | git push
        v
GitHub
        |
        | emerge --sync
        v
/var/db/repos/goonbox-overlay
        |
        v
Portage
```

Useful QA tools:

```sh
emerge -av app-portage/pkgdev
pkgcheck scan
pkgdev manifest
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the package-maintenance checklist.
