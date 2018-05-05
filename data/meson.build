i18n.merge_file (
    'desktop',
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'xgreeters'),
    po_dir: join_paths(meson.source_root (), 'po'),
    type: 'desktop'
)

install_data(
    meson.project_name() + '.conf',
    install_dir: '/etc/lightdm'
)
install_data(
    'fingerprint.svg',
    install_dir: join_paths(get_option('datadir'), meson.project_name())
)

test (
    'Validate desktop file',
    find_program('desktop-file-validate'),
    args: join_paths(meson.current_build_dir (), meson.project_name() + '.desktop')
)