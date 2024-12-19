/*
 * Copyright 2018-2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

public class Greeter.CapsLockRevealer : Adw.Bin {
    private unowned Gdk.Device device;

    private Gtk.Image caps_lock_image;
    private Gtk.Image num_lock_image;
    private Gtk.Label lock_label;
    private Gtk.Revealer revealer;

    construct {
        caps_lock_image = new Gtk.Image.from_icon_name ("input-keyboard-capslock-symbolic") {
            use_fallback = true,
            visible = false
        };

        num_lock_image = new Gtk.Image.from_icon_name ("input-keyboard-numlock-symbolic") {
            use_fallback = true,
            visible = false
        };

        lock_label = new Gtk.Label (null);
        lock_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var caps_lock_box = new Gtk.Box (HORIZONTAL, 3) {
            halign = CENTER
        };
        caps_lock_box.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        caps_lock_box.append (caps_lock_image);
        caps_lock_box.append (num_lock_image);
        caps_lock_box.append (lock_label);

        revealer = new Gtk.Revealer () {
            child = caps_lock_box,
            transition_type = SLIDE_DOWN
        };

        child = revealer;

        device = Gdk.Display.get_default ().get_default_seat ().get_keyboard ();
        device.changed.connect (update_visibility);

        update_visibility ();
    }

    private void update_visibility () {
        var caps_lock = device.caps_lock_state;
        var num_lock = device.num_lock_state;

        revealer.reveal_child = caps_lock || num_lock;

        caps_lock_image.visible = caps_lock;
        num_lock_image.visible = num_lock;

        if (caps_lock && num_lock) {
            lock_label.label = _("Caps Lock & Num Lock are on");
        } else if (caps_lock) {
            lock_label.label = _("Caps Lock is on");
        } else if (num_lock) {
            lock_label.label = _("Num Lock is on");
        } else {
            lock_label.label = null;
        }
    }
}
