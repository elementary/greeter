/*
 * Copyright 2018-2021 elementary, Inc. (https://elementary.io)
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

public class Greeter.MainWindow : Gtk.ApplicationWindow {
    protected static Gtk.CssProvider css_provider;

    private GLib.Queue<unowned Greeter.UserCard> user_cards;
    private Gtk.SizeGroup card_size_group;
    private Hdy.Carousel carousel;
    private LightDM.Greeter lightdm_greeter;
    private Greeter.Settings settings;
    private Gtk.Button guest_login_button;
    private Gtk.ToggleButton manual_login_button;
    private Gtk.Revealer datetime_revealer;
    private Greeter.DateTimeWidget datetime_widget;
    private unowned LightDM.UserList lightdm_user_list;

    private int current_user_card_index = 0;
    private unowned Greeter.BaseCard? current_card = null;

    private bool _is_live_session? = null;
    private bool is_live_session {
        get {
            if (_is_live_session != null) {
                return _is_live_session;
            }

            var proc_cmdline = File.new_for_path ("/proc/cmdline");
            try {
                var dis = new DataInputStream (proc_cmdline.read ());
                var line = dis.read_line ();
                if ("boot=casper" in line || "boot=live" in line || "rd.live.image" in line) {
                    return true;
                }
            } catch (Error e) {
                critical ("Couldn't detect if running in Live Session: %s", e.message);
            }

            return false;
        }
    }

    private Gtk.EventControllerKey key_controller;

    private const uint[] NAVIGATION_KEYS = {
        Gdk.Key.Up,
        Gdk.Key.Down,
        Gdk.Key.Left,
        Gdk.Key.Right,
        Gdk.Key.Tab
    };

    static construct {
        css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/greeter/MainWindow.css");
    }

    construct {
        app_paintable = true;
        decorated = false;
        type_hint = Gdk.WindowTypeHint.DESKTOP;
        get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        settings = new Greeter.Settings ();
        create_session_selection_action ();

        set_visual (get_screen ().get_rgba_visual ());

        guest_login_button = new Gtk.Button.with_label (_("Log in as Guest"));

        manual_login_button = new Gtk.ToggleButton.with_label (_("Manual Login…"));

        var extra_login_grid = new Gtk.Grid () {
            column_homogeneous = true,
            column_spacing = 12,
            halign = CENTER,
            valign = END,
            vexpand = true
        };

        datetime_widget = new Greeter.DateTimeWidget ();

        datetime_revealer = new Gtk.Revealer () {
            child = datetime_widget,
            transition_type = CROSSFADE,
            valign = CENTER,
            vexpand = true
        };

        user_cards = new GLib.Queue<unowned Greeter.UserCard> ();

        var manual_card = new Greeter.ManualCard ();

        carousel = new Hdy.Carousel () {
            allow_long_swipes = true,
            vexpand = true
        };

        var manual_login_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        manual_login_stack.add (carousel);
        manual_login_stack.add (manual_card);

        var main_box = new Gtk.Box (VERTICAL, 24) {
            margin_top = 24,
            margin_bottom = 24
        };
        main_box.add (datetime_revealer);
        main_box.add (manual_login_stack);
        main_box.add (extra_login_grid);

        child = main_box;

        manual_login_button.toggled.connect (() => {
            if (manual_login_button.active) {
                if (lightdm_greeter.in_authentication) {
                    try {
                        lightdm_greeter.cancel_authentication ();
                    } catch (Error e) {
                        critical (e.message);
                    }
                }

                manual_login_stack.visible_child = manual_card;
                current_card = manual_card;
            } else {
                if (lightdm_greeter.in_authentication) {
                    try {
                        lightdm_greeter.cancel_authentication ();
                    } catch (Error e) {
                        critical (e.message);
                    }
                }

                manual_login_stack.visible_child = carousel;
                current_card = user_cards.peek_nth (current_user_card_index);

                try {
                    lightdm_greeter.authenticate (((UserCard) current_card).lightdm_user.name);
                } catch (Error e) {
                    critical (e.message);
                }
            }
        });

        guest_login_button.clicked.connect (() => {
            try {
                lightdm_greeter.authenticate_as_guest ();
            } catch (Error e) {
                critical (e.message);
            }
        });

        card_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        card_size_group.add_widget (extra_login_grid);
        card_size_group.add_widget (manual_card);

        lightdm_greeter = new LightDM.Greeter ();
        lightdm_greeter.show_message.connect (show_message);
        lightdm_greeter.show_prompt.connect (show_prompt);
        lightdm_greeter.authentication_complete.connect (authentication_complete);

        lightdm_greeter.notify["has-guest-account-hint"].connect (() => {
            if (lightdm_greeter.has_guest_account_hint && guest_login_button.parent == null) {
                extra_login_grid.attach (guest_login_button, 0, 0);
                guest_login_button.show ();
            }
        });

        lightdm_greeter.notify["show-manual-login-hint"].connect (() => {
            if (lightdm_greeter.show_manual_login_hint && manual_login_button.parent == null) {
                extra_login_grid.attach (manual_login_button, 1, 0);
                manual_login_button.show ();
            }
        });

        lightdm_greeter.bind_property ("hide-users-hint", manual_login_button, "sensitive", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
        lightdm_greeter.bind_property ("hide-users-hint", manual_login_button, "active", GLib.BindingFlags.SYNC_CREATE);

        notify["scale-factor"].connect (() => {
            maximize_window ();
        });

        lightdm_user_list = LightDM.UserList.get_instance ();
        lightdm_user_list.user_added.connect (() => {
            load_users.begin ();
        });

        manual_card.do_connect_username.connect (do_connect_username);
        manual_card.do_connect.connect (do_connect);

        key_controller = new Gtk.EventControllerKey (this) {
            propagation_phase = CAPTURE
        };
        key_controller.key_pressed.connect ((keyval, keycode, state) => {
            var mods = state & Gtk.accelerator_get_default_mod_mask ();

            if (!(keyval in NAVIGATION_KEYS)) {
                // Don't focus if it is a modifier or if search_box is already focused
                unowned var current_focus = get_focus ();
                if ((mods == 0) && (current_focus == null || !current_focus.is_ancestor (current_card))) {
                    current_card.grab_focus ();
                }

                return Gdk.EVENT_PROPAGATE;
            }

            // arrow key is being used to navigate
            if (current_card is UserCard) {
                unowned var focused_entry = (Gtk.Entry) get_focus ();
                if (focused_entry != null && focused_entry.is_ancestor (current_card)) {
                    if (focused_entry.text == "") {
                        if (keyval == Gdk.Key.Left) {
                            if (Gtk.StateFlags.DIR_LTR in get_state_flags ()) {
                                go_previous ();
                            } else {
                                go_next ();
                            }
                            return Gdk.EVENT_STOP;
                        } else if (keyval == Gdk.Key.Right) {
                            if (Gtk.StateFlags.DIR_LTR in get_state_flags ()) {
                                go_next ();
                            } else {
                                go_previous ();
                            }
                            return Gdk.EVENT_STOP;
                        }
                    }
                }
            }
        });

        carousel.page_changed.connect ((index) => {
            var children = carousel.get_children ();

            if (children.nth_data (index) is Greeter.UserCard) {
                current_user_card_index = (int) index;
                switch_to_card ((Greeter.UserCard) children.nth_data (index));
            }
        });

        // regrab focus when dpi changed
        get_screen ().monitors_changed.connect (() => {
            maximize_and_focus ();
        });

        leave_notify_event.connect (() => {
            maximize_and_focus ();
            return false;
        });

        destroy.connect (() => {
            Gtk.main_quit ();
        });

        load_users.begin (() => {
            /* A significant delay is required in order for the window and card to be focused at
             * at boot.  TODO: Find whether boot sequence can be tweaked to fix this.
             */
            Timeout.add (500, () => {
                maximize_and_focus ();
                return Source.REMOVE;
            });
        });

        maximize_window ();

        if (settings.activate_numlock) {
            try {
                Process.spawn_async (null, { "numlockx", "on" }, null, SpawnFlags.SEARCH_PATH, null, null);
            } catch (Error e) {
                warning ("Unable to spawn numlockx to set numlock state");
            }
        }
    }

    private void maximize_and_focus () {
        present ();
        maximize_window ();
        get_style_context ().add_class ("initialized");

        if (current_card != null) {
            current_card.grab_focus ();
        }
    }

    private void maximize_window () {
        var display = Gdk.Display.get_default ();
        unowned Gdk.Seat seat = display.get_default_seat ();
        unowned Gdk.Device? pointer = seat.get_pointer ();

        Gdk.Monitor? monitor;
        if (pointer != null) {
            int x, y;
            pointer.get_position (null, out x, out y);
            monitor = display.get_monitor_at_point (x, y);
        } else {
            monitor = display.get_primary_monitor ();
        }

        var rect = monitor.get_geometry ();
        resize (rect.width, rect.height);
        move (rect.x, rect.y);
    }

    private void create_session_selection_action () {
        unowned GLib.List<LightDM.Session> sessions = LightDM.get_sessions ();
        weak LightDM.Session? first_session = sessions.nth_data (0);
        var selected_session = new GLib.Variant.string (first_session != null ? first_session.key : "");
        var select_session_action = new GLib.SimpleAction.stateful ("select", GLib.VariantType.STRING, selected_session);
        var vardict = new GLib.VariantDict ();
        sessions.foreach ((session) => {
            vardict.insert_value (session.name, new GLib.Variant.string (session.key));
        });
        select_session_action.set_state_hint (vardict.end ());

        select_session_action.activate.connect ((param) => {
            if (!select_session_action.get_state ().equal (param)) {
                select_session_action.set_state (param);
            }
        });

        var action_group = new GLib.SimpleActionGroup ();
        action_group.add_action (select_session_action);
        insert_action_group ("session", action_group);
    }

    private void show_message (string text, LightDM.MessageType type) {
        var messagetext = Greeter.FPrintUtils.string_to_messagetext (text);
        switch (messagetext) {
            case Greeter.FPrintUtils.MessageText.FPRINT_TIMEOUT:
            case Greeter.FPrintUtils.MessageText.FPRINT_ERROR:
            case Greeter.FPrintUtils.MessageText.OTHER:
                current_card.use_fingerprint = false;
                break;
            default:
                current_card.use_fingerprint = true;
                break;
        }

        critical ("message: `%s' (%d): %s", text, type, messagetext.to_string ());
        /*var messagetext = string_to_messagetext(text);

        if (messagetext == MessageText.FPRINT_SWIPE || messagetext == MessageText.FPRINT_PLACE) {
            // For the fprint module, there is no prompt message from PAM.
            send_prompt (PromptType.FPRINT);
        }

        current_login.show_message (type, messagetext, text);*/
    }

    private void show_prompt (string text, LightDM.PromptType type = LightDM.PromptType.QUESTION) {
        critical ("prompt: `%s' (%d)", text, type);
        /*send_prompt (lightdm_prompttype_to_prompttype(type), string_to_prompttext(text), text);

        had_prompt = true;

        current_login.show_prompt (type, prompttext, text);*/
        if (current_card is ManualCard) {
            if (type == LightDM.PromptType.SECRET) {
                ((ManualCard) current_card).ask_password ();
            } else {
                ((ManualCard) current_card).wrong_username ();
            }
        }
    }

    // Called after the credentials are checked, might be authenticated or not.
    private void authentication_complete () {
        var user_card = current_card as Greeter.UserCard;
        if (user_card != null) {
             settings.last_user = user_card.lightdm_user.name;
        }

        if (lightdm_greeter.is_authenticated) {
            // Copy user's power settings to lightdm user
            if (user_card != null) {
                settings.sleep_inactive_ac_timeout = user_card.sleep_inactive_ac_timeout;
                settings.sleep_inactive_ac_type = user_card.sleep_inactive_ac_type;
                settings.sleep_inactive_battery_timeout = user_card.sleep_inactive_battery_timeout;
                settings.sleep_inactive_battery_type = user_card.sleep_inactive_battery_type;
            }

            var action_group = get_action_group ("session");
            try {
                unowned var session = action_group.get_action_state ("select").get_string ();

                // If the greeter is running on the install medium, check if the Installer has signalled
                // that it wants the greeter to launch the live (demo) session by means of touching a file
                if (is_live_session) {
                    var demo_mode_file = File.new_for_path ("/var/lib/lightdm/demo-mode");
                    if (demo_mode_file.query_exists ()) {
                        demo_mode_file.@delete ();
                        session = "pantheon";
                    } else {
                        session = "installer";
                    }
                }

                lightdm_greeter.start_session_sync (session);
                return;
            } catch (Error e) {
                var error_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Unable to Log In"),
                    _("Starting the session has failed."),
                    "dialog-error",
                    Gtk.ButtonsType.CLOSE
                );
                error_dialog.show_error_details (e.message);
                error_dialog.present ();
                error_dialog.response.connect (error_dialog.destroy);
            }
        }

        if (user_card != null) {
            try {
                lightdm_greeter.authenticate (user_card.lightdm_user.name);
            } catch (Error e) {
                critical (e.message);
            }
        }

        current_card.wrong_credentials ();

        carousel.interactive = true;
    }

    private async void load_users () {
        try {
            yield lightdm_greeter.connect_to_daemon (null);
        } catch (Error e) {
            critical (e.message);
        }

        // Don't need to build user cards etc in live media
        if (is_live_session) {
            return;
        }

        if (lightdm_greeter.default_session_hint != null) {
            get_action_group ("session").activate_action ("select", new GLib.Variant.string (lightdm_greeter.default_session_hint));
        }

        if (lightdm_user_list.length > 0) {
            datetime_revealer.reveal_child = true;

            lightdm_user_list.users.foreach ((user) => {
                add_card (user);
            });

            unowned string? select_user = lightdm_greeter.select_user_hint;
            var user_to_select = (select_user != null) ? select_user : settings.last_user;

            bool user_selected = false;
            if (user_to_select != null) {
                user_cards.head.foreach ((card) => {
                    if (card.lightdm_user.name == user_to_select) {
                        switch_to_card (card);
                        user_selected = true;
                    }
                });
            }

            if (!user_selected) {
                unowned var user_card = user_cards.peek_head ();
                user_card.show_input = true;
                switch_to_card (user_card);
            }
        } else {
            datetime_revealer.reveal_child = false;

            /* We're not certain that scaling factor will change, but try to wait for GSD in case it does */
            Timeout.add (500, () => {
                try {
                    var initial_setup = AppInfo.create_from_commandline ("io.elementary.initial-setup", null, GLib.AppInfoCreateFlags.NONE);
                    initial_setup.launch (null, null);
                } catch (Error e) {
                    string error_text = _("Unable to Launch Initial Setup");
                    critical ("%s: %s", error_text, e.message);

                    var error_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                        error_text,
                        _("Initial Setup creates your first user. Without it, you will not be able to log in and may need to reinstall the OS."),
                        "dialog-error",
                        Gtk.ButtonsType.CLOSE
                    );
                    error_dialog.show_error_details (e.message);
                    error_dialog.present ();
                    error_dialog.response.connect (error_dialog.destroy);
                }

                return Source.REMOVE;
            });
        }

        lightdm_greeter.notify_property ("hide-users-hint");
        lightdm_greeter.notify_property ("show-manual-login-hint");
        lightdm_greeter.notify_property ("has-guest-account-hint");
    }

    private void add_card (LightDM.User lightdm_user) {
        var user_card = new Greeter.UserCard (lightdm_user);
        user_card.show_all ();

        carousel.add (user_card);

        user_card.focus_requested.connect (() => {
            switch_to_card (user_card);
        });

        user_card.go_left.connect (() => {
            if (Gtk.StateFlags.DIR_LTR in get_state_flags ()) {
                go_previous ();
            } else {
                go_next ();
            }
        });

        user_card.go_right.connect (() => {
            if (Gtk.StateFlags.DIR_LTR in get_state_flags ()) {
                go_next ();
            } else {
                go_previous ();
            }
        });

        user_card.do_connect.connect (do_connect);

        card_size_group.add_widget (user_card);
        user_cards.push_tail (user_card);
    }

    private unowned GLib.Binding? time_format_binding = null;
    private void switch_to_card (Greeter.UserCard user_card) {
        if (!carousel.interactive) {
            return;
        }

        if (current_card != null && current_card is UserCard) {
            ((UserCard) current_card).show_input = false;
        }

        if (time_format_binding != null) {
            time_format_binding.unbind ();
        }
        time_format_binding = user_card.bind_property ("is-24h", datetime_widget, "is-24h", GLib.BindingFlags.SYNC_CREATE);

        current_card = user_card;

        carousel.scroll_to (user_card);

        user_card.set_settings ();
        user_card.show_input = true;
        user_card.grab_focus ();

        if (user_card.lightdm_user.session != null) {
            get_action_group ("session").activate_action ("select", new GLib.Variant.string (user_card.lightdm_user.session));
        }

        if (lightdm_greeter.in_authentication) {
            try {
                lightdm_greeter.cancel_authentication ();
            } catch (Error e) {
                critical (e.message);
            }
        }

        try {
            lightdm_greeter.authenticate (user_card.lightdm_user.name);
        } catch (Error e) {
            critical (e.message);
        }
    }

    private void do_connect_username (string username) {
        if (lightdm_greeter.in_authentication) {
            try {
                lightdm_greeter.cancel_authentication ();
            } catch (Error e) {
                critical (e.message);
            }
        }

        try {
            lightdm_greeter.authenticate (username);
        } catch (Error e) {
            critical (e.message);
        }
    }

    private void do_connect (string? credential) {
        if (credential != null) {
            try {
                lightdm_greeter.respond (credential);
            } catch (Error e) {
                critical (e.message);
            }
        }

        carousel.interactive = false;
        carousel.scroll_to (current_card);
    }

    private void go_previous () {
        if (!carousel.interactive) {
            return;
        }

        unowned Greeter.UserCard? next_card = user_cards.peek_nth (current_user_card_index - 1);
        if (next_card != null) {
            carousel.scroll_to (next_card);
        }
    }

    private void go_next () {
        if (!carousel.interactive) {
            return;
        }

        unowned Greeter.UserCard? next_card = user_cards.peek_nth (current_user_card_index + 1);
        if (next_card != null) {
            carousel.scroll_to (next_card);
        }
    }
}
