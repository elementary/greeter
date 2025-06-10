actservice_dep = dependency('accountsservice')
gobject_dep = dependency('gobject-2.0')
glib_dep = dependency('glib-2.0')
gdk_wl_dep = dependency('gtk4-wayland')
gdk_x11_dep = dependency('gtk4-x11')
gnome_desktop_dep = dependency('gnome-desktop-3.0')
gtk_dep = dependency('gtk4')
granite_dep = dependency('granite-7')
adw_dep = dependency('libadwaita-1')
lightdm_dep = dependency('liblightdm-gobject-1')
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
    'Settings.vala',
    'SettingsPortal.vala',
    'Cards/BaseCard.vala',
    'Cards/ManualCard.vala',
    'Cards/UserCard.vala',
    'Widgets/CapsLockRevealer.vala',
    'Widgets/DateTimeWidget.vala',
    'Widgets/PasswordEntry.vala',
    'Widgets/SessionButton.vala',
    config_header,
    dependencies: [ actservice_dep, gobject_dep, glib_dep, gdk_wl_dep, gdk_x11_dep, gtk_dep, granite_dep, adw_dep, lightdm_dep, m_dep, pantheon_desktop_shell_dep, wl_client_dep, x11_dep ],
    install : true,
    install_dir: install_path
)
