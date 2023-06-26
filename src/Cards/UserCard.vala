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
    public bool is_24h { get; set; default = true; }

    public int prefers_accent_color { get; set; default = 6; }
    public int sleep_inactive_ac_timeout { get; set; default = 1200; }
    public int sleep_inactive_ac_type { get; set; default = 1; }
    public int sleep_inactive_battery_timeout { get; set; default = 1200; }
    public int sleep_inactive_battery_type { get; set; default = 1; }

    private Act.User act_user;
    private Pantheon.AccountsService greeter_act;
    private Pantheon.SettingsDaemon.AccountsService settings_act;
    private Gtk.Revealer form_revealer;
    private Gtk.Stack login_stack;
    private Greeter.PasswordEntry password_entry;

    private SelectionCheck logged_in;
    private unowned Gtk.StyleContext logged_in_context;
    private weak Gtk.StyleContext main_grid_style_context;
    private weak Gtk.StyleContext password_entry_context;

    private bool needs_settings_set = false;

    construct {
        need_password = true;

        var username_label = new Gtk.Label (lightdm_user.display_name) {
            hexpand = true,
            margin = 24,
            margin_bottom = 12
        };

        unowned var username_label_context = username_label.get_style_context ();
        username_label_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
        username_label_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        password_entry = new Greeter.PasswordEntry ();
        password_entry_context = password_entry.get_style_context ();

        bind_property (
            "connecting",
            password_entry,
            "sensitive",
            GLib.BindingFlags.INVERT_BOOLEAN
        );

        var fingerprint_image = new Gtk.Image.from_icon_name (
            "fingerprint-symbolic",
            Gtk.IconSize.BUTTON
        );

        bind_property (
            "use-fingerprint",
            fingerprint_image,
            "no-show-all",
            GLib.BindingFlags.INVERT_BOOLEAN | GLib.BindingFlags.SYNC_CREATE
        );

        bind_property (
            "use-fingerprint",
            fingerprint_image,
            "visible",
            GLib.BindingFlags.SYNC_CREATE
        );

        var session_button = new Greeter.SessionButton () {
            valign = Gtk.Align.START
        };

        var caps_lock_revealer = new Greeter.CapsLockRevealer ();

        var password_grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6
        };
        password_grid.attach (password_entry, 0, 0);
        password_grid.attach (fingerprint_image, 1, 0);
        password_grid.attach (caps_lock_revealer, 0, 1, 2);

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.VERTICAL);
        size_group.add_widget (password_entry);
        size_group.add_widget (session_button);

        var login_button = new Gtk.Button.with_label (_("Log In"));
        login_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        bind_property (
            "connecting",
            login_button,
            "sensitive",
            GLib.BindingFlags.INVERT_BOOLEAN
        );

        var disabled_icon = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.MENU);

        var disabled_message = new Gtk.Label (_("Account disabled"));

        var disabled_grid = new Gtk.Grid () {
            column_spacing = 6,
            halign = Gtk.Align.CENTER,
            margin_top = 3
        };
        disabled_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        disabled_grid.add (disabled_icon);
        disabled_grid.add (disabled_message);

        login_stack = new Gtk.Stack ();
        login_stack.add_named (password_grid, "password");
        login_stack.add_named (login_button, "button");
        login_stack.add_named (disabled_grid, "disabled");

        var form_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 24,
            margin_bottom = 12,
            margin_top = 12,
            row_spacing = 12
        };
        form_grid.add (login_stack);
        form_grid.add (session_button);

        form_revealer = new Gtk.Revealer () {
            margin_bottom = 12,
            reveal_child = true,
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        form_revealer.add (form_grid);

        bind_property (
            "show-input",
            form_revealer,
            "reveal-child",
            GLib.BindingFlags.SYNC_CREATE
        );

        var background_path = lightdm_user.background;

        if (background_path == null) {
            string path = GLib.Path.build_filename ("/", "var", "lib", "lightdm-data", lightdm_user.name, "wallpaper");
            if (GLib.FileUtils.test (path, FileTest.EXISTS)) {
                var background_directory = GLib.File.new_for_path (path);
                try {
                    var enumerator = background_directory.enumerate_children (
                        GLib.FileAttribute.STANDARD_NAME,
                        GLib.FileQueryInfoFlags.NONE
                    );

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
        }

        var background_image = new Greeter.BackgroundImage (background_path);

        var main_grid = new Gtk.Grid () {
            margin_bottom = 48,
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.add (background_image);
        main_grid.add (username_label);
        main_grid.add (form_revealer);

        main_grid_style_context = main_grid.get_style_context ();
        main_grid_style_context.add_class (Granite.STYLE_CLASS_CARD);
        main_grid_style_context.add_class (Granite.STYLE_CLASS_ROUNDED);
        main_grid_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        update_collapsed_class ();

        var avatar = new Hdy.Avatar (64, lightdm_user.display_name, true) {
            margin = 6
        };
        avatar.loadable_icon = new FileIcon (File.new_for_path (lightdm_user.image));

        var avatar_overlay = new Gtk.Overlay () {
            halign = Gtk.Align.CENTER,
            margin_top = 100,
            valign = Gtk.Align.START
        };
        avatar_overlay.add (avatar);

        logged_in = new SelectionCheck () {
            halign = Gtk.Align.END,
            valign = Gtk.Align.END
        };

        logged_in_context = logged_in.get_style_context ();

        if (lightdm_user.logged_in) {
            avatar_overlay.add_overlay (logged_in);

            session_button.sensitive = false;
            session_button.tooltip_text = (_("Session cannot be changed while user is logged in"));
        }

        var card_overlay = new Gtk.Overlay () {
            margin = 12
        };
        card_overlay.add (main_grid);
        card_overlay.add_overlay (avatar_overlay);

        add (card_overlay);

        act_user = Act.UserManager.get_default ().get_user (lightdm_user.name);
        act_user.bind_property ("locked", username_label, "sensitive", GLib.BindingFlags.INVERT_BOOLEAN);
        act_user.bind_property ("locked", session_button, "visible", GLib.BindingFlags.INVERT_BOOLEAN);
        act_user.notify["is-loaded"].connect (on_act_user_loaded);

        on_act_user_loaded ();

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
            reveal_ratio = (double)alloc.height / (double)total_height;
        });

        notify["show-input"].connect (() => {
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

        // initially update_style is called inside `set_settings`
        notify["prefers-accent-color"].connect (() => {
            update_style ();
        });

        grab_focus.connect (() => {
            password_entry.grab_focus_without_selecting ();
        });
    }

    private void update_style () {
        var interface_settings = new GLib.Settings ("org.gnome.desktop.interface");
        interface_settings.set_value ("gtk-theme", "io.elementary.stylesheet." + accent_to_string (prefers_accent_color));
    }

    private void set_check_style () {
        // Override check's accent_color so that it *always* uses user's preferred color
        var style_provider = Gtk.CssProvider.get_named ("io.elementary.stylesheet." + accent_to_string (prefers_accent_color), null);
        logged_in_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    private string accent_to_string (int i) {
        switch (i) {
            case 1:
                return "strawberry";
            case 2:
                return "orange";
            case 3:
                return "banana";
            case 4:
                return "lime";
            case 5:
                return "mint";
            case 7:
                return "grape";
            case 8:
                return "bubblegum";
            case 9:
                return "cocoa";
            case 10:
                return "slate";
            default:
                return "blueberry";
        }
    }

    private void on_act_user_loaded () {
        if (!act_user.is_loaded) {
            return;
        }

        unowned string? act_path = act_user.get_object_path ();
        if (act_path != null) {
            try {
                greeter_act = GLib.Bus.get_proxy_sync (
                    GLib.BusType.SYSTEM,
                    "org.freedesktop.Accounts",
                    act_path,
                    GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES
                );

                settings_act = GLib.Bus.get_proxy_sync (
                    GLib.BusType.SYSTEM,
                    "org.freedesktop.Accounts",
                    act_path,
                    GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES
                );

                is_24h = greeter_act.time_format != "12h";
                prefers_accent_color = greeter_act.prefers_accent_color;
                sleep_inactive_ac_timeout = greeter_act.sleep_inactive_ac_timeout;
                sleep_inactive_ac_type = greeter_act.sleep_inactive_ac_type;
                sleep_inactive_battery_timeout = greeter_act.sleep_inactive_battery_timeout;
                sleep_inactive_battery_type = greeter_act.sleep_inactive_battery_type;

                ((GLib.DBusProxy) greeter_act).g_properties_changed.connect ((changed_properties, invalidated_properties) => {
                    string time_format;
                    changed_properties.lookup ("TimeFormat", "s", out time_format);
                    is_24h = time_format != "12h";

                    changed_properties.lookup ("PrefersAccentColor", "i", out _prefers_accent_color);
                    changed_properties.lookup ("SleepInactiveACTimeout", "i", out _sleep_inactive_ac_timeout);
                    changed_properties.lookup ("SleepInactiveACType", "i", out _sleep_inactive_ac_type);
                    changed_properties.lookup ("SleepInactiveBatteryTimeout", "i", out _sleep_inactive_battery_timeout);
                    changed_properties.lookup ("SleepInactiveBatteryType", "i", out _sleep_inactive_battery_type);
                });
            } catch (Error e) {
                critical (e.message);
            }
        }

        set_check_style ();

        if (needs_settings_set) {
            set_settings ();
        }

        if (act_user.locked) {
            login_stack.visible_child_name = "disabled";
        } else {
            if (need_password) {
                login_stack.visible_child_name = "password";
            } else {
                login_stack.visible_child_name = "button";
            }
        }
    }

    private void on_login () {
        if (connecting) {
            return;
        }

        connecting = true;
        if (need_password) {
            do_connect (password_entry.text);
        } else {
            do_connect ();
        }
    }

    private void update_collapsed_class () {
        if (show_input) {
            main_grid_style_context.remove_class ("collapsed");
        } else {
            main_grid_style_context.add_class ("collapsed");
        }
    }

    public void set_settings () {
        if (!act_user.is_loaded) {
            needs_settings_set = true;
            return;
        }

        set_keyboard_layouts ();
        set_mouse_touchpad_settings ();
        update_style ();
    }

    private void set_keyboard_layouts () {
        var settings = new GLib.Settings ("org.gnome.desktop.input-sources");

        Variant[] elements = {};
        foreach (var layout in settings_act.keyboard_layouts) {
            GLib.Variant first = new GLib.Variant.string (layout.backend);
            GLib.Variant second = new GLib.Variant.string (layout.name);
            GLib.Variant result = new GLib.Variant.tuple ({first, second});

            elements += result;
        }

        GLib.Variant layouts_list = new GLib.Variant.array (new VariantType ("(ss)"), elements);
        settings.set_value ("sources", layouts_list);

        settings.set_value ("current", settings_act.active_keyboard_layout);

        string[] options = {};
        foreach (var option in settings_act.xkb_options) {
            options += option.option;
        }
        settings.set_value ("xkb-options", options);
    }

    private void set_mouse_touchpad_settings () {
        var mouse_settings = new GLib.Settings ("org.gnome.desktop.peripherals.mouse");
        mouse_settings.set_boolean ("left-handed", settings_act.left_handed);
        mouse_settings.set_enum ("accel-profile", settings_act.accel_profile);

        mouse_settings.set_boolean ("natural-scroll", settings_act.mouse_natural_scroll);
        mouse_settings.set_double ("speed", settings_act.mouse_speed);

        var touchpad_settings = new GLib.Settings ("org.gnome.desktop.peripherals.touchpad");
        touchpad_settings.set_enum ("click-method", settings_act.touchpad_click_method);
        touchpad_settings.set_boolean ("disable-while-typing", settings_act.touchpad_disable_while_typing);
        touchpad_settings.set_boolean ("edge-scrolling-enabled", settings_act.touchpad_edge_scrolling);
        touchpad_settings.set_boolean ("natural-scroll", settings_act.touchpad_natural_scroll);
        touchpad_settings.set_enum ("send-events", settings_act.touchpad_send_events);
        touchpad_settings.set_double ("speed", settings_act.touchpad_speed);
        touchpad_settings.set_boolean ("tap-to-click", settings_act.touchpad_tap_to_click);
        touchpad_settings.set_boolean ("two-finger-scrolling-enabled", settings_act.touchpad_two_finger_scrolling);

        var interface_settings = new GLib.Settings ("org.gnome.desktop.interface");
        interface_settings.set_int ("cursor-size", settings_act.cursor_size);
    }

    public UserCard (LightDM.User lightdm_user) {
        Object (lightdm_user: lightdm_user);
    }

    public override void wrong_credentials () {

        weak Gtk.StyleContext entry_style_context = password_entry.get_style_context ();
        entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);

        main_grid_style_context.add_class ("shake");

        GLib.Timeout.add (ERROR_SHAKE_DURATION, () => {
            main_grid_style_context.remove_class ("shake");
            entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);

            connecting = false;
            password_entry.grab_focus ();
            return GLib.Source.REMOVE;
        });
    }

    private class SelectionCheck : Gtk.Spinner {
        private static Gtk.CssProvider check_provider;

        class construct {
            set_css_name (Gtk.STYLE_CLASS_CHECK);
        }

        static construct {
            check_provider = new Gtk.CssProvider ();
            check_provider.load_from_resource ("/io/elementary/greeter/Check.css");
        }

        construct {
            get_style_context ().add_provider (check_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        }
    }
}
