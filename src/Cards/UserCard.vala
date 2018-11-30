/*
 * Copyright 2018 elementary, Inc. (https://elementary.io)
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
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class Greeter.UserCard : Greeter.BaseCard {
    public signal void go_left ();
    public signal void go_right ();
    public signal void focus_requested ();

    public LightDM.User lightdm_user { get; construct; }
    public bool show_input { get; set; default = false; }
    public double reveal_ratio { get; private set; default = 0.0; }

    private Gtk.Revealer form_revealer;
    private weak Gtk.StyleContext main_grid_style_context;
    private Greeter.PasswordEntry password_entry;

    construct {
        need_password = true;

        var username_label = new Gtk.Label (lightdm_user.display_name);
        username_label.margin = 24;
        username_label.hexpand = true;
        username_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        password_entry = new Greeter.PasswordEntry ();

        this.bind_property ("connecting", password_entry, "sensitive", GLib.BindingFlags.INVERT_BOOLEAN);
        var fingerprint_image = new Gtk.Image.from_icon_name ("fingerprint-symbolic", Gtk.IconSize.BUTTON);
        this.bind_property ("use-fingerprint", fingerprint_image, "no-show-all", GLib.BindingFlags.INVERT_BOOLEAN|GLib.BindingFlags.SYNC_CREATE);
        this.bind_property ("use-fingerprint", fingerprint_image, "visible", GLib.BindingFlags.SYNC_CREATE);
        var session_button = new Greeter.SessionButton ();

        var caps_lock_revealer = new Greeter.CapsLockRevealer ();
        var num_lock_revealer = new Greeter.NumLockRevealer ();

        var password_grid = new Gtk.Grid ();
        password_grid.column_spacing = 6;
        password_grid.row_spacing = 6;
        password_grid.attach (password_entry, 0, 0);
        password_grid.attach (fingerprint_image, 1, 0);
        password_grid.attach (caps_lock_revealer, 0, 1, 2, 1);
        password_grid.attach (num_lock_revealer, 0, 1, 2, 1);

        var login_button = new Gtk.Button.with_label (_("Log In"));
        this.bind_property ("connecting", login_button, "sensitive", GLib.BindingFlags.INVERT_BOOLEAN);
        login_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var login_stack = new Gtk.Stack ();
        login_stack.add_named (password_grid, "password");
        login_stack.add_named (login_button, "button");

        var form_grid = new Gtk.Grid ();
        form_grid.column_spacing = 6;
        form_grid.row_spacing = 12;
        form_grid.margin = 24;
        form_grid.margin_top = 0;
        form_grid.attach (login_stack, 0, 1, 1, 1);
        form_grid.attach (session_button, 1, 1, 1, 1);

        form_revealer = new Gtk.Revealer ();
        form_revealer.reveal_child = true;
        form_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        form_revealer.add (form_grid);
        bind_property ("show-input", form_revealer, "reveal-child", GLib.BindingFlags.SYNC_CREATE);

        var background_path = lightdm_user.background;

        if (background_path == null) {
            try {
                string path = GLib.Path.build_filename ("/", "var", "lib", "lightdm-data", lightdm_user.name, "wallpaper");
                var background_directory = GLib.File.new_for_path (path);
                var enumerator = background_directory.enumerate_children (GLib.FileAttribute.STANDARD_NAME, GLib.FileQueryInfoFlags.NONE);

                GLib.FileInfo file_info;
                while ((file_info = enumerator.next_file ()) != null) {
                    if (file_info.get_file_type () == GLib.FileType.REGULAR) {
                        background_path = Path.build_filename (path, file_info.get_name ());
                        break;
                    }
                }
            } catch (Error e) {
                critical (e.message);
            }
        }

        var background_image = new Greeter.BackgroundImage (background_path);

        var main_grid = new Gtk.Grid ();
        main_grid.margin_bottom = 48;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (background_image);
        main_grid.add (username_label);
        main_grid.add (form_revealer);

        main_grid_style_context = main_grid.get_style_context ();
        main_grid_style_context.add_class (Granite.STYLE_CLASS_CARD);
        main_grid_style_context.add_class ("rounded");
        main_grid_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        update_collapsed_class ();

        Granite.Widgets.Avatar avatar;
        if (lightdm_user.image != null) {
            avatar = new Granite.Widgets.Avatar.from_file (lightdm_user.image, 64);
        } else {
            avatar = new Granite.Widgets.Avatar.with_default_icon (64);
        }

        var avatar_overlay = new Gtk.Overlay ();
        avatar_overlay.valign = Gtk.Align.START;
        avatar_overlay.halign = Gtk.Align.CENTER;
        avatar_overlay.margin_top = 100;
        avatar_overlay.add (avatar);

        if (lightdm_user.logged_in) {
            var logged_in = new Gtk.Image.from_icon_name ("selection-checked", Gtk.IconSize.LARGE_TOOLBAR);
            logged_in.halign = logged_in.valign = Gtk.Align.END;

            avatar_overlay.add_overlay (logged_in);
        }

        var card_overlay = new Gtk.Overlay ();
        card_overlay.margin = 12;
        card_overlay.add (main_grid);
        card_overlay.add_overlay (avatar_overlay);

        add (card_overlay);

        card_overlay.focus.connect ((direction) => {
            if (direction == Gtk.DirectionType.LEFT) {
                go_left ();
                return true;
            } else if (direction == Gtk.DirectionType.RIGHT) {
                go_right ();
                return true;
            }

            return false;
        });

        card_overlay.button_release_event.connect ((event) => {
            if (!show_input) {
                focus_requested ();
                password_entry.grab_focus ();
            }

            return false;
        });

        // This makes all the animations synchonous
        form_revealer.size_allocate.connect ((alloc) => {
            var total_height = form_grid.get_allocated_height () + form_grid.margin_top + form_grid.margin_bottom;
            reveal_ratio = (double)alloc.height/(double)total_height;
        });

        form_revealer.notify["child-revealed"].connect (() => {
            update_collapsed_class ();
        });

        notify["child-revealed"].connect (() => {
            reveal_ratio = child_revealed ? 1.0 : 0.0;
        });

        password_entry.activate.connect (on_login);
        login_button.clicked.connect (on_login);

        notify["need-password"].connect (() => {
            if (need_password) {
                login_stack.visible_child = password_grid;
            } else {
                login_stack.visible_child = login_button;
            }
        });

        grab_focus.connect (() => {
            password_entry.grab_focus_without_selecting ();
        });
    }

    private void on_login () {
        connecting = true;
        if (need_password) {
            do_connect (password_entry.text);
        } else {
            do_connect ();
        }

        password_entry.text = "";
    }

    private void update_collapsed_class () {
        if (form_revealer.child_revealed) {
            main_grid_style_context.remove_class ("collapsed");
        } else {
            main_grid_style_context.add_class ("collapsed");
        }
    }

    public UserCard (LightDM.User lightdm_user) {
        Object (lightdm_user: lightdm_user);
    }

    public override void wrong_credentials () {
        weak Gtk.StyleContext entry_style_context = password_entry.get_style_context ();
        entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);
        main_grid_style_context.add_class ("shake");
        GLib.Timeout.add (450, () => {
            main_grid_style_context.remove_class ("shake");
            entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);
            return GLib.Source.REMOVE;
        });
    }
}
