/*
 * Copyright 2018-2024 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class Greeter.Application : Gtk.Application {
    private LightDM.Greeter lightdm_greeter;

    public Application () {
        Object (
            application_id: "io.elementary.greeter",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Constants.GETTEXT_PACKAGE);
        Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALE_DIR);
    }

    protected override void startup () {
        base.startup ();

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/greeter/Application.css");

        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        GLib.Bus.own_name (
            SESSION,
            "org.freedesktop.portal.Desktop",
            NONE,
            (connection, name) => {
                try {
                    connection.register_object ("/org/freedesktop/portal/desktop", SettingsPortal.get_default ());
                } catch (Error e) {
                    critical ("Unable to register the object: %s", e.message);
                }
            },
            () => debug ("org.freedesktop.portal.Desktop acquired"),
            () => debug ("org.freedesktop.portal.Desktop lost")
        );

        unowned var gtk_settings = Gtk.Settings.get_default ();
        unowned var settings_portal = SettingsPortal.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = settings_portal.prefers_color_scheme == 1;

        settings_portal.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = settings_portal.prefers_color_scheme == 1;
        });

        var settings = new GLib.Settings ("io.elementary.greeter");

        lightdm_greeter = new LightDM.Greeter ();
        try {
            lightdm_greeter.connect_to_daemon_sync ();
        } catch (Error e) {
            critical ("LightDM couldn't connect to daemon: %s", e.message);
        }

        unowned var sessions = LightDM.get_sessions ();

        var selected_session = "";
        if (settings.get_string ("last-session-type") != "") {
            selected_session = settings.get_string ("last-session-type");
        } else if (lightdm_greeter.default_session_hint != null) {
            selected_session = lightdm_greeter.default_session_hint;
        } else if (sessions.length () > 0) {
            selected_session = sessions.first ().data.key;
        }

        var select_session_action = new GLib.SimpleAction.stateful ("select-session", GLib.VariantType.STRING, selected_session);
        var vardict = new GLib.VariantDict ();
        var has_pantheon_x11_session = false;
        sessions.foreach ((session) => {
            vardict.insert_value (session.name, new GLib.Variant.string (session.key));
            if (session.key == "pantheon") {
                has_pantheon_x11_session = true;
            }
        });
        select_session_action.set_state_hint (vardict.end ());

        select_session_action.activate.connect ((param) => {
            if (!select_session_action.get_state ().equal (param)) {
                select_session_action.set_state (param);
            }
        });

        add_action (select_session_action);

        var a11y_settings = new GLib.Settings ("org.gnome.desktop.a11y.applications");
        a11y_settings.changed.connect ((key) => {
            if (key != "screen-keyboard-enabled" && key != "screen-reader-enabled") {
                return;
            }

            if (!a11y_settings.get_boolean (key)) {
                return;
            }

            if (select_session_action.get_state ().get_string () != "pantheon-wayland") {
                return;
            }

            if (!has_pantheon_x11_session) {
                return;
            }

            select_session_action.set_state (new Variant.string ("pantheon"));

            var notification = new Notification (_("Classic session automatically selected"));
            notification.set_body (_("Accessibility features may be unavailable in the Secure session"));
            notification.set_icon (new ThemedIcon ("preferences-desktop-accessibility"));

            send_notification ("session-type", notification);
        });
    }

    public override void activate () {
        add_window (new Greeter.MainWindow (lightdm_greeter));
        active_window.show_all ();
        active_window.present ();
    }

    public static int main (string[] args) {
        return new Greeter.Application ().run (args);
    }
}
