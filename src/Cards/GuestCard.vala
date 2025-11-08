/*
 * Copyright 2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Greeter.GuestCard : BaseCard {
    construct {
        var label = new Gtk.Label (_("Guest")) {
            hexpand = true,
            margin_bottom = 16
        };
        label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var login_button = new Gtk.Button.with_label (_("Login")) {
            halign = END
        };
        login_button.get_style_context ().add_class (Granite.STYLE_CLASS_ACCENT);

        main_box.add (label);
        main_box.add (login_button);
        
        login_button.clicked.connect (() => do_connect (null));
    }

    public override void wrong_credentials () {}

    public override BackgroundImage load_background_image () {
        return new Greeter.BackgroundImage.from_path (null);
    }

    public override Gtk.Widget get_avatar_widget () {
        return new Gtk.Image () {
            icon_name = "avatar-default",
            pixel_size = 64
        };
    }

    public override void reveal_card_content () {}

    public override void hide_card_content () {}
}
