project (pantheon-greeter)
cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.6)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala)
enable_testing ()

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/pantheon-greeter")
set (CMAKE_INSTALL_PREFIX /usr)

configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_BINARY_DIR}/src/config.vala)
add_definitions (-DGETTEXT_PACKAGE="pantheon-greeter")

find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED granite liblightdm-gobject-1 gdk-x11-3.0 clutter-gtk-1.0 indicator3-0.4 gdk-pixbuf-2.0)
add_definitions (${DEPS_CFLAGS})
link_libraries (${DEPS_LIBRARIES})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.16.0" MINIMUM)

file(GLOB_RECURSE sources src/*.vala)

include (ValaPrecompile)
vala_precompile (VALA_C
    ${sources}
    ${CMAKE_BINARY_DIR}/src/config.vala
PACKAGES
    granite
    liblightdm-gobject-1
    posix
    gdk-pixbuf-2.0
    gdk-x11-3.0
    x11
    clutter-gtk-1.0
    indicator-0.4
OPTIONS
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi
)

add_subdirectory (po)

include (GSettings)
add_schema ("data/org.pantheon.desktop.greeter.gschema.xml")

add_executable (pantheon-greeter ${VALA_C})

install (TARGETS pantheon-greeter RUNTIME DESTINATION share/xgreeters)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/pantheon-greeter.desktop DESTINATION share/xgreeters)
