[DBus (name = "org.freedesktop.login1.Manager")]
interface LoginManager : GLib.Object {
    public signal void prepare_for_sleep (bool start);
}

public class Greeter.DateTimeWidget : Gtk.Box {
    public bool is_24h { get; set; default=true; }

    private Gtk.Label time_label;
    private Gtk.Label date_label;
    private uint timeout_id = 0U;

    private LoginManager login_manager;

    construct {
        time_label = new Gtk.Label (null);
        time_label.add_css_class ("time");

        date_label = new Gtk.Label (null);
        date_label.add_css_class ("date");

        orientation = VERTICAL;
        append (time_label);
        append (date_label);

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
