/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2018-2025 elementary, Inc. (https://elementary.io)
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class Greeter.SessionButton : Granite.Bin {
    construct {
        var menu = new GLib.Menu ();
        unowned var application = (Gtk.Application) GLib.Application.get_default ();
        var hint = application.get_action_state_hint ("select-session");
        var iter = hint.iterator ();
        GLib.Variant? val = null;
        string? key = null;
        while (iter.next ("{sv}", out key, out val)) {
            menu.append (key, Action.print_detailed_name ("app.select-session", val));
        }

        var menu_button = new Gtk.MenuButton () {
            direction = DOWN,
            has_frame = false,
            icon_name = "open-menu-symbolic",
            menu_model = menu
        };

        child = menu_button;
    }
}
