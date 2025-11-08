/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2018-2025 elementary, Inc. (https://elementary.io)
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public abstract class Greeter.BaseCard : Gtk.Bin {
    public signal void do_connect (string? credential);

    protected const int ERROR_SHAKE_DURATION = 450;

    public bool connecting { get; set; default = false; }
    public bool use_fingerprint { get; set; default = false; }

    protected Gtk.Box main_box { get; private set; }

    construct {
        main_box = new Gtk.Box (VERTICAL, 0) {
            margin_bottom = 48
        };
        main_box.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        main_box.get_style_context ().add_class (Granite.STYLE_CLASS_ROUNDED);
        main_box.add (load_background_image ());

        var overlay = new Gtk.Overlay () {
            child = main_box,
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };

        overlay.add_overlay (get_avatar_widget ());

        child = overlay;
        halign = CENTER;
        valign = CENTER;
        width_request = 350;
    }

    public abstract void wrong_credentials ();
    public abstract BackgroundImage load_background_image ();
    public abstract Gtk.Widget get_avatar_widget ();
    public abstract void reveal_card_content ();
    public abstract void hide_card_content ();
}
