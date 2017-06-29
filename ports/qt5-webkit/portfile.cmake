# Common Ambient Variables:
#   CURRENT_BUILDTREES_DIR    = ${VCPKG_ROOT_DIR}\buildtrees\${PORT}
#   CURRENT_PACKAGES_DIR      = ${VCPKG_ROOT_DIR}\packages\${PORT}_${TARGET_TRIPLET}
#   CURRENT_PORT DIR          = ${VCPKG_ROOT_DIR}\ports\${PORT}
#   PORT                      = current port name (zlib, etc)
#   TARGET_TRIPLET            = current triplet (x86-windows, x64-windows-static, etc)
#   VCPKG_CRT_LINKAGE         = C runtime linkage type (static, dynamic)
#   VCPKG_LIBRARY_LINKAGE     = target library linkage type (static, dynamic)
#   VCPKG_ROOT_DIR            = <C:\path\to\current\vcpkg>
#   VCPKG_TARGET_ARCHITECTURE = target architecture (x64, x86, arm)
#

include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/qtwebkit-5.212.0-alpha2)
vcpkg_download_distfile(ARCHIVE
    URLS "https://github.com/annulen/webkit/releases/download/qtwebkit-5.212.0-alpha2/qtwebkit-5.212.0-alpha2.tar.xz"
    FILENAME "qtwebkit-5.212-alpha2.tar.xz"
    SHA512 b15985aab20c5618dc1f71a0d91f02dbed993516272090a4a12990714bf4c9554ccbdcf9d6a143bf46fcc2c170f691e571114d61686fe49791f8d5c540785758
)
vcpkg_extract_source_archive(${ARCHIVE})

# post source-extract adjust FindICU.cmake and comment out setting for icu-libs
vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES "${CMAKE_CURRENT_LIST_DIR}/cmake_vcpkg_adjustment.patch" "${CMAKE_CURRENT_LIST_DIR}/wk2-icu59-fix.patch"
)


vcpkg_find_acquire_program(PYTHON2)
vcpkg_find_acquire_program(NASM)
vcpkg_find_acquire_program(PERL)
vcpkg_find_acquire_program(RUBY)
vcpkg_find_acquire_program(BISON)
vcpkg_find_acquire_program(FLEX)
vcpkg_find_acquire_program(GPERF)

# Gperf is required in environment-path for the build to succeed
get_filename_component(GPERF_DIR ${GPERF} DIRECTORY)

# For ruby include dir
get_filename_component(RUBY_DIR ${RUBY} DIRECTORY)
set(RUBY_INCLUDE_DIR "${RUBY_DIR}/../include")

# Qtwebkit build system requires libs for QtTools-exes and gperf in the path
SET(ENV{PATH} "$ENV{PATH};${GPERF_DIR};${CURRENT_INSTALLED_DIR}/bin;${CURRENT_INSTALLED_DIR}/debug/bin")
# This fixes issues on machines with default codepages that are not ASCII compatible, such as some CJK encodings
set(ENV{_CL_} "/utf-8")

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DPORT=Qt
        -DUSE_MEDIA_FOUNDATION=ON
        -DUSE_QT_MULTIMEDIA=OFF
        -DENABLE_WEBKIT2=ON
        -DENABLE_API_TESTS=OFF
        -DENABLE_TEST_SUPPORT=OFF
        -DENABLE_TOOLS=ON
        -DGENERATE_DOCUMENTATION=OFF
        -DQML_INSTALL_DIR=${CURRENT_PACKAGES_DIR}/qml
        -DFLEX_EXECUTABLE=${FLEX}
        -DBISON_EXECUTABLE=${BISON}
        -DGPERF_EXECUTABLE=${GPERF}
        -DRUBY_EXECUTABLE=${RUBY}
        -DRUBY_INCLUDE_DIR=${RUBY_INCLUDE_DIR}
    # OPTIONS_RELEASE -DOPTIMIZE=1
    # OPTIONS_DEBUG -DDEBUGGABLE=1
)

vcpkg_install_cmake()

vcpkg_copy_pdbs()

# post default install
vcpkg_apply_patches(
    SOURCE_PATH ${CURRENT_PACKAGES_DIR}/debug/lib/cmake
    PATCHES "${CMAKE_CURRENT_LIST_DIR}/adjust-debug-folders.patch"
)

file(GLOB EXECUTABLES ${CURRENT_PACKAGES_DIR}/bin/*.exe)
file(GLOB EXECUTABLES_DBG ${CURRENT_PACKAGES_DIR}/debug/bin/*.exe)
file(COPY ${EXECUTABLES} DESTINATION ${CURRENT_PACKAGES_DIR}/tools/${PORT})
file(COPY ${CURRENT_PACKAGES_DIR}/lib/cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share)
file(COPY ${CURRENT_PACKAGES_DIR}/debug/lib/cmake/Qt5Webkit/WebKitTargets-debug.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/cmake/Qt5Webkit)
file(COPY ${CURRENT_PACKAGES_DIR}/debug/lib/cmake/Qt5WebkitWidgets/Qt5WebKitWidgetsTargets-debug.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/cmake/Qt5WebkitWidgets)
file(COPY ${CURRENT_PACKAGES_DIR}/mkspecs DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(REMOVE ${EXECUTABLES} ${EXECUTABLES_DBG})
file(REMOVE_RECURSE 
    ${CURRENT_PACKAGES_DIR}/lib/cmake
    ${CURRENT_PACKAGES_DIR}/lib/pkgconfig
    ${CURRENT_PACKAGES_DIR}/mkspecs
    ${CURRENT_PACKAGES_DIR}/debug/include
    ${CURRENT_PACKAGES_DIR}/debug/lib/cmake
    ${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig
    ${CURRENT_PACKAGES_DIR}/debug/mkspecs
)

# Handle copyright
file(INSTALL ${SOURCE_PATH}/LICENSE.LGPLv21 DESTINATION  ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
