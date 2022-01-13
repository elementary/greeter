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

public class Greeter.SessionButton : Gtk.Widget {
    construct {
        var settings_list = new Gtk.ListBox () {
            margin_bottom = 3,
            margin_top = 3
        };
        // settings_list.set_sort_func ((row1, row2) => {
        //     var child1 = (Gtk.ModelButton) row1.get_child ();
        //     var child2 = (Gtk.ModelButton) row2.get_child ();

        //     return child1.text.collate (child2.text);
        // });

        var settings_popover = new Gtk.Popover () {
            child = settings_list,
            position = Gtk.PositionType.BOTTOM
        };

        var menu_button = new Gtk.MenuButton () {
            direction = Gtk.ArrowType.DOWN,
            icon_name = "open-menu-symbolic",
            popover = settings_popover
        };
        menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        menu_button.set_parent (this);

        // // The session action is on the MainWindow toplevel, wait until it is accessible.
        // hierarchy_changed.connect ((previous_toplevel) => {
        //     var main_window = get_ancestor (typeof (Greeter.MainWindow));
        //     if (main_window != null) {
        //         var session_action_group = main_window.get_action_group ("session");
        //         var hint = session_action_group.get_action_state_hint ("select");
        //         var iter = hint.iterator ();
        //         GLib.Variant? val = null;
        //         string? key = null;
        //         while (iter.next ("{sv}", out key, out val)) {
        //             var radio = new Gtk.ModelButton () {
        //                 text = key
        //             };
        //             radio.set_detailed_action_name (Action.print_detailed_name ("session.select", val));

        //             settings_list.add (radio);
        //         }

        //         if (settings_list.get_row_at_index (1) == null) {
        //             destroy ();
        //         } else {
        //             settings_list.show_all ();
        //             settings_list.invalidate_sort ();
        //         }
        //     }
        // });
    }
}
