
# Dependencies
glib_dep = [dependency('gio-2.0'), dependency('gio-unix-2.0'), dependency('gmodule-2.0')]
gtk_dep = [dependency('gtk+-3.0'), dependency('gdk-x11-3.0')]
gee_dep = dependency('gee-0.8')
m_dep = meson.get_compiler('c').find_library('m', required: false)
gnome_desktop_dep = dependency('gnome-desktop-3.0')

# Mutter is a complicated library with many API changes, copied from Gala.
mutter_dep = []
libmutter_dep = []

vala_flags = []
compositor_c_args = []

mutter318_dep = dependency('libmutter', version: ['>= 3.18.3', '< 3.19'], required: false)
if mutter318_dep.found()
	mutter_packages_command = [
		'--pkg', 'libmutter',
		'--pkg', 'cogl-1.0',
		'--pkg', 'clutter-1.0'
	]
	libmutter_dep = dependency('libmutter')
	mutter_dep = [libmutter_dep, dependency('cogl-1.0'), dependency('clutter-1.0')]
endif

mutter320_dep = dependency('libmutter', version: ['>= 3.19', '< 3.21'], required: false)
if mutter320_dep.found()
	mutter_packages_command = [
		'--pkg', 'libmutter',
		'--pkg', 'cogl-1.0',
		'--pkg', 'clutter-1.0'
	]
	libmutter_dep = dependency('libmutter', version: '>= 3.20.3')
	mutter_dep = [libmutter_dep, dependency('cogl-1.0'), dependency('clutter-1.0')]
	vala_flags += ['--define', 'HAS_MUTTER320']
endif

mutter322_dep = dependency('libmutter', version: ['>= 3.21', '< 3.23'], required: false)
if mutter322_dep.found()
	mutter_packages_command = [
		'--pkg', 'libmutter',
		'--pkg', 'mutter-cogl-1.0',
		'--pkg', 'mutter-cogl-pango-1.0',
		'--pkg', 'mutter-cogl-path-1.0',
		'--pkg', 'mutter-clutter-1.0'
	]
	libmutter_dep = dependency('libmutter', version: '>= 3.22.0')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-1.0'), dependency('mutter-cogl-pango-1.0'),
		dependency('mutter-cogl-path-1.0'), dependency('mutter-clutter-1.0')
	]
	vala_flags += ['--define', 'HAS_MUTTER320', '--define', 'HAS_MUTTER322']
	compositor_c_args = ['-DCLUTTER_ENABLE_COMPOSITOR_API', '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
		'-DCOGL_ENABLE_EXPERIMENTAL_API', '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API']
endif

mutter324_dep = dependency('libmutter-0', version: ['>= 3.23', '< 3.25'], required: false)
if mutter324_dep.found()
	mutter_packages_command = [
		'--pkg', 'libmutter-0',
		'--pkg', 'mutter-cogl-0',
		'--pkg', 'mutter-cogl-pango-0',
		'--pkg', 'mutter-cogl-path-0',
		'--pkg', 'mutter-clutter-0'
	]
	libmutter_dep = dependency('libmutter-0', version: '>= 3.24.0')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-0'), dependency('mutter-cogl-pango-0'),
		dependency('mutter-cogl-path-0'), dependency('mutter-clutter-0')
	]
	vala_flags += ['--define', 'HAS_MUTTER320', '--define', 'HAS_MUTTER322', '--define', 'HAS_MUTTER324']
	compositor_c_args = ['-DCLUTTER_ENABLE_COMPOSITOR_API', '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
		'-DCOGL_ENABLE_EXPERIMENTAL_API', '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API']
endif

mutter326_dep = dependency('libmutter-1', version: ['>= 3.25', '< 3.27'], required: false)
if mutter326_dep.found()
	mutter_packages_command = [
		'--pkg', 'libmutter-1',
		'--pkg', 'mutter-cogl-1',
		'--pkg', 'mutter-cogl-pango-1',
		'--pkg', 'mutter-cogl-path-1',
		'--pkg', 'mutter-clutter-1'
	]
	libmutter_dep = dependency('libmutter-1', version: '>= 3.26.0')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-1'), dependency('mutter-cogl-pango-1'),
		dependency('mutter-cogl-path-1'), dependency('mutter-clutter-1')
	]
	vala_flags += ['--define', 'HAS_MUTTER320', '--define', 'HAS_MUTTER322', '--define', 'HAS_MUTTER324', '--define', 'HAS_MUTTER326']
	compositor_c_args = ['-DCLUTTER_ENABLE_COMPOSITOR_API', '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
		'-DCOGL_ENABLE_EXPERIMENTAL_API', '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API']
endif

mutter328_dep = dependency('libmutter-2', version: ['>= 3.27', '< 3.29'], required: false)
if mutter328_dep.found()
	mutter_packages_command = [
		'--pkg', 'libmutter-2',
		'--pkg', 'mutter-cogl-2',
		'--pkg', 'mutter-cogl-pango-2',
		'--pkg', 'mutter-cogl-path-2',
		'--pkg', 'mutter-clutter-2'
	]
	libmutter_dep = dependency('libmutter-2', version: '>= 3.27.92')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-2'), dependency('mutter-cogl-pango-2'),
		dependency('mutter-cogl-path-2'), dependency('mutter-clutter-2')
	]
	vala_flags += ['--define', 'HAS_MUTTER320', '--define', 'HAS_MUTTER322', '--define', 'HAS_MUTTER324', '--define', 'HAS_MUTTER326', '--define', 'HAS_MUTTER328']
	compositor_c_args = ['-DCLUTTER_ENABLE_COMPOSITOR_API', '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
		'-DCOGL_ENABLE_EXPERIMENTAL_API', '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API']
endif

if mutter_dep.length() == 0
	error ('No supported mutter library found!')
endif

mutter_typelib_dir = libmutter_dep.get_pkgconfig_variable('typelibdir')

# Here is the real Compositor work
compositor_files = files(
	'main.vala',
	'WindowManager.vala',
	'MediaFeedback.vala',
	'DBus.vala',
	'DBusAccelerator.vala',
	'Wallpaper.vala',
	'Utils.vala'
)

executable(
	meson.project_name()+'-compositor',
	compositor_files,
	config_header,
	dependencies: [glib_dep, gtk_dep, gee_dep, m_dep, mutter_dep],
	vala_args: vala_flags,
	c_args: compositor_c_args,
	build_rpath: mutter_typelib_dir,
	install_rpath: mutter_typelib_dir,
	install: true,
)
