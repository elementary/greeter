actservice_dep = dependency('accountsservice')
gobject_dep = dependency('gobject-2.0')
glib_dep = dependency('glib-2.0')
gtk_dep = dependency('gtk+-3.0')
granite_dep = dependency('granite', version: '>= 5.5.0')
hdy_dep = dependency('libhandy-1', version: '>= 1.1.90')
polkit_dep = dependency('polkit-gobject-1')
systemd_dep = dependency('libsystemd')
lightdm_dep = dependency('liblightdm-gobject-1')

install_path = join_paths(get_option('prefix'), get_option('sbindir'))

executable(
    meson.project_name(),
    greeter_resources,
    'Application.vala',
    'FPrintUtils.vala',
    'MainWindow.vala',
    'PantheonAccountsServicePlugin.vala',
    'PromptText.vala',
    'SettingsDaemon.vala',
    'Settings.vala',
    'SubprocessSupervisor.vala',
    'Cards/BaseCard.vala',
    'Cards/ManualCard.vala',
    'Cards/UserCard.vala',
    'Widgets/BackgroundImage.vala',
    'Widgets/CapsLockRevealer.vala',
    'Widgets/DateTimeWidget.vala',
    'Widgets/PasswordEntry.vala',
    'Widgets/SessionButton.vala',
    config_header,
    dependencies: [ actservice_dep, gobject_dep, glib_dep, gtk_dep, granite_dep, hdy_dep, polkit_dep, systemd_dep, lightdm_dep ],
    install : true,
    install_dir: install_path
)
