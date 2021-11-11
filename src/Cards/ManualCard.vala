/*
 * Copyright 2018–2021 elementary, Inc. (https://elementary.io)
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

public class Greeter.ManualCard : Greeter.BaseCard {
    public signal void do_connect_username (string username);

    private Greeter.PasswordEntry password_entry;
    private Gtk.Entry username_entry;
    private Gtk.Grid main_grid;

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
            input_purpose = Gtk.InputPurpose.FREE_FORM,
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

        var password_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            row_spacing = 6
        };
        password_grid.add (password_entry);
        password_grid.add (caps_lock_revealer);

        var session_button = new Greeter.SessionButton ();

        var form_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 24,
            row_spacing = 12
        };
        form_grid.attach (icon, 0, 0, 2);
        form_grid.attach (label, 0, 1, 2);
        form_grid.attach (username_entry, 0, 2);
        form_grid.attach (password_grid, 0, 3);
        form_grid.attach (session_button, 1, 2, 1, 2);

        main_grid = new Gtk.Grid () {
            margin = 12
        };
        main_grid.add (form_grid);

        weak Gtk.StyleContext main_grid_style_context = main_grid.get_style_context ();
        main_grid_style_context.add_class (Granite.STYLE_CLASS_CARD);
        main_grid_style_context.add_class (Granite.STYLE_CLASS_ROUNDED);
        main_grid_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        add (main_grid);

        bind_property ("connecting", username_entry, "sensitive", GLib.BindingFlags.INVERT_BOOLEAN);
        bind_property ("connecting", password_entry, "sensitive", GLib.BindingFlags.INVERT_BOOLEAN);

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
        if(connecting)
            return;
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

        weak Gtk.StyleContext username_entry_style_context = username_entry.get_style_context ();
        username_entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);

        weak Gtk.StyleContext password_entry_style_context = password_entry.get_style_context ();
        password_entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);

        weak Gtk.StyleContext grid_style_context = main_grid.get_style_context ();
        grid_style_context.add_class ("shake");

        GLib.Timeout.add (ERROR_SHAKE_DURATION, () => {
            grid_style_context.remove_class ("shake");
            username_entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);
            password_entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);

            connecting = false;
            focus_username_entry ();
            return GLib.Source.REMOVE;
        });
    }

    public void ask_password () {
        focus_password_entry ();
    }

    public void wrong_username () {
        username_entry.grab_focus_without_selecting ();
        username_entry.secondary_icon_name = "";
        username_entry.text = "";

        weak Gtk.StyleContext entry_style_context = username_entry.get_style_context ();
        entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);

        weak Gtk.StyleContext grid_style_context = main_grid.get_style_context ();
        grid_style_context.add_class ("shake");

        GLib.Timeout.add (ERROR_SHAKE_DURATION, () => {
            grid_style_context.remove_class ("shake");
            entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);

            return GLib.Source.REMOVE;
        });
    }
}
