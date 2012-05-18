
/*big parts stolen from unity-greeter ;) */
public class IndicatorMenuItem : Gtk.MenuItem {
    
    public unowned Indicator.ObjectEntry entry;
    private Gtk.Box hbox;
    
    public IndicatorMenuItem (Indicator.ObjectEntry entry) {
        this.entry = entry;
        this.hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        this.add (this.hbox);
        this.hbox.show ();
        
        /*if (entry.label != null) {
            entry.label.show.connect (this.visibility_changed_cb);
            entry.label.hide.connect (this.visibility_changed_cb);
            hbox.pack_start (entry.label, false, false, 0);
        }*/
        if (entry.image != null) {
            entry.image.show.connect (visibility_changed_cb);
            entry.image.hide.connect (visibility_changed_cb);
            hbox.pack_start (entry.image, false, false, 0);
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
            proxy.call ("UpdateActivationEnvironment", new GLib.Variant ("(a{ss})", builder), 
                GLib.DBusCallFlags.NONE, -1, null);
        } catch (Error e) { warning ("Could not get set environment for indicators: %s", e.message); }
    }
    
    public Indicators () {
        
        this.bar = new Gtk.MenuBar ();
        (this.get_widget () as Gtk.Container).add (this.bar);
        
        bar.pack_direction = Gtk.PackDirection.RTL;
        
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
        string[] filenames = {Path.build_filename (INDICATORDIR, "libsession.so"),
                              Path.build_filename (INDICATORDIR, "libpower.so"),
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
                bar.get_children ().foreach ( (c) => {
                    if (entry == (c as IndicatorMenuItem).entry)
                        bar.remove (c);
                });
            });
            foreach (var entry in io.get_entries ())
                bar.append (new IndicatorMenuItem (entry));
        }
        
        start ();
    }
}

