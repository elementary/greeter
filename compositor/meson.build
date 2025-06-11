
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

mutter45_dep = dependency('libmutter-13', version: ['>= 45', '< 46'], required: false)
if mutter45_dep.found()
	libmutter_dep = dependency('libmutter-13', version: '>= 45')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-mtk-13'), dependency('mutter-cogl-13'),
		dependency('mutter-cogl-pango-13'), dependency('mutter-clutter-13')
	]
endif

mutter46_dep = dependency('libmutter-14', version: ['>= 46', '< 47'], required: false)
if mutter46_dep.found()
	libmutter_dep = dependency('libmutter-14', version: '>= 46')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-mtk-14'), dependency('mutter-cogl-14'),
		dependency('mutter-cogl-pango-14'), dependency('mutter-clutter-14')
	]
	vala_flags = ['--define', 'HAS_MUTTER46']
endif

mutter47_dep = dependency('libmutter-15', version: ['>= 47', '< 48'], required: false)
if mutter47_dep.found()
	libmutter_dep = dependency('libmutter-15', version: '>= 47')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-mtk-15'), dependency('mutter-cogl-15'),
		dependency('mutter-cogl-pango-15'), dependency('mutter-clutter-15')
	]
	vala_flags = ['--define', 'HAS_MUTTER46', '--define', 'HAS_MUTTER47']
endif

mutter48_dep = dependency('libmutter-16', version: ['>= 48', '< 49'], required: false)
if mutter48_dep.found()
	libmutter_dep = dependency('libmutter-16', version: '>= 48')
	mutter_dep = [
		libmutter_dep,
		dependency('mutter-mtk-16'), dependency('mutter-cogl-16'),
		dependency('mutter-clutter-16')
	]
	vala_flags = ['--define', 'HAS_MUTTER46', '--define', 'HAS_MUTTER47', '--define', 'HAS_MUTTER48']
endif

if mutter_dep.length() == 0
	error ('No supported mutter library found!')
endif

mutter_typelib_dir = libmutter_dep.get_variable('typelibdir')

# Here is the real Compositor work
compositor_files = files(
  'Background/Animation.vala',
  'Background/Background.vala',
  'Background/BackgroundCache.vala',
  'Background/BackgroundContainer.vala',
  'Background/BackgroundManager.vala',
  'Background/BackgroundSource.vala',
  'Background/BlurEffect.vala',
  'Background/SystemBackground.vala',
  'PantheonShell.vala',
  'ShellClients/CenteredWindow.vala',
  'ShellClients/ManagedClient.vala',
  'ShellClients/NotificationsClient.vala',
  'ShellClients/PanelWindow.vala',
  'ShellClients/PositionedWindow.vala',
  'ShellClients/ShellClientsManager.vala',
  'ShellClients/ShellWindow.vala',
  'Widgets/SafeWindowClone.vala',
  'WingpanelManager/WingpanelManager.vala',
  'WingpanelManager/DBusWingpanelManager.vala',
  'WingpanelManager/FocusManager.vala',
  'WingpanelManager/BackgroundUtils.vala',
  'DBus.vala',
  'DBusAccelerator.vala',
  'Dialogs.vala',
  'KeyboardManager.vala',
  'main.vala',
  'MediaFeedback.vala',
  'PointerLocator.vala',
  'Utils.vala',
  'WindowManager.vala',
  'Zoom.vala'
)

subdir('protocol')

executable(
  meson.project_name()+'-compositor',
  compositor_files,
  config_header,
  dependencies: [glib_dep, gtk_dep, gee_dep, m_dep, posix_dep, mutter_dep, gnome_desktop_dep, pantheon_desktop_shell_dep],
  vala_args: vala_flags,
  c_args: compositor_c_args,
  build_rpath: mutter_typelib_dir,
  install_rpath: mutter_typelib_dir,
  install: true,
)
