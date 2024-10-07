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
    private unowned Gdk.Device device;

    private Gtk.Image caps_lock_image;
    private Gtk.Image num_lock_image;
    private Gtk.Label lock_label;

    construct {
        transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

        caps_lock_image = new Gtk.Image.from_icon_name ("input-keyboard-capslock-symbolic");
        caps_lock_image.use_fallback = true;
        caps_lock_image.visible = false;

        num_lock_image = new Gtk.Image.from_icon_name ("input-keyboard-numlock-symbolic");
        num_lock_image.use_fallback = true;
        num_lock_image.visible = false;

        lock_label = new Gtk.Label (null);
        lock_label.use_markup = true;

        var caps_lock_box = new Gtk.Box (HORIZONTAL, 3) {
            halign = CENTER
        };
        caps_lock_box.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        caps_lock_box.append (caps_lock_image);
        caps_lock_box.append (num_lock_image);
        caps_lock_box.append (lock_label);

        child = caps_lock_box;

        device = Gdk.Display.get_default ().get_default_seat ().get_devices (KEYBOARD)[0];
        device.changed.connect (update_visibility);

        update_visibility ();
    }

    private void update_visibility () {
        unowned string? label = null;
        var caps_lock = device.caps_lock_state;
        var num_lock = device.num_lock_state;

        reveal_child = caps_lock || num_lock;

        caps_lock_image.visible = caps_lock;
        num_lock_image.visible = num_lock;

        if (caps_lock && num_lock) {
            label = _("Caps Lock & Num Lock are on");
        } else if (caps_lock) {
            label = _("Caps Lock is on");
        } else if (num_lock) {
            label = _("Num Lock is on");
        }

        if (label == null) {
            lock_label.label = null;
        } else {
            lock_label.label = "<small>%s</small>".printf (GLib.Markup.escape_text (label, -1));
        }
    }
}
