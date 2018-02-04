project (pantheon-greeter)
cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)

enable_testing ()

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set (CONF_DIR "/etc/lightdm")
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/pantheon-greeter")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (CMAKE_INSTALL_PREFIX /usr)
set (VERSION "3.2.0")

configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_BINARY_DIR}/src/config.vala)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Comment this out to enable C compiler warnings
add_definitions (-w)

find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED granite liblightdm-gobject-1>=1.2.1 gdk-x11-3.0 clutter-gtk-1.0 gdk-pixbuf-2.0 gl wingpanel-2.0)
add_definitions (${DEPS_CFLAGS})
link_libraries (${DEPS_LIBRARIES})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.26.0" MINIMUM)

include (ValaPrecompile)
vala_precompile (VALA_C
    src/PantheonGreeter.vala
    src/SettingsDaemon.vala
    src/UserList.vala
    src/UserListActor.vala

    src/Gateways/DummyGateway.vala
    src/Gateways/LightDMGateway.vala
    src/Gateways/LoginGateway.vala

    src/Indicators/EntryList.vala
    src/Indicators/IndicatorBar.vala
    src/Indicators/IndicatorEntry.vala
    src/Indicators/IndicatorPopover.vala
    src/Indicators/PopoverManager.vala
    src/Indicators/StyleClass.vala

    src/Interfaces/Credentials.vala
    src/Interfaces/LoginMask.vala

    src/LoginOptions/GuestLogin.vala
    src/LoginOptions/LoginOption.vala
    src/LoginOptions/ManualLogin.vala
    src/LoginOptions/UserLogin.vala

    src/Widgets/CredentialsArea.vala
    src/Widgets/FingerprintCredentials.vala
    src/Widgets/LoginBox.vala
    src/Widgets/LoginButtonCredentials.vala
    src/Widgets/PasswordCredentials.vala
    src/Widgets/TimeLabel.vala
    src/Widgets/Wallpaper.vala

    ${CMAKE_BINARY_DIR}/src/config.vala
PACKAGES
    granite
    liblightdm-gobject-1
    posix
    gdk-pixbuf-2.0
    gdk-x11-3.0
    x11
    clutter-gtk-1.0
    gl
    wingpanel-2.0
OPTIONS
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi
)

add_subdirectory (po)

include (GSettings)

include (GResource)
glib_compile_resources (GLIB_RESOURCES_CSS SOURCE data/css.gresource.xml)

add_executable (pantheon-greeter ${VALA_C} ${GLIB_RESOURCES_CSS})
target_link_libraries(pantheon-greeter m)

install (TARGETS pantheon-greeter RUNTIME DESTINATION sbin)
configure_file (${CMAKE_SOURCE_DIR}/data/pantheon-greeter.desktop.in ${CMAKE_BINARY_DIR}/data/pantheon-greeter.desktop)
install (FILES ${CMAKE_BINARY_DIR}/data/pantheon-greeter.desktop DESTINATION share/xgreeters)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/pantheon-greeter.conf DESTINATION ${CONF_DIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/fingerprint.svg DESTINATION ${PKGDATADIR})
