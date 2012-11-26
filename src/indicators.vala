
/*big parts stolen from unity-greeter ;) */
public class IndicatorMenuItem : Gtk.MenuItem
{
    public unowned Indicator.ObjectEntry entry;
    private Gtk.Box hbox;
    
    public IndicatorMenuItem (Indicator.ObjectEntry _entry)
    {
        entry = _entry;
        hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        add (this.hbox);
        hbox.show ();
        
        if (entry.image != null) {
            var img = entry.image;
            
            img.show.connect (visibility_changed_cb);
            img.hide.connect (visibility_changed_cb);
            hbox.pack_start (img, false, false, 0);
            img.show ();
        }
        if (entry.accessible_desc != null)
            get_accessible ().set_name (entry.accessible_desc);
        if (entry.menu != null)
            submenu = entry.menu;
        
        if (has_visible_child ())
            show ();
    }
    public bool has_visible_child () {
        return (entry.image != null && entry.image.get_visible ()) ||
               (entry.label != null && entry.label.get_visible ());
    }
    public void visibility_changed_cb (Gtk.Widget widget) { visible = has_visible_child (); }
}

public class Indicators : GtkClutter.Actor {
    
    int keyboard_pid;
    
    public Gtk.MenuBar bar;
    private List<Indicator.Object> indicator_objects;
    
    public async void start () {
        string[] disabled = {"org.gnome.settings-daemon.plugins.background",
                             "org.gnome.settings-daemon.plugins.clipboard",
                             "org.gnome.settings-daemon.plugins.font",
                             "org.gnome.settings-daemon.plugins.gconf",
                             "org.gnome.settings-daemon.plugins.gsdwacom",
                             "org.gnome.settings-daemon.plugins.housekeeping",
                             "org.gnome.settings-daemon.plugins.keybindings",
                             "org.gnome.settings-daemon.plugins.keyboard",
                             "org.gnome.settings-daemon.plugins.media-keys",
                             "org.gnome.settings-daemon.plugins.mouse",
                             "org.gnome.settings-daemon.plugins.print-notifications",
                             "org.gnome.settings-daemon.plugins.smartcard",
                             "org.gnome.settings-daemon.plugins.sound",
                             "org.gnome.settings-daemon.plugins.wacom",
                             "org.gnome.settings-daemon.plugins.xsettings"};
        
        string[] enabled =  {"org.gnome.settings-daemon.plugins.a11y-keyboard",
                             "org.gnome.settings-daemon.plugins.a11y-settings",
                             "org.gnome.settings-daemon.plugins.color",
                             "org.gnome.settings-daemon.plugins.cursor",
                             "org.gnome.settings-daemon.plugins.power",
                             "org.gnome.settings-daemon.plugins.xrandr"};
        foreach (var schema in disabled)
            toggle_schema (schema, false);
        foreach (var schema in enabled)
            toggle_schema (schema, true);
        GLib.Bus.own_name (GLib.BusType.SESSION, "org.gnome.ScreenSaver",
                           GLib.BusNameOwnerFlags.NONE);
        yield run ();
    }
    
    ~Indicators ()
    {
        if (keyboard_pid != 0) {
            Posix.kill (keyboard_pid, Posix.SIGKILL);
            int status;
            Posix.waitpid (keyboard_pid, out status, 0);
            keyboard_pid = 0;
        }
    }

    private async void run () {
        try {
            var proxy = new GLib.DBusProxy.for_bus_sync (GLib.BusType.SESSION,
                                                         GLib.DBusProxyFlags.NONE, null, 
                                                         "org.gnome.SettingsDaemon",
                                                         "/org/gnome/SettingsDaemon",
                                                         "org.gnome.SettingsDaemon",
                                                         null);
            yield proxy.call ("Awake", null, GLib.DBusCallFlags.NONE, -1, null);
        } catch (Error e) {warning ("Could not start gnome-settings-daemon: %s", e.message); }
    }
    
    private void toggle_schema (string name, bool active) {
        var schema = SettingsSchemaSource.get_default ().lookup (name, false);
        if (schema != null)
            new Settings (name).set_boolean ("active", active);
	}
	
	private void greeter_set_env (string key, string val) {
		GLib.Environment.set_variable (key, val, true);
		try {
			var proxy = new GLib.DBusProxy.for_bus_sync (GLib.BusType.SESSION,
                                                         GLib.DBusProxyFlags.NONE, null,
                                                         "org.freedesktop.DBus",
                                                         "/org/freedesktop/DBus",
                                                         "org.freedesktop.DBus",
                                                         null);
			var builder = new GLib.VariantBuilder (GLib.VariantType.ARRAY);
			builder.add ("{ss}", key, val);
			proxy.call ("UpdateActivationEnvironment", new Variant ("(a{ss})", builder), DBusCallFlags.NONE, -1, null);
		} catch (Error e) { warning ("Could not get set environment for indicators: %s", e.message); }
    }
	
	Settings settings;
	
	public Indicators (LoginBox loginbox, Settings _settings) {
		settings = _settings;
		
		bar = new Gtk.MenuBar ();
        (get_widget () as Gtk.Container).add (bar);
        
        bar.pack_direction = Gtk.PackDirection.RTL;
        height = 26;
        
        var transp = new Gtk.CssProvider ();
        try {
            transp.load_from_data ("*{background-color:@transparent;-GtkWidget-window-dragging:false;}", -1);
        } catch (Error e) { warning (e.message); }
        bar.get_style_context ().add_provider (transp, 20000);
        
        this.get_widget ().draw.connect ( (ctx) => {
            ctx.set_operator (Cairo.Operator.SOURCE);
            ctx.rectangle (0, 0, bar.get_allocated_width (), bar.get_allocated_height ());
            ctx.set_source_rgba (0, 0, 0, 0.6);
            ctx.fill ();
            
            return false;
        });
        
        greeter_set_env ("INDICATOR_GREETER_MODE", "1");
        greeter_set_env ("GIO_USE_VFS", "local");
        greeter_set_env ("GVFS_DISABLE_FUSE", "1");
        greeter_set_env ("RUNNING_UNDER_GDM", "1");
        
        var INDICATORDIR = "/usr/lib/indicators3/7";
        string[] filenames = {Path.build_filename (INDICATORDIR, "libpower.so"),
                              Path.build_filename (INDICATORDIR, "libsoundmenu.so")};
        
        foreach (var filename in filenames) {
            var io = new Indicator.Object.from_file (filename);
            if (io == null)
                continue;
            
            indicator_objects.append (io);
            io.entry_added.connect ( (object, entry) => {
                bar.append (new IndicatorMenuItem (entry));
            });
            io.entry_removed.connect ( (object, entry) => {
                for (var i=1;i<bar.get_children ().length () - 1;i++) {
                    if (entry == (bar.get_children ().nth_data (i) as IndicatorMenuItem).entry)
                        bar.remove (bar.get_children ().nth_data (i));
                }
            });
            foreach (var entry in io.get_entries ())
                bar.append (new IndicatorMenuItem (entry));
        }
        
        start ();
        
        var power = new Gtk.MenuItem ();
        try {
        	power.add (new Gtk.Image.from_pixbuf (Gtk.IconTheme.get_default ().lookup_by_gicon (
		    	new GLib.ThemedIcon.with_default_fallbacks ("system-shutdown-symbolic"), 16, 0).load_symbolic ({1,1,1,1})));
    	} catch (Error e) { warning (e.message); }
        power.submenu = new Gtk.Menu ();
        
        var poweroff = new Gtk.MenuItem.with_label (_("Shutdown"));
        var suspend = new Gtk.MenuItem.with_label (_("Suspend"));
       	var restart = new Gtk.MenuItem.with_label (_("Restart"));
       	var hibernate = new Gtk.MenuItem.with_label (_("Hibernate"));
        if (LightDM.get_can_hibernate ())
        	power.submenu.append (hibernate);
    	if (LightDM.get_can_suspend ())
        	power.submenu.append (suspend);
    	if (LightDM.get_can_restart ())
        	power.submenu.append (restart);
    	if (LightDM.get_can_shutdown ())
        	power.submenu.append (poweroff);
        poweroff.activate.connect (() => {try { LightDM.shutdown (); } catch (Error e) { warning (e.message); }});
        suspend.activate.connect (() => {try { LightDM.suspend (); } catch (Error e) { warning (e.message); }});
        restart.activate.connect (() => {try { LightDM.restart (); } catch (Error e) { warning (e.message); }});
        hibernate.activate.connect (() => {try { LightDM.hibernate (); } catch (Error e) { warning (e.message); }});
        
        bar.insert (power, 0);
        power.show_all ();
        
        var accessibility = new Gtk.MenuItem ();
        try {
        	accessibility.add (new Gtk.Image.from_pixbuf (Gtk.IconTheme.get_default ().lookup_by_gicon (
		    	new GLib.ThemedIcon.with_default_fallbacks ("preferences-desktop-accessibility-symbolic"), 16, 0).load_symbolic ({1,1,1,1})));
		} catch (Error e) { warning (e.message); }
		accessibility.submenu = new Gtk.Menu ();
		
		var keyboard = new Gtk.CheckMenuItem.with_label (_("Onscreen Keyboard"));
		keyboard.toggled.connect (toggle_keyboard);
		keyboard.active = settings.get_boolean ("onscreen-keyboard");
		accessibility.submenu.append (keyboard);
		
		var high_contrast = new Gtk.CheckMenuItem.with_label (_("HighContrast"));
		high_contrast.toggled.connect (() => {
			Gtk.Settings.get_default ().gtk_theme_name = high_contrast.active ? "HighContrastInverse" : "elementary";
			
			if (high_contrast.active)
				loginbox.draw_ref.get_style_context ().remove_class ("content-view-window");
			else
				loginbox.draw_ref.get_style_context ().add_class ("content-view-window");
			
			settings.set_boolean ("high-contrast", high_contrast.active);
			
			loginbox.get_widget ().queue_draw ();
		});
		high_contrast.active = settings.get_boolean ("high-contrast");
		accessibility.submenu.append (high_contrast);
		
		bar.append (accessibility);
		
		accessibility.show_all ();
    }
    
    int onboard_stdout_fd;
    Gtk.Window keyboard_window;
    
	void toggle_keyboard (Gtk.CheckMenuItem item)
	{
		if (keyboard_window != null) {
			keyboard_window.visible = item.active;
			settings.set_boolean ("onscreen-keyboard", item.active);
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
		} catch (Error e) { warning (e.message); }
		
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
		settings.set_boolean ("onscreen-keyboard", true);
    }
}

