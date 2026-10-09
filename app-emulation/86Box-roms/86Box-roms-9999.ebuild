# Copyright 2026 goonbox-overlay contributors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/86Box/roms.git"
EGIT_BRANCH="master"

inherit git-r3

DESCRIPTION="Firmware ROM collection for the 86Box PC emulator"
HOMEPAGE="https://github.com/86Box/roms"

# The collection contains firmware owned by multiple original vendors.
# It is fetched from upstream on the user's machine, never redistributed
# through the overlay or Gentoo binary package mirrors.
LICENSE="all-rights-reserved"
SLOT="0"
RESTRICT="bindist mirror"

src_install() {
	local romdir

	insinto /usr/share/86Box/roms
	# Install every current top-level ROM directory, including new ones
	# added upstream. Hidden Git metadata is deliberately not copied.
	for romdir in "${S}"/*; do
		[[ -d ${romdir} ]] || continue
		doins -r "${romdir}" || die "Failed to install ${romdir}"
	done
}
