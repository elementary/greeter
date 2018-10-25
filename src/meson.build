conf_data = configuration_data()
conf_data.set('CONF_DIR', join_paths(get_option('sysconfdir'), 'lightdm'))
conf_data.set('GETTEXT_PACKAGE', meson.project_name())
conf_data.set('GSD_DIR', '/usr/lib/gnome-settings-daemon/')
conf_data.set('VERSION', meson.project_version())
config_header = configure_file (
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)
install_path = join_paths(get_option('prefix'), get_option('sbindir'))

executable(
    meson.project_name(),
    'ComponentWatcher.vala',
    'PantheonGreeter.vala',
    'SettingsDaemon.vala',
    'UserList.vala',
    'UserListActor.vala',
    'LoginMask.vala',
    'Credentials/Credentials.vala',
    'Credentials/FingerprintCredentials.vala',
    'Credentials/LoginButtonCredentials.vala',
    'Credentials/PasswordCredentials.vala',
    'Gateways/DummyGateway.vala',
    'Gateways/LightDMGateway.vala',
    'Gateways/LoginGateway.vala',
    'LoginOptions/GuestLogin.vala',
    'LoginOptions/LoginOption.vala',
    'LoginOptions/ManualLogin.vala',
    'LoginOptions/UserLogin.vala',
    'Widgets/CredentialsArea.vala',
    'Widgets/LoginBox.vala',
    'Widgets/TimeLabel.vala',
    'Widgets/Wallpaper.vala',
    config_header,
    greeter_resources,

    dependencies: [
        dependency('clutter-gtk-1.0'),
        dependency('gdk-pixbuf-2.0'),
        dependency('gdk-x11-3.0'),
        dependency('gl'),
        dependency('granite'),
        dependency('liblightdm-gobject-1'),
        dependency('wingpanel-2.0'),
        dependency('x11'),
        meson.get_compiler('vala').find_library('posix'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install : true,
    install_dir: install_path
)
