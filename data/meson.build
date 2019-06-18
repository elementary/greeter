conf_data = configuration_data()
conf_data.set('GETTEXT_PACKAGE', meson.project_name())
conf_data.set('PROJECT_NAME', meson.project_name())

desktop_in = configure_file (
    input: meson.project_name() + '.desktop.in.in',
    output: meson.project_name() + '.desktop.in',
    configuration: conf_data
)

i18n.merge_file (
    'desktop',
    input: desktop_in,
    output: meson.project_name() + '.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'xgreeters'),
    po_dir: join_paths(meson.source_root (), 'po'),
    type: 'desktop'
)

install_data(
    meson.project_name() + '.conf',
    install_dir: join_paths(get_option('sysconfdir'), 'lightdm')
)

install_data(
    meson.project_name() + '.AccountsService.xml',
    install_dir: join_paths(get_option('datadir'), 'dbus-1', 'interfaces')
)

install_data(
    meson.project_name() + '.AccountsService.policy',
    install_dir: join_paths(get_option('datadir'), 'polkit-1', 'actions')
)

meson.add_install_script(
    'create-symlink.py',
    join_paths(get_option('datadir'), 'dbus-1', 'interfaces', meson.project_name() + '.AccountsService.xml'),
    join_paths(get_option('datadir'), 'accountsservice', 'interfaces', meson.project_name() + '.AccountsService.xml')
)

test (
    'Validate desktop file',
    find_program('desktop-file-validate'),
    args: join_paths(meson.current_build_dir (), meson.project_name() + '.desktop')
)
