/*
 * Copyright 2018 elementary, Inc. (https://elementary.io)
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

public int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (Constants.GETTEXT_PACKAGE);
    Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALE_DIR);

    // Ensure we present ourselves as Pantheon so we pick up the right GSettings
    // overrides
    GLib.Environment.set_variable ("XDG_CURRENT_DESKTOP", "Pantheon", true);

    var settings_daemon = new Greeter.SettingsDaemon ();
    settings_daemon.start ();

    Greeter.SubprocessSupervisor compositor;

    try {
        compositor = new Greeter.SubprocessSupervisor ({"io.elementary.greeter-compositor"});
    } catch (Error e) {
        critical (e.message);
    }

    Gtk.init (ref args);

    var window = new Greeter.MainWindow ();
    window.show_all ();

    Gtk.main ();

    return 0;
}
