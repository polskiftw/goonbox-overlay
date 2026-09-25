# Contributing

This repository follows normal Gentoo ebuild conventions as closely as is practical for a personal overlay.

## Package checklist

Before pushing a new package or version:

1. Confirm the package is not already adequately provided by `::gentoo` or another intentionally-used repository.
2. Prefer a stable upstream release over a moving branch.
3. Pin all non-system source inputs.
4. Do not disable Portage's network sandbox to accommodate a build system.
5. Prefer system libraries when upstream supports them cleanly.
6. Keep generated user data outside Portage-managed paths.
7. Add or update `metadata.xml`.
8. Generate/update the Manifest when the package uses `SRC_URI`.
9. Run:
   ```sh
   pkgcheck scan
   ```
10. Test an actual merge on goonbox before treating a new package as proven.

## Ebuild style

- Use the newest EAPI that is appropriate and supported by required eclasses.
- New architecture support starts unstable (`~arch`) after a successful test on that architecture.
- VCS-fetched packages follow Gentoo's VCS keywording rules.
- Small packaging patches belong in `<category>/<package>/files/`.
- Do not include upstream copyrighted assets that are not redistributable.
- Document unusual choices in the ebuild rather than hiding them behind QA suppressions.

## Commit style

Prefer Gentoo-like subjects:

```text
games-action/ship-of-harkinian: add 9.2.3
metadata: add initial repository configuration
```
