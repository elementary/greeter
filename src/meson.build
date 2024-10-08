actservice_dep = dependency('accountsservice')
gobject_dep = dependency('gobject-2.0')
glib_dep = dependency('glib-2.0')
gtk_dep = dependency('gtk4')
granite_dep = dependency('granite-7', version: '>= 7.0.0')
adw_dep = dependency('libadwaita-1', version: '>= 1.0.0')
lightdm_dep = dependency('liblightdm-gobject-1')
gnome_desktop_dep = dependency('gnome-desktop-3.0')
m_dep = meson.get_compiler('c').find_library('m')

install_path = join_paths(get_option('prefix'), get_option('sbindir'))

executable(
    meson.project_name(),
    greeter_resources,
    'Application.vala',
    'FPrintUtils.vala',
    'MainWindow.vala',
    'PantheonAccountsServicePlugin.vala',
    'PromptText.vala',
    'Settings.vala',
    'Cards/BaseCard.vala',
    'Cards/ManualCard.vala',
    'Cards/UserCard.vala',
    'Widgets/CapsLockRevealer.vala',
    'Widgets/DateTimeWidget.vala',
    'Widgets/PasswordEntry.vala',
    'Widgets/SessionButton.vala',
    config_header,
    dependencies: [ actservice_dep, gobject_dep, glib_dep, gtk_dep, granite_dep, adw_dep, lightdm_dep, m_dep ],
    install : true,
    install_dir: install_path
)
