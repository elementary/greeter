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
            primary_icon_name = "avatar-default-symbolic",
            secondary_icon_name = "go-jump-symbolic",
            secondary_icon_tooltip_text = _("Try username")
        };

        password_entry = new Greeter.PasswordEntry () {
            secondary_icon_name = "",
            sensitive = false
        };

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
        form_grid.attach (icon, 0, 0, 2);
        form_grid.attach (label, 0, 1, 2);
        form_grid.attach (username_entry, 0, 2);
        form_grid.attach (password_entry, 0, 3);
        form_grid.attach (session_button, 1, 2, 1, 2);
        form_grid.attach (caps_lock_revealer, 0, 4, 2);

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

        username_entry.activate.connect (() => do_connect_username (username_entry.text));
        password_entry.activate.connect (on_login);
        grab_focus.connect (() => {
            if (username_entry.sensitive) {
                username_entry.grab_focus_without_selecting ();
            } else {
                password_entry.grab_focus_without_selecting ();
            }
        });
    }

    private void on_login () {
        if (connecting) {
            return;
        }

        connecting = true;
        do_connect (password_entry.text);
        password_entry.sensitive = false;
    }

    private void focus_username_entry () {
        password_entry.secondary_icon_name = "";
        password_entry.sensitive = false;

        username_entry.secondary_icon_name = "go-jump-symbolic";
        username_entry.sensitive = true;
        username_entry.grab_focus_without_selecting ();
    }

    private void focus_password_entry () {
        username_entry.secondary_icon_name = "";
        username_entry.sensitive = false;

        password_entry.secondary_icon_name = "go-jump-symbolic";
        password_entry.sensitive = true;
        password_entry.grab_focus_without_selecting ();
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
            focus_username_entry ();
            return Source.REMOVE;
        });
    }

    public void ask_password () {
        focus_password_entry ();
    }

    public void wrong_username () {
        username_entry.grab_focus_without_selecting ();
        username_entry.secondary_icon_name = "";
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
