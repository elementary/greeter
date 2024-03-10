/*
 * Copyright 2018-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class Greeter.UserCard : Greeter.BaseCard {
    public signal void go_left ();
    public signal void go_right ();
    public signal void focus_requested ();

    public LightDM.User lightdm_user { get; construct; }
    public bool show_input { get; set; default = false; }
    public bool is_24h { get; set; default = true; }

    public int prefers_accent_color { get; set; default = 6; }
    public int sleep_inactive_ac_timeout { get; set; default = 1200; }
    public int sleep_inactive_ac_type { get; set; default = 1; }
    public int sleep_inactive_battery_timeout { get; set; default = 1200; }
    public int sleep_inactive_battery_type { get; set; default = 1; }

    private Act.User act_user;
    private Pantheon.AccountsService greeter_act;
    private Pantheon.SettingsDaemon.AccountsService settings_act;

    private Gtk.GestureClick click_gesture;
    private Gtk.Revealer form_revealer;
    private Gtk.Stack login_stack;
    private Greeter.PasswordEntry password_entry;
    private Gtk.Box main_box;

    private SelectionCheck logged_in;

    private unowned Gtk.StyleContext logged_in_context;
    private unowned Gtk.StyleContext main_box_style_context;
    private unowned Gtk.StyleContext password_entry_context;

    private bool needs_settings_set = false;

    public UserCard (LightDM.User lightdm_user) {
        Object (lightdm_user: lightdm_user);
    }

    construct {
        need_password = true;

        var username_label = new Gtk.Label (lightdm_user.display_name) {
            hexpand = true,
            margin_top = 24,
            margin_bottom = 12,
            margin_start = 24,
            margin_end = 24,
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
            INVERT_BOOLEAN
        );

        var fingerprint_image = new Gtk.Image.from_icon_name (
            "fingerprint-symbolic",
            BUTTON
        );

        bind_property (
            "use-fingerprint",
            fingerprint_image,
            "no-show-all",
            INVERT_BOOLEAN | SYNC_CREATE
        );

        bind_property (
            "use-fingerprint",
            fingerprint_image,
            "visible",
            SYNC_CREATE
        );

        var session_button = new Greeter.SessionButton () {
            valign = START
        };

        var caps_lock_revealer = new Greeter.CapsLockRevealer ();

        var password_grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6
        };
        password_grid.attach (password_entry, 0, 0);
        password_grid.attach (fingerprint_image, 1, 0);
        password_grid.attach (caps_lock_revealer, 0, 1, 2);

        var size_group = new Gtk.SizeGroup (VERTICAL);
        size_group.add_widget (password_entry);
        size_group.add_widget (session_button);

        var login_button = new Gtk.Button.with_label (_("Log In"));
        login_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        bind_property (
            "connecting",
            login_button,
            "sensitive",
            INVERT_BOOLEAN
        );

        var disabled_icon = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", MENU);

        var disabled_message = new Gtk.Label (_("Account disabled"));

        var disabled_box = new Gtk.Box (HORIZONTAL, 6) {
            halign = Gtk.Align.CENTER,
            margin_top = 3
        };
        disabled_box.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        disabled_box.add (disabled_icon);
        disabled_box.add (disabled_message);

        login_stack = new Gtk.Stack ();
        login_stack.add_named (password_grid, "password");
        login_stack.add_named (login_button, "button");
        login_stack.add_named (disabled_box, "disabled");

        var form_box = new Gtk.Box (HORIZONTAL, 6) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 24,
            margin_end = 24
        };
        form_box.add (login_stack);
        form_box.add (session_button);

        form_revealer = new Gtk.Revealer () {
            margin_bottom = 12,
            reveal_child = true,
            transition_type = SLIDE_DOWN,
            child = form_box
        };

        bind_property (
            "show-input",
            form_revealer,
            "reveal-child",
            SYNC_CREATE
        );

        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_bottom = 48
        };
        // in reverse order because pack_end is used
        main_box.pack_end (form_revealer);
        main_box.pack_end (username_label);

        main_box_style_context = main_box.get_style_context ();
        main_box_style_context.add_class (Granite.STYLE_CLASS_CARD);
        main_box_style_context.add_class (Granite.STYLE_CLASS_ROUNDED);
        main_box_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        update_collapsed_class ();

        var avatar = new Hdy.Avatar (64, lightdm_user.display_name, true) {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6,
            loadable_icon = new FileIcon (File.new_for_path (lightdm_user.image))
        };

        var avatar_overlay = new Gtk.Overlay () {
            halign = CENTER,
            valign = START,
            margin_top = 100,
            child = avatar
        };

        logged_in = new SelectionCheck () {
            halign = END,
            valign = END
        };

        logged_in_context = logged_in.get_style_context ();

        if (lightdm_user.logged_in) {
            avatar_overlay.add_overlay (logged_in);

            session_button.sensitive = false;
            session_button.tooltip_text = (_("Session cannot be changed while user is logged in"));
        }

        var card_overlay = new Gtk.Overlay () {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            child = main_box
        };
        card_overlay.add_overlay (avatar_overlay);

        child = card_overlay;

        act_user = Act.UserManager.get_default ().get_user (lightdm_user.name);
        act_user.bind_property ("locked", username_label, "sensitive", INVERT_BOOLEAN);
        act_user.bind_property ("locked", session_button, "visible", INVERT_BOOLEAN);
        act_user.notify["is-loaded"].connect (on_act_user_loaded);

        on_act_user_loaded ();

        card_overlay.focus.connect ((direction) => {
            if (direction == LEFT) {
                go_left ();
                return true;
            } else if (direction == RIGHT) {
                go_right ();
                return true;
            }

            return false;
        });

        click_gesture = new Gtk.GestureMultiPress (this);
        click_gesture.pressed.connect ((n_press, x, y) => {
            if (!show_input) {
                focus_requested ();
                password_entry.grab_focus ();
            }
        });

        notify["show-input"].connect (() => {
            update_collapsed_class ();
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

    private void set_check_style () {
        // Override check's accent_color so that it *always* uses user's preferred color
        var style_provider = Gtk.CssProvider.get_named ("io.elementary.stylesheet." + accent_to_string (prefers_accent_color), null);
        logged_in_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    private void set_background_image () {
        var background_picture = new Gtk.Picture () {
            content_fit = COVER,
            height_request = 150
        };

        var background_path = lightdm_user.background;
        var background_exists = (
            background_path != null &&
            FileUtils.test (background_path, EXISTS) &&
            FileUtils.test (background_path, IS_REGULAR)
        );

        if (!background_exists) {
            background_path = Path.build_filename ("/", "var", "lib", "lightdm-data", lightdm_user.name, "wallpaper");
            background_exists = FileUtils.test (background_path, EXISTS) && FileUtils.test (background_path, IS_REGULAR);
        }

        if (settings_act.picture_options != 0 && background_exists) {
            background_picture.set_filename (background_path);
        } else if (settings_act.picture_options == 0 && settings_act.primary_color != null) {
            Gdk.RGBA rgba_color = {};
            rgba_color.parse (settings_act.primary_color);

            uint32 f = 0x0;
            f += (uint) Math.round (rgba_color.red * 255);
            f <<= 8;
            f += (uint) Math.round (rgba_color.green * 255);
            f <<= 8;
            f += (uint) Math.round (rgba_color.blue * 255);
            f <<= 8;
            f += 255;

            pixbuf = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 1, 1);
            pixbuf.fill (f);

            background_picture.paintable = (Gdk.Texture.for_pixbuf (pixbuf));
        } else {
            background_picture.set_filename ("/usr/share/backgrounds/elementaryos-default");
        }

        main_box.pack_start (background_image);
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
                greeter_act = Bus.get_proxy_sync (
                    SYSTEM,
                    "org.freedesktop.Accounts",
                    act_path,
                    GET_INVALIDATED_PROPERTIES
                );

                settings_act = Bus.get_proxy_sync (
                    SYSTEM,
                    "org.freedesktop.Accounts",
                    act_path,
                    GET_INVALIDATED_PROPERTIES
                );

                is_24h = greeter_act.time_format != "12h";
                prefers_accent_color = greeter_act.prefers_accent_color;
                sleep_inactive_ac_timeout = greeter_act.sleep_inactive_ac_timeout;
                sleep_inactive_ac_type = greeter_act.sleep_inactive_ac_type;
                sleep_inactive_battery_timeout = greeter_act.sleep_inactive_battery_timeout;
                sleep_inactive_battery_type = greeter_act.sleep_inactive_battery_type;

                ((DBusProxy) greeter_act).g_properties_changed.connect ((changed_properties, invalidated_properties) => {
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

        set_background_image ();
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
            main_box_style_context.remove_class ("collapsed");
        } else {
            main_box_style_context.add_class ("collapsed");
        }
    }

    public void set_settings () {
        if (!act_user.is_loaded) {
            needs_settings_set = true;
            return;
        }

        set_keyboard_layouts ();
        set_mouse_touchpad_settings ();
        set_interface_settings ();
        set_night_light_settings ();
        update_style ();
    }

    private void set_keyboard_layouts () {
        var settings = new GLib.Settings ("org.gnome.desktop.input-sources");

        Variant[] elements = {};
        foreach (var layout in settings_act.keyboard_layouts) {
            Variant first = new Variant.string (layout.backend);
            Variant second = new Variant.string (layout.name);
            Variant result = new Variant.tuple ({first, second});

            elements += result;
        }

        Variant layouts_list = new Variant.array (new VariantType ("(ss)"), elements);
        settings.set_value ("sources", layouts_list);

        settings.set_value ("current", settings_act.active_keyboard_layout);

        string[] options = {};
        foreach (var option in settings_act.xkb_options) {
            options += option.option;
        }
        settings.set_value ("xkb-options", options);
    }

    /* 
     * When we get string typed settings from our settings daemon account service we might get a null value.
     * In this case we reset the value to avoid criticals and unwanted behaviour.
     */
    private void set_or_reset_settings_key (GLib.Settings settings, string key, GLib.Variant? value) {
        if (value != null) {
            settings.set_value (key, value);
        } else {
            settings.reset (key);
        }
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
    }

    private void set_interface_settings () {
        var interface_settings = new GLib.Settings ("org.gnome.desktop.interface");
        interface_settings.set_value ("cursor-blink", settings_act.cursor_blink);
        interface_settings.set_value ("cursor-blink-time", settings_act.cursor_blink_time);
        interface_settings.set_value ("cursor-blink-timeout", settings_act.cursor_blink_timeout);
        interface_settings.set_value ("cursor-size", settings_act.cursor_size);
        interface_settings.set_value ("locate-pointer", settings_act.locate_pointer);
        interface_settings.set_value ("text-scaling-factor", settings_act.text_scaling_factor);
        set_or_reset_settings_key (interface_settings, "document-font-name", settings_act.document_font_name);
        set_or_reset_settings_key (interface_settings, "font-name", settings_act.font_name);
        set_or_reset_settings_key (interface_settings, "monospace-font-name", settings_act.monospace_font_name);

        var touchscreen_settings = new GLib.Settings ("org.gnome.settings-daemon.peripherals.touchscreen");
        touchscreen_settings.set_boolean ("orientation-lock", settings_act.orientation_lock);

        var background_settings = new GLib.Settings ("org.gnome.desktop.background");
        if (lightdm_user.background != null) {
            background_settings.set_value ("picture-uri", lightdm_user.background);
        } else {
            background_settings.reset ("picture-uri");
        }

        background_settings.set_value ("picture-options", settings_act.picture_options);
        background_settings.set_value ("primary-color", settings_act.primary_color);
    }

    private void set_night_light_settings () {
        var night_light_settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.color");
        night_light_settings.set_value ("night-light-enabled", settings_act.night_light_enabled);

        var latitude = new Variant.double (settings_act.night_light_last_coordinates.latitude);
        var longitude = new Variant.double (settings_act.night_light_last_coordinates.longitude);
        var coordinates = new Variant.tuple ({latitude, longitude});
        night_light_settings.set_value ("night-light-last-coordinates", coordinates);

        night_light_settings.set_value ("night-light-schedule-automatic", settings_act.night_light_schedule_automatic);
        night_light_settings.set_value ("night-light-schedule-from", settings_act.night_light_schedule_from);
        night_light_settings.set_value ("night-light-schedule-to", settings_act.night_light_schedule_to);
        night_light_settings.set_value ("night-light-temperature", settings_act.night_light_temperature);
    }

    private void update_style () {
        var interface_settings = new GLib.Settings ("org.gnome.desktop.interface");
        interface_settings.set_value ("gtk-theme", "io.elementary.stylesheet." + accent_to_string (prefers_accent_color));
    }

    public override void wrong_credentials () {
        unowned var entry_style_context = password_entry.get_style_context ();
        entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);

        main_box_style_context.add_class ("shake");

        Timeout.add (ERROR_SHAKE_DURATION, () => {
            main_box_style_context.remove_class ("shake");
            entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);

            connecting = false;
            password_entry.grab_focus ();
            return Source.REMOVE;
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
