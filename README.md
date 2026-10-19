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
| `games-action/ship-of-harkinian-9999` | Live native Linux build of Ship of Harkinian, tracking upstream `develop` |
| `app-emulation/86Box-9999` | Live 86Box emulator following upstream `master` |
| `app-emulation/86Box-roms-9999` | Upstream ROM collection, installed into 86Box's system ROM path |
| `media-libs/librashader-0.12.1` | Source-built Vulkan shader runtime for 86Box |

## Ship of Harkinian (live)

The overlay provides `games-action/ship-of-harkinian-9999`, tracking Shipwright's `develop` branch. There is no versioned Ship of Harkinian ebuild in this repository.

Git submodules and CMake FetchContent dependencies are fetched during Portage's unpack phase at revisions selected by the checked-out source. Configure and build run with FetchContent disconnected, rather than downloading untracked dependencies during compilation.

Like other Gentoo live ebuilds, `9999` has no `KEYWORDS`. To opt in:

```sh
mkdir -p /etc/portage/package.accept_keywords /etc/portage/package.license
echo '=games-action/ship-of-harkinian-9999::goonbox-overlay **' >> /etc/portage/package.accept_keywords/ship-of-harkinian
echo 'games-action/ship-of-harkinian all-rights-reserved' >> /etc/portage/package.license/ship-of-harkinian
emerge -av =games-action/ship-of-harkinian-9999
```

The upstream source has no project-wide license, so the ebuild uses `all-rights-reserved` conservatively rather than guessing. The only optional USE flag is `tts` for eSpeak NG text-to-speech.

The package builds upstream's `NON_PORTABLE` configuration. Portage manages read-only application files under `/usr/libexec/ship-of-harkinian`; writable configuration, saves, mods, and ROM-derived archives remain in the user's application-data directory. No Ocarina of Time ROM or Nintendo-derived game assets are included in the repository.

`emerge --sync` updates the overlay but does not automatically rebuild a live package at newer upstream commits. Use `emerge -1av =games-action/ship-of-harkinian-9999` or `app-portage/smart-live-rebuild` to refresh installed Git-backed sources.

## 86Box: live emulator and ROM set

The overlay provides `app-emulation/86Box-9999`, adapted from Gentoo's
official 6.0 ebuild to track 86Box's `master` branch through `git-r3`.
It preserves upstream defaults for the retained Gentoo USE switches. The
upstream-removed `NEW_DYNAREC` build option is no longer exposed; remove
`new-dynarec` from any local `package.use` entry. The overlay also exposes:

- `roms` (off): install the separately managed firmware ROM collection.
- `librashader` (on): compile Qt Vulkan shader support and automatically
  install `media-libs/librashader[vulkan]`. Requires `qt6`.
- `soundcanvas` (on): compile Sound Canvas CLAP host support.

Audio backends follow `openal`: when disabled, 86Box uses FAudio instead.
The `vde` USE flag now fully controls VDE detection, including on machines
where its headers happen to be installed.

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
media-libs/librashader ~amd64
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

Upstream development now defaults to SDL3, and the live ebuild follows
that upstream choice. The ebuild uses system `media-libs/libsdl3`, explicitly
disables SDL2, and does not need a separate backend USE flag. Gentoo's SDL3
3.2 series is stable on amd64; newer SDL3 releases may still be `~amd64`,
so only unmask them if you specifically need one. Current upstream CMake
installs desktop assets itself, unlike the released 6.0 tree. Changes to
upstream dependencies or build options may require future updates.

## librashader (versioned)

`media-libs/librashader-0.12.1` builds the upstream Rust C API from its
pinned release source and the crates in upstream's `Cargo.lock`. Portage
verifies every distfile's checksums and builds offline, with no dependence
on an unofficial prepacked Rust dependency archive.

Vulkan runtime support is on by default, matching 86Box's shader backend.
OpenGL is optional; `X`, `wayland`, `lto`, `tools`, and `static-libs`
are optional as well. The runtime installs `librashader.so`, which 86Box
loads dynamically when Vulkan shader presets are used. No shader collection
is bundled.

The versioned librashader ebuild is `~amd64`; on a stable system, accept
that keyword as shown in the 86Box section above. `USE=-librashader` on
86Box avoids this dependency entirely.

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

GitHub Actions runs `pkgcheck` on changes. **86Box** and **Ship of Harkinian**
now have independent Portage dependency-plan and full Gentoo build workflows:
changing an 86Box ebuild does not start a Ship job, or vice versa. Each
package's full-build workflow can also be launched manually using GitHub
Actions > **86Box - Full Gentoo build** or **Ship of Harkinian - Full Gentoo
build**. Full builds compile and install from source inside a fresh Gentoo
container and may consume significant runner time. The Ship dependency-plan
workflow also dry-runs the patch that disables CMake network fetching.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the package-maintenance checklist.
