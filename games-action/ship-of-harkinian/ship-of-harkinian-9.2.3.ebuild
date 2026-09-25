# Copyright 2026 goonbox-overlay contributors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/HarbourMasters/Shipwright.git"
EGIT_BRANCH="develop"
EGIT_COMMIT="cb71e22a79bc5d1f688fa881795bbd93094895fc"

PYTHON_COMPAT=( python3_1{2..4} )
inherit cmake desktop git-r3 python-any-r1 xdg

DESCRIPTION="Native PC port of The Legend of Zelda: Ocarina of Time"
HOMEPAGE="https://www.shipofharkinian.com/ https://github.com/HarbourMasters/Shipwright"

# Shipwright itself does not publish a repository-wide license.  The remaining
# entries cover source components bundled into the build.
LICENSE="all-rights-reserved MIT MIT-0 WTFPL-2 ZLIB"
SLOT="0"
KEYWORDS="~amd64"
IUSE="remote-control tts"

# Be conservative while upstream has no repository-wide license.
RESTRICT="bindist mirror"

RDEPEND="
	app-arch/bzip2
	dev-libs/libzip
	dev-libs/spdlog
	dev-libs/tinyxml2
	media-libs/libogg
	media-libs/libpng
	media-libs/libsdl2[opengl,video]
	media-libs/opus
	media-libs/opusfile
	media-libs/libvorbis
	virtual/zlib
	virtual/libusb:1
	virtual/opengl
	remote-control? ( media-libs/sdl2-net )
	tts? ( app-accessibility/espeak-ng )
"
DEPEND="
	${RDEPEND}
	dev-cpp/nlohmann_json
"
BDEPEND="
	${PYTHON_DEPS}
	sys-apps/lsb-release
"

DR_LIBS_COMMIT="da35f9d6c7374a95353fd1df1d394d44ab66cf01"
IMGUI_COMMIT="4806a1924ff6181180bf5e4b8b79ab4394118875"
STORMLIB_COMMIT="28c9b4be3f23c6b3a5ff55cacac7dbe5b9cdc4fc"
LIBGFXD_COMMIT="008f73dca8ebc9151b205959b17773a19c5bd0da"
THREADPOOL_COMMIT="097aa718f25d44315cadb80b407144ad455ee4f9"
PRISM_COMMIT="bbcbc7e3f890a5806b579361e7aa0336acd547e7"
STB_COMMIT="0bc88af4de5fb022db643c2d8e549a0927749354"
GAMECONTROLLERDB_COMMIT="c6d6e7ecca57ff106ef63350da3cc03728d88a5f"

PATCHES=(
	"${FILESDIR}/${P}-no-network.patch"
)

_git_checkout_dependency() {
	local uri=${1}
	local commit=${2}
	local id=${3}
	local destination=${4}
	local EGIT_BRANCH=${5}

	# git-r3 uses EGIT_BRANCH dynamically.  Keep Shipwright's develop branch
	# from leaking into auxiliary repositories, while still fetching the exact
	# pinned commit from the branch that contains it.
	git-r3_fetch "${uri}" "${commit}" "${id}"
	git-r3_checkout "${uri}" "${WORKDIR}/${destination}" "${id}"
}

src_unpack() {
	# Fetch Shipwright and the exact submodule revisions recorded by 9.2.3.
	git-r3_src_unpack

	# Upstream normally FetchContent/downloads these during CMake configure.
	# Pull them into Portage's fetch phase instead so configure/build can remain
	# network-sandboxed and deterministic.
	_git_checkout_dependency \
		"https://github.com/mackron/dr_libs.git" \
		"${DR_LIBS_COMMIT}" \
		dr-libs dr_libs master
	_git_checkout_dependency \
		"https://github.com/ocornut/imgui.git" \
		"${IMGUI_COMMIT}" \
		imgui imgui docking
	_git_checkout_dependency \
		"https://github.com/ladislav-zezula/StormLib.git" \
		"${STORMLIB_COMMIT}" \
		stormlib stormlib master
	_git_checkout_dependency \
		"https://github.com/glankk/libgfxd.git" \
		"${LIBGFXD_COMMIT}" \
		libgfxd libgfxd master
	_git_checkout_dependency \
		"https://github.com/bshoshany/thread-pool.git" \
		"${THREADPOOL_COMMIT}" \
		threadpool threadpool master
	_git_checkout_dependency \
		"https://github.com/KiritoDv/prism-processor.git" \
		"${PRISM_COMMIT}" \
		prism prism main
	_git_checkout_dependency \
		"https://github.com/nothings/stb.git" \
		"${STB_COMMIT}" \
		stb stb master
	_git_checkout_dependency \
		"https://github.com/mdqinc/SDL_GameControllerDB.git" \
		"${GAMECONTROLLERDB_COMMIT}" \
		gamecontrollerdb gamecontrollerdb master
}

src_prepare() {
	cmake_src_prepare

	# FetchContent normally applies these patches itself. Source overrides bypass
	# FetchContent's PATCH_COMMAND, so apply the exact upstream patches here.
	pushd "${WORKDIR}/imgui" >/dev/null || die
	eapply "${S}/libultraship/cmake/dependencies/patches/imgui-fixes-and-config.patch"
	popd >/dev/null || die

	pushd "${WORKDIR}/stormlib" >/dev/null || die
	eapply "${S}/libultraship/cmake/dependencies/patches/stormlib-optimizations.patch"
	popd >/dev/null || die
}

src_configure() {
	python_setup
	CMAKE_BUILD_TYPE="Release"

	local mycmakeargs=(
		-DPython3_EXECUTABLE="${PYTHON}"
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/libexec/${PN}"
		-DNON_PORTABLE=ON

		# A hard guard against an unaccounted-for FetchContent dependency.
		-DFETCHCONTENT_FULLY_DISCONNECTED=ON
		-DFETCHCONTENT_SOURCE_DIR_DR_LIBS="${WORKDIR}/dr_libs"
		-DFETCHCONTENT_SOURCE_DIR_IMGUI="${WORKDIR}/imgui"
		-DFETCHCONTENT_SOURCE_DIR_STORMLIB="${WORKDIR}/stormlib"
		-DFETCHCONTENT_SOURCE_DIR_LIBGFXD="${WORKDIR}/libgfxd"
		-DFETCHCONTENT_SOURCE_DIR_THREADPOOL="${WORKDIR}/threadpool"
		-DFETCHCONTENT_SOURCE_DIR_PRISM="${WORKDIR}/prism"

		-DSTB_IMAGE_HEADER="${WORKDIR}/stb/stb_image.h"
		-DGAMECONTROLLERDB_FILE="${WORKDIR}/gamecontrollerdb/gamecontrollerdb.txt"

		-DSTORM_SKIP_INSTALL=ON
		-DSTORM_BUILD_TESTS=OFF
		-DSTORM_USE_BUNDLED_LIBRARIES=OFF
		-DBUILD_REMOTE_CONTROL=$(usex remote-control ON OFF)
	)

	if ! use tts; then
		# Upstream enables eSpeak opportunistically if it is installed. Force it
		# off when the USE flag is disabled so installed packages do not change
		# the result of the build.
		mycmakeargs+=( -DESPEAK=ESPEAK-NOTFOUND )
	fi

	cmake_src_configure
}

src_compile() {
	# soh.o2r contains Ship's own assets and is required at runtime. This target
	# explicitly does not consume an Ocarina of Time ROM.
	cmake_build GenerateSohOtr
	cmake_src_compile
}

src_install() {
	cmake_src_install

	dosym "../libexec/${PN}/soh.elf" /usr/bin/ship-of-harkinian
	dosym "ship-of-harkinian" /usr/bin/soh

	newicon -s 512 "${S}/soh/macosx/sohIcon.png" ship-of-harkinian.png
	newmenu "${FILESDIR}/ship-of-harkinian.desktop" ship-of-harkinian.desktop

	dodoc README.md
}
