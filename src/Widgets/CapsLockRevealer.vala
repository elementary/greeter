/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2018-2025 elementary, Inc. (https://elementary.io)
 */

public class Greeter.CapsLockRevealer : Gtk.Bin {
    private Gtk.Image caps_lock_image;
    private Gtk.Image num_lock_image;
    private Gtk.Label lock_label;
    private Gtk.Revealer revealer;

    construct {
        caps_lock_image = new Gtk.Image.from_icon_name ("input-keyboard-capslock-symbolic", MENU);
        num_lock_image = new Gtk.Image.from_icon_name ("input-keyboard-numlock-symbolic", MENU);

        lock_label = new Gtk.Label (null);
        lock_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var caps_lock_box = new Gtk.Box (HORIZONTAL, 3) {
            halign = CENTER
        };
        caps_lock_box.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        caps_lock_box.add (caps_lock_image);
        caps_lock_box.add (num_lock_image);
        caps_lock_box.add (lock_label);

        revealer = new Gtk.Revealer () {
            child = caps_lock_box,
            transition_type = SLIDE_DOWN
        };

        child = revealer;

        var keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());
        keymap.state_changed.connect (update_visibility);

        update_visibility (keymap);
    }

    private void update_visibility (Gdk.Keymap keymap) {
        var caps_lock = keymap.get_caps_lock_state ();
        var num_lock = keymap.get_num_lock_state ();

        revealer.reveal_child = caps_lock || num_lock;

        caps_lock_image.no_show_all = !caps_lock;
        num_lock_image.no_show_all = !num_lock;
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
