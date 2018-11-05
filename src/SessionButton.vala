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
        direction = Gtk.ArrowType.DOWN;
        menu_model = new GLib.Menu ();
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        // The session action is on the MainWindow toplevel, wait until it is accessible.
        hierarchy_changed.connect ((previous_toplevel) => {
            var main_window = get_ancestor (typeof (Greeter.MainWindow));
            if (main_window != null) {
                var session_action_group = main_window.get_action_group ("session");
                var hint = session_action_group.get_action_state_hint ("select");
                var iter = hint.iterator ();
                GLib.Variant? val = null;
                string? key = null;
                while (iter.next ("{sv}", out key, out val)) {
                    var shell_menuitem = new GLib.MenuItem (key, GLib.Action.print_detailed_name ("session.select", val));
                    ((GLib.Menu) menu_model).append_item (shell_menuitem);
                }

                if (menu_model.get_n_items () < 2) {
                    destroy ();
                }
            }
        });

        var cog_image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON);
        add (cog_image);
    }
}
