

public class AccessibilityMenu : Gtk.MenuItem {

    int onboard_stdout_fd;
    Gtk.Window keyboard_window;
    unowned KeyFile settings;
    int keyboard_pid;

    public AccessibilityMenu (KeyFile _settings) {
        this.settings = _settings;
        try {
            add (new Gtk.Image.from_pixbuf (Gtk.IconTheme.get_default ().lookup_by_gicon (
                                                          new GLib.ThemedIcon.with_default_fallbacks ("preferences-desktop-accessibility-symbolic"),
                                                          16, 0).load_symbolic ({1,1,1,1})));
        } catch (Error e) {
            warning (e.message);
        }

        submenu = new Gtk.Menu ();

        var keyboard = new Gtk.CheckMenuItem.with_label (_("Onscreen Keyboard"));
        try {
            keyboard.active = settings.get_boolean ("greeter", "onscreen-keyboard");
        } catch (Error e) {
            warning (e.message);
        }

        keyboard.toggled.connect ((e) => {
            toggle_keyboard (e.active);
        });
        submenu.append (keyboard);

        var high_contrast = new Gtk.CheckMenuItem.with_label (_("HighContrast"));
        high_contrast.toggled.connect (() => {
            Gtk.Settings.get_default ().gtk_theme_name = high_contrast.active ? "HighContrastInverse" : "elementary";
            settings.set_boolean ("greeter", "high-contrast", high_contrast.active);
        });

        try {
            high_contrast.active = settings.get_boolean ("greeter", "high-contrast");
        } catch (Error e) {
            warning (e.message);
        }

        submenu.append (high_contrast);

        try {
            if (settings.get_boolean ("greeter", "onscreen-keyboard")) {
                toggle_keyboard (true);
            }
        } catch (Error e) {
            warning (e.message);
        }
    }

    ~AccessibilityMenu () {
        if (keyboard_pid != 0) {
            Posix.kill (keyboard_pid, Posix.SIGKILL);

            int status;
            Posix.waitpid (keyboard_pid, out status, 0);
            keyboard_pid = 0;
        }
    }

    public void toggle_keyboard (bool active) {
        if (keyboard_window != null) {
            keyboard_window.visible = active;
            settings.set_boolean ("greeter", "onscreen-keyboard", active);
            return;
        }

        int id = 0;

        try {
            string [] argv;
            Shell.parse_argv ("onboard --xid", out argv);
            Process.spawn_async_with_pipes (null, argv, null, SpawnFlags.SEARCH_PATH, null, out keyboard_pid, null, out onboard_stdout_fd, null);

            var f = FileStream.fdopen (onboard_stdout_fd, "r");
            var stdout_text = new char[1024];
            f.gets (stdout_text);
            id = int.parse ((string)stdout_text);
        } catch (Error e) {
            warning (e.message);
        }

        var keyboard_socket = new Gtk.Socket ();
        keyboard_window = new Gtk.Window ();
        keyboard_window.accept_focus = false;
        keyboard_window.focus_on_map = false;
        keyboard_window.add (keyboard_socket);
        keyboard_socket.add_id (id);

        var screen = Gdk.Screen.get_default ();
        var monitor = screen.get_primary_monitor ();
        Gdk.Rectangle geom;
        screen.get_monitor_geometry (monitor, out geom);
        keyboard_window.move (geom.x, geom.y + geom.height - 200);
        keyboard_window.resize (geom.width, 200);
        keyboard_window.set_keep_above (true);

        keyboard_window.show_all ();
        settings.set_boolean ("greeter", "onscreen-keyboard", true);
    }

}
