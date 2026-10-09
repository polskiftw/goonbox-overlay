# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/86Box/86Box.git"
EGIT_BRANCH="master"

inherit cmake flag-o-matic git-r3 xdg-utils

DESCRIPTION="Emulator of x86-based machines based on PCem"
HOMEPAGE="https://github.com/86Box/86Box"

LICENSE="GPL-2+"
SLOT="0"
IUSE="discord experimental +fluidsynth +munt new-dynarec +openal +qt6 roms +threads vde vnc"

DEPEND="
	app-emulation/faudio
	dev-libs/libevdev
	dev-libs/libserialport
	media-libs/freetype:2=
	media-libs/libpng:=
	media-libs/libsdl2
	media-libs/libsndfile
	media-libs/openal
	media-libs/rtmidi
	net-libs/libslirp
	virtual/zlib:=
	fluidsynth? ( media-sound/fluidsynth:= )
	munt? ( media-libs/munt-mt32emu )
	openal? ( media-libs/openal )
	qt6? (
		dev-util/vulkan-headers
		dev-libs/wayland
		dev-qt/qtbase:6=[gui,network,opengl,widgets]
		x11-libs/libX11
		x11-libs/libXi
		x11-libs/libxkbcommon
	)
	vnc? ( net-libs/libvncserver )
"
RDEPEND="${DEPEND}
	qt6? ( dev-qt/qttranslations:6 )
	roms? ( app-emulation/86Box-roms )
	vde? ( net-misc/vde )
"
BDEPEND="
	virtual/pkgconfig
	qt6? ( kde-frameworks/extra-cmake-modules )
"

src_configure() {
	# LTO needs to be filtered
	# See https://bugs.gentoo.org/854507
	filter-lto
	append-flags -fno-strict-aliasing

	local mycmakeargs=(
		-DCPPTHREADS="$(usex threads)"
		# Upstream development builds default to SDL3; keep Gentoo's SDL2 backend.
		-DSDL2="ON"
		# Never allow CMake to fetch untracked dependencies outside src_unpack.
		-DFETCHCONTENT_FULLY_DISCONNECTED="ON"
		-DLIBRASHADER_STATIC="OFF"
		-DDEV_BRANCH="$(usex experimental)"
		-DDISCORD="$(usex discord)"
		-DDYNAREC="ON"
		-DFLUIDSYNTH="$(usex fluidsynth)"
		-DHAS_VDE="$(usex vde "${EPREFIX}/usr/$(get_libdir)/libvdeplug.so" "HAS_VDE-NOTFOUND")"
		-DMINITRACE="OFF"
		-DMUNT="$(usex munt)"
		-DMUNT_EXTERNAL="$(usex munt)"
		-DNEW_DYNAREC="$(usex new-dynarec)"
		-DOPENAL="$(usex openal)"
		-DPREFER_STATIC="OFF"
		-DQT="$(usex qt6)"
		-DRELEASE="ON"
		-DRTMIDI="ON"
		$(usex qt6 '-DUSE_QT6=ON' '')
		-DVNC="$(usex vnc)"
	)

	cmake_src_configure
}

src_install() {
	# Current upstream CMake already installs desktop integration and icons.
	# The 6.0 ebuild's manually installed 96/192/512px icons no longer exist.
	cmake_src_install
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update

	if use roms; then
		elog "System ROMs are installed by app-emulation/86Box-roms."
	else
		elog "In order to use 86Box, you will need some roms for various emulated systems."
		elog "Enable USE=roms to have Portage manage the upstream ROM collection."
		elog "See https://github.com/86Box/roms for more information."
	fi
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
