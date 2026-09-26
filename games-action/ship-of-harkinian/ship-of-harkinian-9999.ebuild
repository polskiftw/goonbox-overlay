# Copyright 2026 goonbox-overlay contributors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/HarbourMasters/Shipwright.git"
EGIT_BRANCH="develop"

PYTHON_COMPAT=( python3_1{2..4} )
inherit cmake desktop git-r3 python-any-r1 xdg

DESCRIPTION="Native PC port of The Legend of Zelda: Ocarina of Time"
HOMEPAGE="https://www.shipofharkinian.com/ https://github.com/HarbourMasters/Shipwright"

# Shipwright itself does not publish a repository-wide license.  The remaining
# entries cover source components bundled into the build.
LICENSE="all-rights-reserved BSD-2 MIT MIT-0 WTFPL-2 ZLIB"
SLOT="0"
IUSE="tts"

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
	media-libs/sdl2-net
	media-libs/opus
	media-libs/opusfile
	media-libs/libvorbis
	virtual/zlib
	virtual/libusb:1
	virtual/opengl
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

PATCHES=(
	"${FILESDIR}/${PN}-live-no-network.patch"
)

_cmake_fetchcontent_field() {
	local file=${1}
	local dependency=${2}
	local field=${3}

	awk -v wanted="${dependency}" -v wanted_field="${field}" '
		function trim(value) {
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
			return value
		}
		{
			line = $0
			sub(/#.*/, "", line)

			if (!in_block && line ~ /^[[:space:]]*FetchContent_Declare[[:space:]]*\(/) {
				in_block = 1
				matched = 0
				sub(/^[[:space:]]*FetchContent_Declare[[:space:]]*\(/, "", line)
				line = trim(line)
				if (line != "" && line != ")") {
					split(line, parts, /[[:space:]]+/)
					if (tolower(parts[1]) == tolower(wanted))
						matched = 1
				}
				next
			}

			if (in_block && !matched) {
				line = trim(line)
				if (line == ")") {
					in_block = 0
					next
				}
				split(line, parts, /[[:space:]]+/)
				if (tolower(parts[1]) == tolower(wanted))
					matched = 1
				next
			}

			if (in_block && matched) {
				line = trim(line)
				if (line == ")")
					exit
				split(line, parts, /[[:space:]]+/)
				if (parts[1] == wanted_field) {
					value = parts[2]
					gsub(/^"|"$/, "", value)
					print value
					exit
				}
			}
		}
	' "${file}"
}

_git_checkout_ref() {
	local uri=${1}
	local remote_ref=${2}
	local id=${3}
	local destination=${4}
	local EGIT_BRANCH=
	local EGIT_COMMIT=

	git-r3_fetch "${uri}" "${remote_ref}" "${id}"
	git-r3_checkout "${uri}" "${WORKDIR}/${destination}" "${id}"
}

_fetchcontent_checkout() {
	local file=${1}
	local dependency=${2}
	local id=${3}
	local destination=${4}
	local uri ref remote_ref

	uri=$(_cmake_fetchcontent_field "${file}" "${dependency}" GIT_REPOSITORY)
	ref=$(_cmake_fetchcontent_field "${file}" "${dependency}" GIT_TAG)

	[[ -n ${uri} ]] || die "Could not find ${dependency} GIT_REPOSITORY in ${file}"
	[[ -n ${ref} ]] || die "Could not find ${dependency} GIT_TAG in ${file}"

	if [[ ${ref} =~ ^[0-9a-fA-F]{40}$ ]]; then
		remote_ref=${ref}
	elif [[ ${ref} == refs/* ]]; then
		remote_ref=${ref}
	else
		remote_ref="refs/tags/${ref}"
	fi

	_git_checkout_ref "${uri}" "${remote_ref}" "${id}" "${destination}"
}

src_unpack() {
	local common_cmake
	local stb_commit

	# git-r3 follows Shipwright's gitlinks recursively, so libultraship and Torch
	# are checked out at exactly the revisions selected by current develop.
	git-r3_src_unpack

	common_cmake="${S}/libultraship/cmake/dependencies/common.cmake"

	# Keep configure/build network-free while still following revision changes
	# made by the rolling source tree.  The tag/commit for each FetchContent
	# dependency is read from the just-checked-out upstream CMake files.
	_fetchcontent_checkout "${S}/CMakeLists.txt" spdlog spdlog spdlog
	_fetchcontent_checkout "${S}/soh/CMakeLists.txt" dr_libs dr-libs dr_libs

	_fetchcontent_checkout "${common_cmake}" ImGui imgui imgui
	_fetchcontent_checkout "${common_cmake}" StormLib stormlib stormlib
	_fetchcontent_checkout "${common_cmake}" libgfxd libgfxd libgfxd
	_fetchcontent_checkout "${common_cmake}" ThreadPool threadpool threadpool
	_fetchcontent_checkout "${common_cmake}" prism prism prism
	_fetchcontent_checkout "${common_cmake}" monocypher monocypher monocypher

	# Torch is a Shipwright submodule.  In the non-standalone configuration
	# used by SoH it currently FetchContents these libraries unconditionally.
	_fetchcontent_checkout "${S}/torch/CMakeLists.txt" yaml-cpp yaml-cpp yaml-cpp
	_fetchcontent_checkout "${S}/torch/CMakeLists.txt" tinyxml2 torch-tinyxml2 torch-tinyxml2
	_fetchcontent_checkout "${S}/torch/CMakeLists.txt" zlib torch-zlib torch-zlib

	# libultraship downloads stb_image.h directly rather than using
	# FetchContent.  Preserve the exact revision named by current develop.
	stb_commit=$(sed -n -E \
		's|.*github.com/nothings/stb/raw/([0-9a-fA-F]{40})/stb_image\.h.*|\1|p' \
		"${common_cmake}")
	[[ ${stb_commit} =~ ^[0-9a-fA-F]{40}$ ]] ||
		die "Could not determine stb revision from ${common_cmake}"
	_git_checkout_ref \
		"https://github.com/nothings/stb.git" \
		"${stb_commit}" \
		stb stb

	# Upstream intentionally tracks the controller database's master branch.
	# Fetch it during src_unpack so soh/CMakeLists.txt never needs curl access.
	_git_checkout_ref \
		"https://github.com/mdqinc/SDL_GameControllerDB.git" \
		"refs/heads/master" \
		gamecontrollerdb gamecontrollerdb
}

src_prepare() {
	cmake_src_prepare

	# Source overrides bypass FetchContent's PATCH_COMMAND.  Apply the exact
	# patches shipped by the libultraship revision selected by Shipwright.
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

		# Gentoo's cmake.eclass seeds BUILD_SHARED_LIBS=ON. Upstream SoH
		# intends bundled helper libraries such as StormLib to be static.
		-DBUILD_SHARED_LIBS=OFF

		# Hard guard against any unaccounted-for FetchContent dependency.
		-DFETCHCONTENT_FULLY_DISCONNECTED=ON
		-DFETCHCONTENT_SOURCE_DIR_SPDLOG="${WORKDIR}/spdlog"
		-DFETCHCONTENT_SOURCE_DIR_DR_LIBS="${WORKDIR}/dr_libs"
		-DFETCHCONTENT_SOURCE_DIR_IMGUI="${WORKDIR}/imgui"
		-DFETCHCONTENT_SOURCE_DIR_STORMLIB="${WORKDIR}/stormlib"
		-DFETCHCONTENT_SOURCE_DIR_LIBGFXD="${WORKDIR}/libgfxd"
		-DFETCHCONTENT_SOURCE_DIR_THREADPOOL="${WORKDIR}/threadpool"
		-DFETCHCONTENT_SOURCE_DIR_PRISM="${WORKDIR}/prism"
		-DFETCHCONTENT_SOURCE_DIR_MONOCYPHER="${WORKDIR}/monocypher"
		-DFETCHCONTENT_SOURCE_DIR_YAML-CPP="${WORKDIR}/yaml-cpp"
		-DFETCHCONTENT_SOURCE_DIR_TINYXML2="${WORKDIR}/torch-tinyxml2"
		-DFETCHCONTENT_SOURCE_DIR_ZLIB="${WORKDIR}/torch-zlib"

		-DSTB_IMAGE_HEADER="${WORKDIR}/stb/stb_image.h"
		-DGAMECONTROLLERDB_FILE="${WORKDIR}/gamecontrollerdb/gamecontrollerdb.txt"

		-DSTORM_SKIP_INSTALL=ON
		-DSTORM_BUILD_TESTS=OFF
		-DSTORM_USE_BUNDLED_LIBRARIES=OFF
	)

	if ! use tts; then
		# Upstream enables eSpeak opportunistically if it is installed.
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
