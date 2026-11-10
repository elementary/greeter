accountsservice_dep = dependency('accountsservice')
gobject_dep = dependency('gobject-2.0')
glib_dep = dependency('glib-2.0')
gdk_wl_dep = dependency('gtk4-wayland')
gtk_dep = dependency('gtk4')
granite_dep = dependency('granite-7')
adw_dep = dependency('libadwaita-1')
lightdm_dep = dependency('liblightdm-gobject-1', version: '>= 1.30.0')
m_dep = meson.get_compiler('c').find_library('m')
wl_client_dep = dependency('wayland-client')

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
    dependencies: [ accountsservice_dep, gobject_dep, glib_dep, gdk_wl_dep, gtk_dep, granite_dep, adw_dep, lightdm_dep, m_dep, pantheon_desktop_shell_dep, wl_client_dep ],
    install : true,
    install_dir: install_path
)
