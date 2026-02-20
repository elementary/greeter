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
    public unowned string default_session_type {
        get {
            if (lightdm_greeter.default_session_hint != null) {
                return lightdm_greeter.default_session_hint;
            }

            unowned var sessions = LightDM.get_sessions ();
            if (sessions.length () > 0) {
                sessions.first ().data.key;
            }

            return "";
        }
    }

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

        lightdm_greeter = new LightDM.Greeter ();
        try {
            lightdm_greeter.connect_to_daemon_sync ();
        } catch (Error e) {
            critical ("LightDM couldn't connect to daemon: %s", e.message);
        }
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
