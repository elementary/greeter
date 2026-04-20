/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2018-2025 elementary, Inc. (https://elementary.io)
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class Greeter.SessionButton : Gtk.Bin {
    public SessionButton (string action_group_prefix, Action select_session_action) {
        var menu = new GLib.Menu ();

        var iter = select_session_action.get_state_hint ().iterator ();
        GLib.Variant? val = null;
        string? key = null;
        while (iter.next ("{sv}", out key, out val)) {
            var action_name = "%s.%s".printf (action_group_prefix, select_session_action.name);
            menu.append (key, Action.print_detailed_name (action_name, val));
        }

        var menu_button = new Gtk.MenuButton () {
            child = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON),
            direction = DOWN,
            menu_model = menu
        };
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        child = menu_button;
    }
}
