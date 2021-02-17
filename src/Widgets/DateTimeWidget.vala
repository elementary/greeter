[DBus (name = "org.freedesktop.login1.Manager")]
interface LoginManager : GLib.Object {
    public signal void prepare_for_sleep (bool start);
}

public class Greeter.DateTimeWidget : Gtk.Grid {
    public bool is_24h { get; set; default=true; }

    private Gtk.Label time_label;
    private Gtk.Label date_label;
    private uint timeout_id = 0U;

    private LoginManager login_manager;

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

        update_labels ();

        notify["is-24h"].connect (() => {
            GLib.Source.remove (timeout_id);
            update_labels ();
        });

        setup_for_sleep.begin ();
    }

    private async void setup_for_sleep () {
        try {
            login_manager = yield Bus.get_proxy (
                BusType.SYSTEM,
                "org.freedesktop.login1",
                "/org/freedesktop/login1"
            );

            login_manager.prepare_for_sleep.connect ((start) => {
                if (!start) {
                    GLib.Source.remove (timeout_id);
                    update_labels ();
                }
            });
        } catch (IOError e) {
            warning (e.message);
        }
    }

    private bool update_labels () {
        var now = new GLib.DateTime.now_local ();
        time_label.label = now.format (Granite.DateTime.get_default_time_format (!is_24h, false));
        date_label.label = now.format (Granite.DateTime.get_default_date_format (true, true, false));
        var delta = 60 - now.get_second ();
        timeout_id = GLib.Timeout.add_seconds (delta, update_labels);
        return GLib.Source.REMOVE;
    }
}
