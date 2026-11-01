/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2018-2026 elementary, Inc. (https://elementary.io)
 */

public class Greeter.CapsLockRevealer : Granite.Bin {
    private Gtk.Image caps_lock_image;
    private Gtk.Image num_lock_image;
    private Gtk.Label lock_label;
    private Gtk.Revealer revealer;
    private DesktopIntegration desktop_integration;

    construct {
        try {
            desktop_integration = Bus.get_proxy_sync (BusType.SESSION , "org.pantheon.gala", "/org/pantheon/gala/DesktopInterface");
            desktop_integration.caps_lock_state_changed.connect (() => update_visibility.begin ());
            desktop_integration.num_lock_state_changed.connect (() => update_visibility.begin ());
        } catch (Error e) {
            warning ("Couldn't connect to DesktopIntegration interface: %s", e.message);
        }

        caps_lock_image = new Gtk.Image.from_icon_name ("input-keyboard-capslock-symbolic");
        num_lock_image = new Gtk.Image.from_icon_name ("input-keyboard-numlock-symbolic");

        lock_label = new Gtk.Label (null);
        lock_label.add_css_class (Granite.CssClass.SMALL);

        var caps_lock_box = new Gtk.Box (HORIZONTAL, 3) {
            halign = CENTER
        };
        caps_lock_box.add_css_class (Granite.CssClass.DIM);
        caps_lock_box.append (caps_lock_image);
        caps_lock_box.append (num_lock_image);
        caps_lock_box.append (lock_label);

        revealer = new Gtk.Revealer () {
            child = caps_lock_box,
            transition_type = SLIDE_DOWN
        };

        child = revealer;

        update_visibility.begin ();
    }

    private async void update_visibility () {
        bool caps_lock = false, num_lock = false;

        if (desktop_integration != null) {
            try {
                caps_lock = yield desktop_integration.get_caps_lock_state ();
                num_lock = yield desktop_integration.get_num_lock_state ();
            } catch (Error e) {
                warning ("Couldn't get toggle keys state: %s", e.message);
                return;
            }
        }

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
