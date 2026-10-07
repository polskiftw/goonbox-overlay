# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop git-r3 qmake-utils xdg

DESCRIPTION="Convert VR videos to normal flat videos using a virtual camera"
HOMEPAGE="https://vongoob9.gitlab.io/vr2normal/ https://gitlab.com/vongooB9/vr2normal"

EGIT_REPO_URI="https://gitlab.com/vongooB9/vr2normal.git"
EGIT_COMMIT="d2784a4b957d24394ab4201dc59f7888a84e8ea3"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=media-video/ffmpeg-5
	dev-qt/qtbase:6[gui,widgets]
"
DEPEND="${RDEPEND}"
BDEPEND="dev-qt/qtbase:6"

src_configure() {
	eqmake6
}

src_install() {
	dobin VR2Normal
	domenu VR2Normal.desktop
	doicon VR2Normal.svg VR2NormalFile.svg

	insinto /usr/share/mime/packages
	doins vr2normal.xml

	einstalldocs
}
