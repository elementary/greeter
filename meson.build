project(
    'io.elementary.greeter',
    'vala', 'c',
    version: '8.1.1',
    meson_version: '>= 0.58.0'
)

gnome = import('gnome')
i18n = import('i18n')
vala = meson.get_compiler('vala')

conf_data = configuration_data()
conf_data.set('CONF_DIR', join_paths(get_option('sysconfdir'), 'lightdm'))
conf_data.set('GETTEXT_PACKAGE', meson.project_name())
conf_data.set('LOCALE_DIR', join_paths(get_option('prefix'), get_option('localedir')))

gsd_dir = get_option('gsd-dir')

if gsd_dir == ''
    gsd_dir = join_paths(get_option('prefix'), get_option('libexecdir') + '/')
endif

message('Path to gnome-settings-daemon: ' + gsd_dir)

conf_data.set('GSD_DIR', gsd_dir)
conf_data.set('VERSION', meson.project_version())
config_header = configure_file (
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DGNOME_DESKTOP_USE_UNSTABLE_API',
    language:'c'
)

greeter_resources = gnome.compile_resources(
    'greeter-resources', 'data/greeter.gresource.xml',
    source_dir: 'data'
)

subdir('protocol')
subdir('src')
subdir('compositor')
subdir('session-manager')
subdir('data')
subdir('po')
vapigen = find_program('vapigen', required: false)
if vapigen.found()
	subdir('vapi')
endif

gnome.post_install(
    glib_compile_schemas: true,
    gtk_update_icon_cache: true
)
