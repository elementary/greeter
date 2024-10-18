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

public class Greeter.SessionButton : Gtk.MenuButton {
    construct {
        var menu = new GLib.Menu ();

        direction = DOWN;
        icon_name = "open-menu-symbolic";
        menu_model = menu;
        has_frame = false;

        var main_window = (Gtk.ApplicationWindow) get_ancestor (typeof (Gtk.ApplicationWindow));
        if (main_window != null) {
            var hint = main_window.get_action_state_hint ("select-session");
            var iter = hint.iterator ();
            GLib.Variant? val = null;
            string? key = null;
            while (iter.next ("{sv}", out key, out val)) {
                menu.append (key, Action.print_detailed_name ("win.select-session", val));
            }

            if (menu.get_n_items () == 0) {
                destroy ();
            }
        }
    }
}
