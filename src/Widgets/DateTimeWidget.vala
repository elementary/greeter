/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class Greeter.DateTimeWidget : Gtk.Box {
    [DBus (name = "org.freedesktop.login1.Manager")]
    private interface LoginManager : GLib.Object {
        public signal void prepare_for_sleep (bool about_to_suspend);
    }

    private bool _is_24h = true;
    public bool is_24h {
        private get {
            return _is_24h;
        }
        set {
            _is_24h = value;
            update_labels ();
        }
    }

    private Gtk.Label time_label;
    private Gtk.Label date_label;
    private uint timeout_id = 0;
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

        setup_for_sleep.begin ();
    }

    private async void setup_for_sleep () {
        try {
            login_manager = yield Bus.get_proxy (
                SYSTEM,
                "org.freedesktop.login1",
                "/org/freedesktop/login1"
            );

            login_manager.prepare_for_sleep.connect ((about_to_suspend) => {
                if (!about_to_suspend) {
                    update_labels ();
                }
            });
        } catch (IOError e) {
            warning (e.message);
        }
    }

    private bool update_labels () {
        if (timeout_id != 0) {
            GLib.Source.remove (timeout_id);
        }

        var now = new GLib.DateTime.now_local ();

        time_label.label = now.format (Granite.DateTime.get_default_time_format (!is_24h, false));
        date_label.label = now.format (Granite.DateTime.get_default_date_format (true, true, false));

        timeout_id = GLib.Timeout.add_seconds (60 - now.get_second (), update_labels);

        return GLib.Source.REMOVE;
    }
}
