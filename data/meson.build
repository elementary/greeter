conf_data = configuration_data()
conf_data.set('GETTEXT_PACKAGE', meson.project_name())
conf_data.set('PROJECT_NAME', meson.project_name())

install_data(
    'compositor.gschema.xml',
    install_dir: join_paths(get_option('prefix'), get_option('datadir'), 'glib-2.0', 'schemas'),
    rename: 'io.elementary.greeter-compositor.gschema.xml'
)

desktop_in = configure_file (
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'xgreeters'),
    configuration: conf_data
)

i18n.merge_file(
    input: 'greeter.metainfo.xml.in',
    output: meson.project_name() + '.metainfo.xml',
    po_dir: meson.project_source_root() / 'po' / 'extra',
    type: 'xml',
    install: true,
    install_dir: get_option('datadir') / 'metainfo',
)

# For notifications
install_data(
    desktop_in,
    install_dir: get_option('datadir') / 'applications',
)

install_data(
    meson.project_name() + '.conf',
    install_dir: join_paths(get_option('sysconfdir'), 'lightdm')
)

install_data(
    '40-' + meson.project_name() + '.conf',
    install_dir: join_paths(get_option('datadir'), 'lightdm', 'lightdm.conf.d')
)

test (
    'Validate desktop file',
    find_program('desktop-file-validate'),
    args: join_paths(meson.current_build_dir (), meson.project_name() + '.desktop')
)
