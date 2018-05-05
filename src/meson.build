conf_data = configuration_data()
conf_data.set('CONF_DIR', '/etc/lightdm')
conf_data.set('DATADIR', get_option('datadir'))
conf_data.set('GSD_DIR', '/usr/lib/gnome-settings-daemon/')
conf_data.set('PKGDATADIR', join_paths(get_option('datadir'), meson.project_name()))
conf_data.set('GETTEXT_PACKAGE', meson.project_name())
conf_data.set('VERSION', '3.2.0')
config_header = configure_file (
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

executable(
    meson.project_name(),
    'PantheonGreeter.vala',
    'SettingsDaemon.vala',
    'UserList.vala',
    'UserListActor.vala',
    'Gateways/DummyGateway.vala',
    'Gateways/LightDMGateway.vala',
    'Gateways/LoginGateway.vala',
    'Indicators/EntryList.vala',
    'Indicators/IndicatorBar.vala',
    'Indicators/IndicatorEntry.vala',
    'Indicators/IndicatorPopover.vala',
    'Indicators/PopoverManager.vala',
    'Indicators/StyleClass.vala',
    'Interfaces/Credentials.vala',
    'Interfaces/LoginMask.vala',
    'LoginOptions/GuestLogin.vala',
    'LoginOptions/LoginOption.vala',
    'LoginOptions/ManualLogin.vala',
    'LoginOptions/UserLogin.vala',
    'Widgets/CredentialsArea.vala',
    'Widgets/FingerprintCredentials.vala',
    'Widgets/LoginBox.vala',
    'Widgets/LoginButtonCredentials.vala',
    'Widgets/PasswordCredentials.vala',
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
    install : true
)