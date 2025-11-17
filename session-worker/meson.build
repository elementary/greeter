gio_dep = dependency('gio-2.0')
gio_unix = dependency('gio-unix-2.0')
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
posix_dep = meson.get_compiler('vala').find_library('posix')

install_path = join_paths(get_option('prefix'), get_option('sbindir'))

files = files(
    'Application.vala',
    'SessionWorker.vala'
)

executable(
    meson.project_name()+'-session-worker',
    files,
    config_header,
    dependencies: [ gio_dep, gio_unix, glib_dep, gobject_dep, posix_dep ],
    install : true,
    install_dir: install_path
)
