
# Dependencies
glib_dep = [dependency('gio-2.0'), dependency('gio-unix-2.0'), dependency('gmodule-2.0')]
gtk_dep = [dependency('gtk+-3.0'), dependency('gdk-x11-3.0')]
gee_dep = dependency('gee-0.8')
m_dep = meson.get_compiler('c').find_library('m', required: false)

# Mutter is a complicated library with many API changes, copied from Gala.
mutter_dep = []
libmutter_dep = []

vala_flags = []
compositor_c_args = []

mutter318_dep = dependency('libmutter', version: ['>= 3.18.3', '< 3.19'], required: false)
if mutter318_dep.found()
  libmutter_dep = dependency('libmutter')
  mutter_dep = [libmutter_dep, dependency('cogl-1.0'), dependency('clutter-1.0')]
endif

mutter320_dep = dependency('libmutter', version: ['>= 3.19', '< 3.21'], required: false)
if mutter320_dep.found()
  libmutter_dep = dependency('libmutter', version: '>= 3.20.3')
  mutter_dep = [libmutter_dep, dependency('cogl-1.0'), dependency('clutter-1.0')]
  vala_flags += ['--define', 'HAS_MUTTER320']
endif

mutter322_dep = dependency('libmutter', version: ['>= 3.21', '< 3.23'], required: false)
if mutter322_dep.found()
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

mutter330_dep = dependency('libmutter-3', version: ['>= 3.29.4', '< 3.31'], required: false)
if mutter330_dep.found()
  libmutter_dep = dependency('libmutter-3', version: '>= 3.29.4')
  mutter_dep = [
    libmutter_dep,
    dependency('mutter-cogl-3'), dependency('mutter-cogl-pango-3'),
    dependency('mutter-cogl-path-3'), dependency('mutter-clutter-3')
  ]
  vala_flags += ['--define', 'HAS_MUTTER320', '--define', 'HAS_MUTTER322', '--define', 'HAS_MUTTER324', '--define', 'HAS_MUTTER326', '--define', 'HAS_MUTTER328', '--define', 'HAS_MUTTER330']
  compositor_c_args = ['-DCLUTTER_ENABLE_COMPOSITOR_API', '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
    '-DCOGL_ENABLE_EXPERIMENTAL_API', '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API']
endif

mutter332_dep = dependency('libmutter-4', version: ['>= 3.31.2', '< 3.34'], required: false)
if mutter332_dep.found()
  libmutter_dep = dependency('libmutter-4', version: '>= 3.31.2')
  mutter_dep = [
    libmutter_dep,
    dependency('mutter-cogl-4'), dependency('mutter-cogl-pango-4'),
    dependency('mutter-cogl-path-4'), dependency('mutter-clutter-4')
  ]
  vala_flags += ['--define', 'HAS_MUTTER320', '--define', 'HAS_MUTTER322', '--define', 'HAS_MUTTER324', '--define', 'HAS_MUTTER326', '--define', 'HAS_MUTTER328', '--define', 'HAS_MUTTER330', '--define', 'HAS_MUTTER332']
  compositor_c_args = ['-DCLUTTER_ENABLE_COMPOSITOR_API', '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
    '-DCOGL_ENABLE_EXPERIMENTAL_API', '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API']
endif

mutter334_dep = dependency('libmutter-5', version: ['>= 3.34', '< 3.35.1'], required: false)
if mutter334_dep.found()
  libmutter_dep = dependency('libmutter-5', version: '>= 3.34')
  mutter_dep = [
    libmutter_dep,
    dependency('mutter-cogl-5'), dependency('mutter-cogl-pango-5'),
    dependency('mutter-cogl-path-5'), dependency('mutter-clutter-5')
  ]
  vala_flags += ['--define', 'HAS_MUTTER320', '--define', 'HAS_MUTTER322', '--define', 'HAS_MUTTER324', '--define', 'HAS_MUTTER326', '--define', 'HAS_MUTTER328', '--define', 'HAS_MUTTER330', '--define', 'HAS_MUTTER332', '--define', 'HAS_MUTTER334']
  compositor_c_args = ['-DCLUTTER_ENABLE_COMPOSITOR_API', '-DCLUTTER_ENABLE_EXPERIMENTAL_API',
    '-DCOGL_ENABLE_EXPERIMENTAL_API', '-DCOGL_ENABLE_EXPERIMENTAL_2_0_API']
endif

mutter336_dep = dependency('libmutter-6', version: ['>= 3.35.1', '< 3.38'], required: false)
if mutter336_dep.found()
  libmutter_dep = dependency('libmutter-6', version: '>= 3.35.1')
  mutter_dep = [
    libmutter_dep,
    dependency('mutter-cogl-6'), dependency('mutter-cogl-pango-6'),
    dependency('mutter-cogl-path-6'), dependency('mutter-clutter-6')
  ]
  vala_flags += ['--define', 'HAS_MUTTER320', '--define', 'HAS_MUTTER322', '--define', 'HAS_MUTTER324', '--define', 'HAS_MUTTER326', '--define', 'HAS_MUTTER328', '--define', 'HAS_MUTTER330', '--define', 'HAS_MUTTER332', '--define', 'HAS_MUTTER334', '--define', 'HAS_MUTTER336']
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
  'SystemBackground.vala',
  'Utils.vala'
)

executable(
  meson.project_name()+'-compositor',
  compositor_files,
  compositor_resources,
  config_header,
  dependencies: [glib_dep, gtk_dep, gee_dep, m_dep, mutter_dep],
  vala_args: vala_flags,
  c_args: compositor_c_args,
  build_rpath: mutter_typelib_dir,
  install_rpath: mutter_typelib_dir,
  install: true,
)
