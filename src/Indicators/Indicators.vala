// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2014 elementary Developers

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/

/*big parts stolen from unity-greeter ;) */

public class IndicatorMenuItem : Gtk.MenuItem {

    public unowned Indicator.ObjectEntry entry;
    private Gtk.Box hbox;

    public IndicatorMenuItem (Indicator.ObjectEntry _entry) {
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

    public void visibility_changed_cb (Gtk.Widget widget) {
        visible = has_visible_child ();
    }
}

public class Indicators : GtkClutter.Actor {
    int margin_to_right = 5;

    PowerMenu power;

    unowned KeyFile settings;

    public KeyboardLayoutMenu keyboard_menu { get; private set; }

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

        foreach (var schema in disabled) {
            toggle_schema (schema, false);
        }

        foreach (var schema in enabled) {
            toggle_schema (schema, true);
        }

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
        } catch (Error e) {
            warning ("Could not start gnome-settings-daemon: %s", e.message);
        }
    }


    public Indicators (KeyFile _settings) {
        settings = _settings;
        bar = new Gtk.MenuBar ();
        (get_widget () as Gtk.Container).add (bar);

        bar.pack_direction = Gtk.PackDirection.RTL;
        height = 26;
        bar.show_all ();

        var transp = new Gtk.CssProvider ();
        try {
            transp.load_from_data ("*{background-color:@transparent;-GtkWidget-window-dragging:false;}", -1);
        } catch (Error e) { warning (e.message); }
        bar.get_style_context ().add_provider (transp, 20000);


        this.get_widget ().draw.connect ((ctx) => {
            ctx.rectangle (0, 0, bar.get_allocated_width (), bar.get_allocated_height ());
            ctx.set_operator (Cairo.Operator.SOURCE);
            ctx.set_source_rgba (0, 0, 0, 0);
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
            io.entry_added.connect ((object, entry) => {
                bar.append (new IndicatorMenuItem (entry));
            });

            io.entry_removed.connect ((object, entry) => {
                for (var i = 1; i < bar.get_children ().length (); i++) {
                    if (bar.get_children ().nth_data (i) is IndicatorMenuItem)
                        if (entry == (bar.get_children ().nth_data (i) as IndicatorMenuItem).entry)
                            bar.remove (bar.get_children ().nth_data (i));
                }
            });

            foreach (var entry in io.get_entries ()) {
                var widget = new IndicatorMenuItem (entry);
                bar.append (widget);
                widget.margin_right = margin_to_right;
            }

        }

        start.begin ();

        //keyboard layout menu
        keyboard_menu = new KeyboardLayoutMenu ();
        bar.append (keyboard_menu);
        keyboard_menu.margin_right = margin_to_right;
        keyboard_menu.show_all ();

        power = new PowerMenu ();
        power.margin_right = margin_to_right;
        bar.insert (power, 0);
        power.show_all ();

        var accessibility = new AccessibilityMenu (settings);
        accessibility.margin_right = margin_to_right;
        bar.append (accessibility);

        accessibility.show_all ();
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
            proxy.call.begin ("UpdateActivationEnvironment", new Variant ("(a{ss})", builder), DBusCallFlags.NONE, -1, null);
        } catch (Error e) {
            warning ("Could not get set environment for indicators: %s", e.message);
        }
    }

    private void toggle_schema (string name, bool active) {
        var schema = SettingsSchemaSource.get_default ().lookup (name, false);

        if (schema != null)
            new Settings (name).set_boolean ("active", active);
    }
}
