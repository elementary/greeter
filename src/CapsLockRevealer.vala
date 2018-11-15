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
 */

public class Greeter.CapsLockRevealer : Gtk.Revealer {
    construct {
        transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

        var caps_lock_image = new Gtk.Image.from_icon_name ("input-keyboard-capslock-symbolic", Gtk.IconSize.MENU);
        caps_lock_image.use_fallback = true;

        var caps_lock_label = new Gtk.Label ("<small>%s</small>".printf (_("Caps Lock is on")));
        caps_lock_label.use_markup = true;

        var caps_lock_grid = new Gtk.Grid ();
        caps_lock_grid.column_spacing = 3;
        caps_lock_grid.halign = Gtk.Align.CENTER;
        caps_lock_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        caps_lock_grid.add (caps_lock_image);
        caps_lock_grid.add (caps_lock_label);

        add (caps_lock_grid);

        var keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());
        keymap.state_changed.connect (() => {
            reveal_child = keymap.get_caps_lock_state ();
        });
    }
}
