/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2018-2026 elementary, Inc. (https://elementary.io)
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public abstract class Greeter.BaseCard : Gtk.Bin {
    public signal void start_authentication (string username);
    public signal void provide_credential (string credential);
    public signal void go_left ();
    public signal void go_right ();

    protected const int ERROR_SHAKE_DURATION = 450;

    public bool connecting { get; set; default = false; }
    public bool need_password { get; set; default = false; }
    public bool use_fingerprint { get; set; default = false; }

    construct {
        halign = CENTER;
        valign = CENTER;
        width_request = 350;
    }

    public override bool focus (Gtk.DirectionType direction) {
        if (direction == LEFT) {
            go_left ();
            return Gdk.EVENT_STOP;
        } else if (direction == RIGHT) {
            go_right ();
            return Gdk.EVENT_STOP;
        }

        return base.focus (direction);
    }

    public virtual void on_selected () {}
    public virtual void on_deselected () {}

    public abstract void wrong_credentials ();
}
