/*
 * Copyright 2018-2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class Greeter.UserCard : Greeter.BaseCard {
    public signal void go_left ();
    public signal void go_right ();

    public LightDM.User lightdm_user { get; construct; }
    public bool show_input { get; set; default = false; }
    public bool is_24h { get; set; default = true; }
    // TODO: In Gtk4 remove this gesture and move it to MainWindow 
    public Gtk.GestureMultiPress click_gesture { get; private set; }

    private Pantheon.AccountsService greeter_act;
    private Pantheon.SettingsDaemon.AccountsService settings_act;

    private Gtk.Revealer form_revealer;
    private Gtk.Stack login_stack;
    private Greeter.PasswordEntry password_entry;
    private Gtk.Box main_box;

    private SelectionCheck logged_in;

    public UserCard (LightDM.User lightdm_user) {
        unowned var default_session = ((Greeter.Application) GLib.Application.get_default ()).default_session_type;

        Object (
            lightdm_user: lightdm_user,
            card_identifier: "User%u".printf ((uint) lightdm_user.uid),
            selected_session: lightdm_user.session ?? default_session
        );
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
        username_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        lightdm_user.bind_property ("is-locked", username_label, "sensitive", SYNC_CREATE | INVERT_BOOLEAN);

        password_entry = new Greeter.PasswordEntry ();
        bind_property ("connecting", password_entry, "sensitive", INVERT_BOOLEAN);

        var fingerprint_image = new Gtk.Image.from_icon_name ("fingerprint-symbolic", BUTTON);
        bind_property ("use-fingerprint", fingerprint_image, "no-show-all", SYNC_CREATE | INVERT_BOOLEAN);
        bind_property ("use-fingerprint", fingerprint_image, "visible", SYNC_CREATE);

        var password_session_button = new Greeter.SessionButton (card_identifier, select_session_action) {
            vexpand = true
        };
        lightdm_user.bind_property ("is-locked", password_session_button, "sensitive", SYNC_CREATE | INVERT_BOOLEAN);

        var password_grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6
        };
        password_grid.attach (password_entry, 0, 0);
        password_grid.attach (fingerprint_image, 1, 0);
        password_grid.attach (password_session_button, 2, 0);
        password_grid.attach (new Greeter.CapsLockRevealer (), 0, 1, 3);

        var login_button = new Gtk.Button.with_label (_("Log In"));
        login_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        bind_property ("connecting", login_button, "sensitive", INVERT_BOOLEAN);

        var login_button_session_button = new Greeter.SessionButton (card_identifier, select_session_action) {
            vexpand = true
        };
        lightdm_user.bind_property ("is-locked", login_button_session_button, "sensitive", SYNC_CREATE | INVERT_BOOLEAN);

        var login_box = new Gtk.Box (HORIZONTAL, 6);
        login_box.add (login_button);
        login_box.add (login_button_session_button);

        var disabled_box = new Gtk.Box (HORIZONTAL, 6) {
            halign = Gtk.Align.CENTER,
            margin_top = 3
        };
        disabled_box.add (new Gtk.Image.from_icon_name ("changes-prevent-symbolic", MENU));
        disabled_box.add (new Gtk.Label (_("Account disabled")));
        disabled_box.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        login_stack = new Gtk.Stack () {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 24,
            margin_end = 24
        };
        login_stack.add_named (password_grid, "password");
        login_stack.add_named (login_button, "button");
        login_stack.add_named (disabled_box, "disabled");

        form_revealer = new Gtk.Revealer () {
            margin_bottom = 12,
            reveal_child = true,
            transition_type = SLIDE_DOWN,
            child = login_stack
        };
        bind_property ("show-input", form_revealer, "reveal-child", SYNC_CREATE);

        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_bottom = 48
        };
        // in reverse order because pack_end is used
        main_box.pack_end (form_revealer);
        main_box.pack_end (username_label);
        main_box.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        main_box.get_style_context ().add_class (Granite.STYLE_CLASS_ROUNDED);

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

        if (lightdm_user.logged_in) {
            avatar_overlay.add_overlay (logged_in);

            password_session_button.sensitive = false;
            password_session_button.tooltip_text = (_("Session cannot be changed while user is logged in"));

            login_button_session_button.sensitive = false;
            login_button_session_button.tooltip_text = (_("Session cannot be changed while user is logged in"));
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

        connect_to_dbus_interfaces ();

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

        notify["show-input"].connect (update_collapsed_class);

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
        logged_in.get_style_context ().add_class (accent_to_string (settings_act.accent_color));
    }

    private void set_background_image () {
        Greeter.BackgroundImage background_image;

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
            background_image = new Greeter.BackgroundImage.from_path (background_path);
        } else if (settings_act.picture_options == 0 && settings_act.primary_color != null) {
            background_image = new Greeter.BackgroundImage.from_color (settings_act.primary_color);
        } else {
            background_image = new Greeter.BackgroundImage.from_path (null);
        }

        main_box.pack_start (background_image);
        main_box.show_all ();
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

    private void connect_to_dbus_interfaces () {
        var account_path = "/org/freedesktop/Accounts/User%d".printf ((int )lightdm_user.uid);
        try {
            greeter_act = Bus.get_proxy_sync (
                SYSTEM,
                "org.freedesktop.Accounts",
                account_path,
                GET_INVALIDATED_PROPERTIES
            );

            settings_act = Bus.get_proxy_sync (
                SYSTEM,
                "org.freedesktop.Accounts",
                account_path,
                GET_INVALIDATED_PROPERTIES
            );

            is_24h = greeter_act.time_format != "12h";
        } catch (Error e) {
            critical (e.message);
        }

        set_background_image ();
        set_check_style ();

        if (lightdm_user.is_locked) {
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
            main_box.get_style_context ().remove_class ("collapsed");
        } else {
            main_box.get_style_context ().add_class ("collapsed");
        }
    }

    public void set_settings () {
        set_keyboard_layouts ();
        set_mouse_touchpad_settings ();
        set_interface_settings ();
        set_wingpanel_settings ();
        set_night_light_settings ();
        set_power_settings ();
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

        var settings_daemon_settings = new GLib.Settings ("io.elementary.settings-daemon.prefers-color-scheme");

        var latitude = new Variant.double (settings_act.last_coordinates.latitude);
        var longitude = new Variant.double (settings_act.last_coordinates.longitude);
        var coordinates = new Variant.tuple ({latitude, longitude});
        settings_daemon_settings.set_value ("last-coordinates", coordinates);

        settings_daemon_settings.set_enum ("prefer-dark-schedule", settings_act.prefer_dark_schedule);
        settings_daemon_settings.set_value ("prefer-dark-schedule-from", settings_act.prefer_dark_schedule_from);
        settings_daemon_settings.set_value ("prefer-dark-schedule-to", settings_act.prefer_dark_schedule_to);

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

    private void set_wingpanel_settings () {
        var wingpanel_schema = SettingsSchemaSource.get_default ().lookup ("io.elementary.desktop.wingpanel", true);
        if (wingpanel_schema == null || !wingpanel_schema.has_key ("use-transparency")) {
            return;
        }

        var wingpanel_settings = new GLib.Settings ("io.elementary.desktop.wingpanel");
        wingpanel_settings.set_value ("use-transparency", settings_act.wingpanel_use_transparency);
    }

    private void set_night_light_settings () {
        var night_light_settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.color");
        night_light_settings.set_value ("night-light-enabled", settings_act.night_light_enabled);

        var latitude = new Variant.double (settings_act.last_coordinates.latitude);
        var longitude = new Variant.double (settings_act.last_coordinates.longitude);
        var coordinates = new Variant.tuple ({latitude, longitude});
        night_light_settings.set_value ("night-light-last-coordinates", coordinates);

        night_light_settings.set_value ("night-light-schedule-automatic", settings_act.night_light_schedule_automatic);
        night_light_settings.set_value ("night-light-schedule-from", settings_act.night_light_schedule_from);
        night_light_settings.set_value ("night-light-schedule-to", settings_act.night_light_schedule_to);
        night_light_settings.set_value ("night-light-temperature", settings_act.night_light_temperature);
    }

    private void set_power_settings () {
        var power_settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");
        power_settings.set_int ("sleep-inactive-ac-timeout", greeter_act.sleep_inactive_ac_timeout);
        power_settings.set_enum ("sleep-inactive-ac-type", greeter_act.sleep_inactive_ac_type);
        power_settings.set_int ("sleep-inactive-battery-timeout", greeter_act.sleep_inactive_battery_timeout);
        power_settings.set_enum ("sleep-inactive-battery-type", greeter_act.sleep_inactive_battery_type);
    }

    private void update_style () {
        var interface_settings = new GLib.Settings ("org.gnome.desktop.interface");
        interface_settings.set_value ("gtk-theme", "io.elementary.stylesheet." + accent_to_string (settings_act.accent_color));

        SettingsPortal.get_default ().prefers_color_scheme = greeter_act.prefers_color_scheme;
    }

    public override void wrong_credentials () {
        password_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);
        main_box.get_style_context ().add_class ("shake");

        Timeout.add (ERROR_SHAKE_DURATION, () => {
            password_entry.get_style_context ().remove_class (Gtk.STYLE_CLASS_ERROR);
            main_box.get_style_context ().remove_class ("shake");

            connecting = false;
            password_entry.grab_focus ();
            return Source.REMOVE;
        });
    }

    private class SelectionCheck : Gtk.Spinner {
        class construct {
            set_css_name (Gtk.STYLE_CLASS_CHECK);
        }
    }
}
