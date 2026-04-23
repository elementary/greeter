gee_dep = dependency('gee-0.8')
gio_dep = dependency('gio-2.0')
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')

install_path = join_paths(get_option('prefix'), get_option('sbindir'))

files = files(
    'main.vala',
    'SessionManager.vala',
    'SettingsDaemon.vala',
    'SubprocessSupervisor.vala'
)

executable(
    meson.project_name()+'-session-manager',
    files,
    config_header,
    dependencies: [ gee_dep, gio_dep, glib_dep, gobject_dep ],
    install : true,
    install_dir: install_path
)
