/*
 * Copyright 2018-2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class Greeter.UserCard : Greeter.BaseCard {
    /**
     * We use Act.User instead of LightDM.User because lightdm is unmaintained
     * and lacks some fields from Act.User such as `password_mode`.
     */
    public Act.User user { get; construct; }
    public bool is_24h { get; set; default = true; }

    private Pantheon.AccountsService greeter_act;
    private Pantheon.SettingsDaemon.AccountsService settings_act;

    private Gtk.Revealer form_revealer;
    private Gtk.Stack login_stack;
    private Greeter.PasswordEntry password_entry;
    private Gtk.Box main_box;

    private Greeter.SessionButton password_session_button;
    private Greeter.SessionButton login_button_session_button;
    private Gtk.Overlay avatar_overlay;
    private SelectionCheck logged_in;

    public UserCard (Act.User user) requires (user.is_loaded) {
        Object (user: user);
    }

    construct {
        need_password = true;

        var username_label = new Gtk.Label (user.real_name) {
            hexpand = true,
            margin_top = 24,
            margin_bottom = 12,
            margin_start = 24,
            margin_end = 24,
        };
        username_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);
        user.bind_property ("locked", username_label, "sensitive", SYNC_CREATE | INVERT_BOOLEAN);

        password_entry = new Greeter.PasswordEntry ();
        bind_property ("connecting", password_entry, "sensitive", INVERT_BOOLEAN);

        var fingerprint_image = new Gtk.Image.from_icon_name ("fingerprint-symbolic");
        bind_property ("use-fingerprint", fingerprint_image, "visible", SYNC_CREATE);

        password_session_button = new Greeter.SessionButton () {
            vexpand = true
        };

        var password_grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6
        };
        password_grid.attach (password_entry, 0, 0);
        password_grid.attach (fingerprint_image, 1, 0);
        password_grid.attach (password_session_button, 2, 0);
        password_grid.attach (new Greeter.CapsLockRevealer (), 0, 1, 3);

        var login_button = new Gtk.Button.with_label (_("Log In"));
        login_button.add_css_class (Granite.CssClass.SUGGESTED);
        bind_property ("connecting", login_button, "sensitive", INVERT_BOOLEAN);

        login_button_session_button = new Greeter.SessionButton () {
            vexpand = true
        };

        var login_box = new Gtk.Box (HORIZONTAL, 6);
        login_box.append (login_button);
        login_box.append (login_button_session_button);

        var disabled_box = new Gtk.Box (HORIZONTAL, 6) {
            halign = Gtk.Align.CENTER,
            margin_top = 3
        };
        disabled_box.append (new Gtk.Image.from_icon_name ("changes-prevent-symbolic"));
        disabled_box.append (new Gtk.Label (_("Account disabled")));
        disabled_box.add_css_class (Granite.CssClass.DIM);

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
            transition_type = SLIDE_DOWN,
            child = login_stack
        };

        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_bottom = 48,
            overflow = HIDDEN // Without this, Gtk.Picture won't have rounded corners
        };
        main_box.append (username_label);
        main_box.append (form_revealer);
        main_box.add_css_class (Granite.CssClass.CARD);

        var avatar = new Adw.Avatar (64, user.real_name, true) {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6,
        };

        var user_icon_file = File.new_for_path (user.icon_file);
        try {
            avatar.custom_image = Gdk.Texture.from_file (user_icon_file );
        } catch (Error e) {
            avatar.custom_image = null;
        }

        avatar_overlay = new Gtk.Overlay () {
            halign = CENTER,
            valign = START,
            margin_top = 100,
            child = avatar
        };

        logged_in = new SelectionCheck () {
            halign = END,
            valign = END
        };

        var card_overlay = new Gtk.Overlay () {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            child = main_box
        };
        card_overlay.add_overlay (avatar_overlay);

        child = card_overlay;

        on_deselected ();

        user.changed.connect (update_is_locked_ui);
        notify["need-password"].connect (update_is_locked_ui);
        update_is_locked_ui ();

        user.sessions_changed.connect (on_sessions_changed);
        on_sessions_changed ();

        password_entry.activate.connect (on_login);
        login_button.clicked.connect (on_login);

        var focus_controller = new Gtk.EventControllerFocus ();
        focus_controller.enter.connect (() => {
            if (focus_controller.is_focus) {
                password_entry.grab_focus_without_selecting ();
            }
        });

        add_controller (focus_controller);

        connect_to_dbus_interfaces ();
    }

    private void set_check_style () {
        // Override check's accent_color so that it *always* uses user's preferred color
        logged_in.add_css_class (accent_to_string (settings_act.accent_color));
    }

    private string generate_background_image_path () {
        if (settings_act.picture_options == 0) {
            return "";
        }

        var path = Path.build_filename ("/", "var", "lib", "lightdm-data", user.user_name, "wallpaper");
        if (FileUtils.test (path, EXISTS) && FileUtils.test (path, IS_REGULAR)) {
            return path;
        }

        return "/usr/share/backgrounds/elementaryos-default";
    }

    private void set_background_image () {
        var background_picture = new Gtk.Picture () {
            content_fit = COVER
        };

        var background_path = generate_background_image_path ();

        if (settings_act.picture_options != 0) {
            background_picture.set_filename (background_path);
        } else if (settings_act.primary_color != null) {
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

            var pixbuf = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 1, 1);
            pixbuf.fill (f);

            background_picture.paintable = (Gdk.Texture.for_pixbuf (pixbuf));
        } else {
            background_picture.set_filename ("/usr/share/backgrounds/elementaryos-default");
        }

        var clamp = new Adw.Clamp () {
            child = background_picture,
            orientation = VERTICAL,
            maximum_size = 150
        };

        main_box.prepend (clamp);
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
            case 11:
                return "latte";
            default:
                return "blueberry";
        }
    }

    private void connect_to_dbus_interfaces () {
        var account_path = "/org/freedesktop/Accounts/User%d".printf (user.uid);
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
    }

    private void update_is_locked_ui () {
        if (user.locked) {
            login_stack.visible_child_name = "disabled";
        } else if (need_password) {
            login_stack.visible_child_name = "password";
        } else {
            login_stack.visible_child_name = "button";
        }
    }

    private void on_sessions_changed () {
        var user_is_logged_in = user.is_logged_in ();

        password_session_button.sensitive = !user_is_logged_in;
        login_button_session_button.sensitive = user_is_logged_in;

        var tooltip_text = user_is_logged_in ? (_("Session cannot be changed while user is logged in")) : "";
        password_session_button.tooltip_text = tooltip_text;
        login_button_session_button.tooltip_text = tooltip_text;

        if (user_is_logged_in) {
            avatar_overlay.add_overlay (logged_in);
        } else if (logged_in.parent == avatar_overlay) {
            avatar_overlay.remove_overlay (logged_in);
        }
    }

    private void on_login () {
        if (connecting) {
            return;
        }

        connecting = true;
        provide_credential (need_password ? password_entry.text : "");
    }

    private void set_settings () {
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
        interface_settings.set_boolean ("cursor-blink", settings_act.cursor_blink);
        interface_settings.set_int ("cursor-blink-time", settings_act.cursor_blink_time);
        interface_settings.set_int ("cursor-blink-timeout", settings_act.cursor_blink_timeout);
        interface_settings.set_int ("cursor-size", settings_act.cursor_size);
        interface_settings.set_boolean ("locate-pointer", settings_act.locate_pointer);
        interface_settings.set_double ("text-scaling-factor", settings_act.text_scaling_factor);
        set_or_reset_settings_key (interface_settings, "document-font-name", settings_act.document_font_name);
        set_or_reset_settings_key (interface_settings, "font-name", settings_act.font_name);
        set_or_reset_settings_key (interface_settings, "monospace-font-name", settings_act.monospace_font_name);

        var settings_daemon_settings = new GLib.Settings ("io.elementary.settings-daemon.prefers-color-scheme");

        var latitude = new Variant.double (settings_act.last_coordinates.latitude);
        var longitude = new Variant.double (settings_act.last_coordinates.longitude);
        var coordinates = new Variant.tuple ({latitude, longitude});
        settings_daemon_settings.set_value ("last-coordinates", coordinates);

        settings_daemon_settings.set_enum ("prefer-dark-schedule", settings_act.prefer_dark_schedule);
        settings_daemon_settings.set_double ("prefer-dark-schedule-from", settings_act.prefer_dark_schedule_from);
        settings_daemon_settings.set_double ("prefer-dark-schedule-to", settings_act.prefer_dark_schedule_to);

        var touchscreen_settings = new GLib.Settings ("org.gnome.settings-daemon.peripherals.touchscreen");
        touchscreen_settings.set_boolean ("orientation-lock", settings_act.orientation_lock);

        var background_settings = new GLib.Settings ("org.gnome.desktop.background");
        background_settings.set_enum ("picture-options", settings_act.picture_options);

        try {
            var uri = Filename.to_uri (generate_background_image_path (), null);
            set_or_reset_settings_key (background_settings, "picture-uri", uri);
        } catch (Error e) {
            critical ("Failed to set background URI: %s", e.message);
        }

        set_or_reset_settings_key (background_settings, "primary-color", settings_act.primary_color);
    }

    private void set_wingpanel_settings () {
        var wingpanel_schema = SettingsSchemaSource.get_default ().lookup ("io.elementary.desktop.wingpanel", true);
        if (wingpanel_schema != null && wingpanel_schema.has_key ("use-transparency")) {
            var wingpanel_settings = new GLib.Settings ("io.elementary.desktop.wingpanel");
            wingpanel_settings.set_boolean ("use-transparency", settings_act.wingpanel_use_transparency);
        }

        var wingpanel_power_schema = SettingsSchemaSource.get_default ().lookup ("io.elementary.panel.power", true);
        if (wingpanel_power_schema != null && wingpanel_power_schema.has_key ("show-percentage")) {
            var wingpanel_power_settings = new GLib.Settings ("io.elementary.panel.power");
            wingpanel_power_settings.set_boolean ("show-percentage", settings_act.wingpanel_show_percentage);
        } else {
            wingpanel_power_schema = SettingsSchemaSource.get_default ().lookup ("io.elementary.desktop.wingpanel.power", true);
            if (wingpanel_power_schema != null && wingpanel_power_schema.has_key ("show-percentage")) {
                var wingpanel_power_settings = new GLib.Settings ("io.elementary.desktop.wingpanel.power");
                wingpanel_power_settings.set_boolean ("show-percentage", settings_act.wingpanel_show_percentage);
            }
        }
    }

    private void set_night_light_settings () {
        var night_light_settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.color");
        night_light_settings.set_boolean ("night-light-enabled", settings_act.night_light_enabled);

        var latitude = new Variant.double (settings_act.last_coordinates.latitude);
        var longitude = new Variant.double (settings_act.last_coordinates.longitude);
        var coordinates = new Variant.tuple ({latitude, longitude});
        night_light_settings.set_value ("night-light-last-coordinates", coordinates);

        night_light_settings.set_boolean ("night-light-schedule-automatic", settings_act.night_light_schedule_automatic);
        night_light_settings.set_double ("night-light-schedule-from", settings_act.night_light_schedule_from);
        night_light_settings.set_double ("night-light-schedule-to", settings_act.night_light_schedule_to);
        night_light_settings.set_uint ("night-light-temperature", settings_act.night_light_temperature);
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
        interface_settings.set_string ("gtk-theme", "io.elementary.stylesheet." + accent_to_string (settings_act.accent_color));

        SettingsPortal.get_default ().prefers_color_scheme = greeter_act.prefers_color_scheme;
    }

    public override void on_selected () {
        form_revealer.reveal_child = true;
        main_box.remove_css_class ("collapsed");

        set_settings ();
        grab_focus ();

        start_authentication (user.user_name);
    }

    public override void on_deselected () {
        form_revealer.reveal_child = false;
        main_box.add_css_class ("collapsed");
    }

    public override void wrong_credentials () {
        password_entry.add_css_class (Granite.CssClass.ERROR);
        main_box.add_css_class ("shake");

        Timeout.add (ERROR_SHAKE_DURATION, () => {
            password_entry.remove_css_class (Granite.CssClass.ERROR);
            main_box.remove_css_class ("shake");

            connecting = false;
            password_entry.grab_focus ();
            return Source.REMOVE;
        });
    }

    private class SelectionCheck : Granite.Bin {
        class construct {
            set_css_name ("check");
        }

        construct {
            child = new Gtk.Image.from_icon_name ("check-active-symbolic");
        }
    }
}
