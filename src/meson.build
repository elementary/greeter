gobject_dep = dependency('gobject-2.0')
glib_dep = dependency('glib-2.0')
gdk_wl_dep = dependency('gdk-wayland-3.0')
gdk_x11_dep = dependency('gdk-x11-3.0')
gnome_desktop_dep = dependency('gnome-desktop-3.0')
gtk_dep = dependency('gtk+-3.0')
granite_dep = dependency('granite', version: '>= 5.5.0')
hdy_dep = dependency('libhandy-1', version: '>= 1.1.90')
lightdm_dep = dependency('liblightdm-gobject-1', version: '>= 1.30.0')
m_dep = meson.get_compiler('c').find_library('m')
wl_client_dep = dependency('wayland-client')
x11_dep = dependency('x11')

install_path = join_paths(get_option('prefix'), get_option('sbindir'))

executable(
    meson.project_name(),
    greeter_resources,
    'Application.vala',
    'FPrintUtils.vala',
    'MainWindow.vala',
    'PantheonAccountsServicePlugin.vala',
    'SessionLauncher.vala',
    'Settings.vala',
    'SettingsPortal.vala',
    'Cards/BaseCard.vala',
    'Cards/ManualCard.vala',
    'Cards/UserCard.vala',
    'Widgets/BackgroundImage.vala',
    'Widgets/CapsLockRevealer.vala',
    'Widgets/DateTimeWidget.vala',
    'Widgets/PasswordEntry.vala',
    'Widgets/SessionButton.vala',
    config_header,
    dependencies: [ gobject_dep, glib_dep, gdk_wl_dep, gdk_x11_dep, gtk_dep, granite_dep, hdy_dep, lightdm_dep, m_dep, pantheon_desktop_shell_dep, wl_client_dep, x11_dep ],
    install : true,
    install_dir: install_path
)
