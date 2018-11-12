public class Greeter.DateTimeWidget : Gtk.Grid {
    private const string STYLESHEET = """
    .time {
        color: #fff;
        text-shadow:
            0 0 2px alpha (#000, 0.3),
            0 1px 2px alpha (#000, 0.6);
        font-size: 72px;
    }

    .date {
        color: #fff;
        text-shadow:
            0 0 2px alpha (#000, 0.3),
            0 1px 2px alpha (#000, 0.6);
        font-size: 24px;
    }""";

    Gtk.Label time_label;
    Gtk.Label date_label;
    construct {
        orientation = Gtk.Orientation.VERTICAL;
        time_label = new Gtk.Label (null);
        time_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        time_label.get_style_context ().add_class ("time");
        date_label = new Gtk.Label (null);
        date_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        date_label.get_style_context ().add_class ("date");

        var css_provider = new Gtk.CssProvider ();
        try {
            css_provider.load_from_data (STYLESHEET, -1);
            time_label.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            date_label.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {}
        add (time_label);
        add (date_label);

        update_time ();
        update_date ();
    }

    private bool update_time () {
        var now = new GLib.DateTime.now_local ();
        time_label.label = now.format (Granite.DateTime.get_default_time_format (true, false));
        var delta = 60 - now.get_second ();
        GLib.Timeout.add_seconds (delta, update_time);
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
