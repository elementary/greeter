/*
 * Copyright 2018-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

public class Greeter.ManualCard : Greeter.BaseCard {
    public signal void do_connect_username (string username);

    private Greeter.PasswordEntry password_entry;
    private Gtk.Entry username_entry;
    private Gtk.Box main_box;

    construct {
        width_request = 350;

        var icon = new Gtk.Image () {
            icon_name = "avatar-default",
            pixel_size = 64
        };

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

        var password_box = new Gtk.Box (VERTICAL, 6);
        password_box.add (password_entry);
        password_box.add (caps_lock_revealer);

        var session_button = new Greeter.SessionButton ();

        var form_grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 12,
            margin_top = 24,
            margin_bottom = 24,
            margin_start = 24,
            margin_end = 24
        };
        form_grid.attach (icon, 0, 0, 2);
        form_grid.attach (label, 0, 1, 2);
        form_grid.attach (username_entry, 0, 2);
        form_grid.attach (password_box, 0, 3);
        form_grid.attach (session_button, 1, 2, 1, 2);

        main_box = new Gtk.Box (VERTICAL, 0) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };
        main_box.add (form_grid);

        unowned var main_grid_style_context = main_box.get_style_context ();
        main_grid_style_context.add_class (Granite.STYLE_CLASS_CARD);
        main_grid_style_context.add_class (Granite.STYLE_CLASS_ROUNDED);

        child = main_box;

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

        unowned var username_entry_style_context = username_entry.get_style_context ();
        username_entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);

        unowned var password_entry_style_context = password_entry.get_style_context ();
        password_entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);

        unowned var grid_style_context = main_box.get_style_context ();
        grid_style_context.add_class ("shake");

        Timeout.add (ERROR_SHAKE_DURATION, () => {
            grid_style_context.remove_class ("shake");
            username_entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);
            password_entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);

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

        unowned var entry_style_context = username_entry.get_style_context ();
        entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);

        unowned var grid_style_context = main_box.get_style_context ();
        grid_style_context.add_class ("shake");

        Timeout.add (ERROR_SHAKE_DURATION, () => {
            grid_style_context.remove_class ("shake");
            entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);

            return Source.REMOVE;
        });
    }
}
