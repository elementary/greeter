/*
 * Copyright 2018-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

public class Greeter.ManualCard : Greeter.BaseCard {
    public signal void do_connect_username (string username);

    private Greeter.PasswordEntry password_entry;
    private Gtk.Entry username_entry;

    construct {
        var label = new Gtk.Label (_("Manual Login")) {
            hexpand = true,
            margin_bottom = 16
        };
        label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        username_entry = new Gtk.Entry () {
            hexpand = true,
            input_purpose = FREE_FORM,
            placeholder_text = _("Username"),
            primary_icon_name = "avatar-default-symbolic"
        };

        password_entry = new Greeter.PasswordEntry ();

        var caps_lock_revealer = new Greeter.CapsLockRevealer ();

        var session_button = new Greeter.SessionButton ();

        var form_grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 12,
            margin_top = 24,
            margin_bottom = 24,
            margin_start = 24,
            margin_end = 24
        };
        form_grid.attach (label, 0, 0, 2);
        form_grid.attach (username_entry, 0, 1);
        form_grid.attach (password_entry, 0, 2);
        form_grid.attach (session_button, 1, 1, 1, 2);
        form_grid.attach (caps_lock_revealer, 0, 3, 2);

        main_box.add (form_grid);

        bind_property ("connecting", username_entry, "sensitive", INVERT_BOOLEAN);
        bind_property ("connecting", password_entry, "sensitive", INVERT_BOOLEAN);

        username_entry.focus_out_event.connect (() => {
            if (username_entry.text != "") {
                do_connect_username (username_entry.text);
            }
        });

        password_entry.activate.connect (on_login);
    }

    private void on_login () {
        if (connecting) {
            return;
        }

        connecting = true;
        do_connect (password_entry.text);
    }

    public override void wrong_credentials () {
        password_entry.text = "";

        username_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);
        password_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);
        main_box.get_style_context ().add_class ("shake");

        Timeout.add (ERROR_SHAKE_DURATION, () => {
            username_entry.get_style_context ().remove_class (Gtk.STYLE_CLASS_ERROR);
            password_entry.get_style_context ().remove_class (Gtk.STYLE_CLASS_ERROR);
            main_box.get_style_context ().remove_class ("shake");

            connecting = false;
            username_entry.grab_focus_without_selecting ();
            return Source.REMOVE;
        });
    }

    public void ask_password () {
        password_entry.grab_focus_without_selecting ();
    }

    public void wrong_username () {
        username_entry.grab_focus_without_selecting ();
        username_entry.text = "";

        username_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);
        main_box.get_style_context ().add_class ("shake");

        Timeout.add (ERROR_SHAKE_DURATION, () => {
            username_entry.get_style_context ().remove_class (Gtk.STYLE_CLASS_ERROR);
            main_box.get_style_context ().remove_class ("shake");

            return Source.REMOVE;
        });
    }

    public override BackgroundImage load_background_image () {
        return new BackgroundImage.from_path (null);
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
