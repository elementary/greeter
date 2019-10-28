public class Greeter.DateTimeWidget : Gtk.Grid {
    public bool is_24h { get; set; default=true; }

    private Gtk.Label time_label;
    private Gtk.Label date_label;
    private uint time_timeout = 0U;

    construct {
        int x, y;
        var display = Gdk.Display.get_default ();
        display.get_pointer (null, out x, out y, null);
        var monitor = display.get_monitor_at_point (x, y);
        var rect = monitor.get_geometry ();
        var scale = get_scale_factor ();

        // NOTE: Display height divided by 12
        margin_top = rect.height / scale / 16;

        orientation = Gtk.Orientation.VERTICAL;

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/greeter/DateTime.css");

        time_label = new Gtk.Label (null);

        var time_label_style_context = time_label.get_style_context ();
        time_label_style_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
        time_label_style_context.add_class ("time");
        time_label_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        date_label = new Gtk.Label (null);

        var date_label_style_context = date_label.get_style_context ();
        date_label_style_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
        date_label_style_context.add_class ("date");
        date_label_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        add (time_label);
        add (date_label);

        update_time ();
        update_date ();
        notify["is-24h"].connect (() => {
            GLib.Source.remove (time_timeout);
            update_time ();
        });
    }

    private bool update_time () {
        var now = new GLib.DateTime.now_local ();
        time_label.label = now.format (Granite.DateTime.get_default_time_format (!is_24h, false));
        var delta = 60 - now.get_second ();
        time_timeout = GLib.Timeout.add_seconds (delta, update_time);
        return GLib.Source.REMOVE;
    }

    private bool update_date () {
        var now = new GLib.DateTime.now_local ();
        date_label.label = now.format (Granite.DateTime.get_default_date_format (true, true, false));
        var delta = 24 * 60 * 60 - (now.get_second () + now.get_minute () * 60 + now.get_hour () * 60 * 60);
        GLib.Timeout.add_seconds (delta, update_date);
        return GLib.Source.REMOVE;
    }
}
