actservice_dep = dependency('accountsservice')
gobject_dep = dependency('gobject-2.0')
glib_dep = dependency('glib-2.0')
gtk_dep = dependency('gtk+-3.0')
granite_dep = dependency('granite')
lightdm_dep = dependency('liblightdm-gobject-1')

install_path = join_paths(get_option('prefix'), get_option('sbindir'))

conf_data = configuration_data()
conf_data.set('CONF_DIR', join_paths(get_option('sysconfdir'), 'lightdm'))
conf_data.set('GETTEXT_PACKAGE', meson.project_name())

gsd_dir = get_option('gsd-dir')

if gsd_dir == ''
    if ubuntu_patched_gsd
        gsd_dir = join_paths(get_option('prefix'), 'lib', 'gnome-settings-daemon' + '/')
    else
        gsd_dir = join_paths(get_option('prefix'), get_option('libexecdir') + '/')
    endif
endif

message('Path to gnome-settings-daemon: ' + gsd_dir)

conf_data.set('GSD_DIR', gsd_dir)
conf_data.set('VERSION', meson.project_version())
config_header = configure_file (
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

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
    dependencies: [ actservice_dep, gobject_dep, glib_dep, gtk_dep, granite_dep, lightdm_dep ],
    install : true,
    install_dir: install_path
)
