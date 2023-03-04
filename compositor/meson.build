
# Dependencies
glib_dep = [dependency('gio-2.0'), dependency('gio-unix-2.0'), dependency('gmodule-2.0')]
gtk_dep = [dependency('gtk+-3.0'), dependency('gdk-x11-3.0')]
gee_dep = dependency('gee-0.8')
m_dep = meson.get_compiler('c').find_library('m', required: false)
posix_dep = meson.get_compiler('vala').find_library('posix', required: false)

# Mutter is a complicated library with many API changes, copied from Gala.
mutter_dep = []
libmutter_dep = []

vala_flags = []
compositor_c_args =['-DCLUTTER_ENABLE_COMPOSITOR_API', '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
		'-DCOGL_ENABLE_EXPERIMENTAL_API', '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API']

mutter338_dep = dependency('libmutter-7', version: ['>= 3.37', '< 3.39'], required: false)
if mutter338_dep.found()
	libmutter_dep = dependency('libmutter-7', version: '>= 3.37')
	mutter_dep = [
	    libmutter_dep,
		dependency('mutter-cogl-7'), dependency('mutter-cogl-pango-7'),
		dependency('mutter-clutter-7')
	]
endif

mutter40_dep = dependency('libmutter-8', version: ['>= 40', '< 41'], required: false)
if mutter40_dep.found()
	libmutter_dep = dependency('libmutter-8', version: '>= 40')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-8'), dependency('mutter-cogl-pango-8'),
		dependency('mutter-clutter-8')
	]
	vala_flags = ['--define', 'HAS_MUTTER40']
endif

mutter41_dep = dependency('libmutter-9', version: ['>= 41', '< 42'], required: false)
if mutter41_dep.found()
	libmutter_dep = dependency('libmutter-9', version: '>= 41')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-9'), dependency('mutter-cogl-pango-9'),
		dependency('mutter-clutter-9')
	]
	vala_flags = ['--define', 'HAS_MUTTER40', '--define', 'HAS_MUTTER41']
endif

mutter42_dep = dependency('libmutter-10', version: ['>= 42', '< 43'], required: false)
if mutter42_dep.found()
	libmutter_dep = dependency('libmutter-10', version: '>= 42')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-10'), dependency('mutter-cogl-pango-10'),
		dependency('mutter-clutter-10')
	]
	vala_flags = ['--define', 'HAS_MUTTER40', '--define', 'HAS_MUTTER41', '--define', 'HAS_MUTTER42']
endif

mutter43_dep = dependency('libmutter-11', version: ['>= 43', '< 44'], required: false)
if mutter43_dep.found()
	libmutter_dep = dependency('libmutter-11', version: '>= 43')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-cogl-11'), dependency('mutter-cogl-pango-11'),
		dependency('mutter-clutter-11')
	]
	vala_flags = ['--define', 'HAS_MUTTER40', '--define', 'HAS_MUTTER41', '--define', 'HAS_MUTTER42', '--define', 'HAS_MUTTER43']
endif

if mutter_dep.length() == 0
	error ('No supported mutter library found!')
endif

mutter_typelib_dir = libmutter_dep.get_pkgconfig_variable('typelibdir')

# Here is the real Compositor work
compositor_files = files(
  'BackgroundManager.vala',
  'BackgroundUtils.vala',
  'DBus.vala',
  'DBusAccelerator.vala',
  'DBusBackgroundManager.vala',
  'Dialogs.vala',
  'KeyboardManager.vala',
  'main.vala',
  'MediaFeedback.vala',
  'SystemBackground.vala',
  'Utils.vala',
  'WindowManager.vala'
)

executable(
  meson.project_name()+'-compositor',
  compositor_files,
  compositor_resources,
  config_header,
  dependencies: [glib_dep, gtk_dep, gee_dep, m_dep, posix_dep, mutter_dep],
  vala_args: vala_flags,
  c_args: compositor_c_args,
  build_rpath: mutter_typelib_dir,
  install_rpath: mutter_typelib_dir,
  install: true,
)
