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

public class Greeter.MainWindow : Gtk.ApplicationWindow {
    protected static Gtk.CssProvider css_provider;

    private GLib.Queue<unowned Greeter.UserCard> user_cards;
    private Gtk.SizeGroup card_size_group;
    private int index_delta = 0;
    private int animation_delta = 0;
    private Gtk.Overlay main_overlay;
    private LightDM.Greeter lightdm_greeter;
    private Greeter.Settings settings;
    private Gtk.ToggleButton manual_login_button;
    private Greeter.DateTimeWidget datetime_widget;
    private unowned Greeter.BaseCard current_card;
    private unowned LightDM.UserList lightdm_user_list;

    private const uint[] NAVIGATION_KEYS = {
        Gdk.Key.Up,
        Gdk.Key.Down,
        Gdk.Key.Left,
        Gdk.Key.Right,
        Gdk.Key.Return,
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

        var guest_login_button = new Gtk.Button.with_label (_("Log in as Guest"));

        manual_login_button = new Gtk.ToggleButton.with_label (_("Manual Login…"));

        var extra_login_grid = new Gtk.Grid ();
        extra_login_grid.halign = Gtk.Align.CENTER;
        extra_login_grid.valign = Gtk.Align.END;
        extra_login_grid.column_spacing = 12;
        extra_login_grid.column_homogeneous = true;

        try {
            var gtksettings = Gtk.Settings.get_default ();
            gtksettings.gtk_icon_theme_name = "elementary";
            gtksettings.gtk_theme_name = "elementary";

            var css_provider = Gtk.CssProvider.get_named (gtksettings.gtk_theme_name, "dark");
            guest_login_button.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            manual_login_button.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {}

        datetime_widget = new Greeter.DateTimeWidget ();
        datetime_widget.halign = Gtk.Align.CENTER;

        user_cards = new GLib.Queue<unowned Greeter.UserCard> ();

        var manual_card = new Greeter.ManualCard ();

        main_overlay = new Gtk.Overlay ();
        main_overlay.vexpand = true;
        main_overlay.add_overlay (manual_card);

        var main_grid = new Gtk.Grid ();
        main_grid.margin_top = main_grid.margin_bottom = 24;
        main_grid.row_spacing = 24;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (datetime_widget);
        main_grid.add (main_overlay);
        main_grid.add (extra_login_grid);

        add (main_grid);

        main_overlay.get_child_position.connect ((widget, out allocation) => {
            if (widget is Greeter.UserCard && widget.is_visible ()) {
                unowned Greeter.UserCard card = (Greeter.UserCard)widget;
                var index = user_cards.index (card) - index_delta;
                int minimum_width, natural_width;
                int minimum_height, natural_height;
                widget.get_preferred_width (out minimum_width, out natural_width);
                widget.get_preferred_height (out minimum_height, out natural_height);
                allocation.x = main_overlay.get_allocated_width () / 2 - natural_width / 2 + index * natural_width - animation_delta;
                allocation.y = main_overlay.get_allocated_height () / 2 - natural_height / 2;
                allocation.width = natural_width;
                allocation.height = natural_height;
                return true;
            }

            return false;
        });

        manual_login_button.bind_property ("active", manual_card, "reveal-child", GLib.BindingFlags.SYNC_CREATE);
        manual_login_button.toggled.connect (() => {
            if (manual_login_button.active) {
                if (lightdm_greeter.in_authentication) {
                    try {
                        lightdm_greeter.cancel_authentication ();
                    } catch (Error e) {
                        critical (e.message);
                    }
                }

                current_card = manual_card;
            } else {
                if (lightdm_greeter.in_authentication) {
                    try {
                        lightdm_greeter.cancel_authentication ();
                    } catch (Error e) {
                        critical (e.message);
                    }
                }

                current_card = user_cards.peek_nth (index_delta);
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

        GLib.ActionEntry entries[] = {
            GLib.ActionEntry () {
                name = "previous",
                activate = go_previous
            },
            GLib.ActionEntry () {
                name = "next",
                activate = go_next
            }
        };

        card_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        card_size_group.add_widget (extra_login_grid);
        card_size_group.add_widget (manual_card);

        add_action_entries (entries, this);

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

        key_press_event.connect ((event) => {
            // arrow key is being used to navigate
            if (event.keyval in NAVIGATION_KEYS) {
                if (current_card is UserCard) {
                    weak Gtk.Widget? current_focus = get_focus ();
                    if (current_focus is Gtk.Entry && current_focus.is_ancestor (current_card)) {
                        if (((Gtk.Entry) current_focus).text == "") {
                            if (event.keyval == Gdk.Key.Left) {
                                if (get_style_context ().direction == Gtk.TextDirection.RTL) {
                                    activate_action ("next", null);
                                } else {
                                    activate_action ("previous", null);
                                }
                                return true;
                            } else if (event.keyval == Gdk.Key.Right) {
                                if (get_style_context ().direction == Gtk.TextDirection.RTL) {
                                    activate_action ("previous", null);
                                } else {
                                    activate_action ("next", null);
                                }
                                return true;
                            }
                        }
                    }
                }

                return false;
            }

            // Don't focus if it is a modifier or if search_box is already focused
            weak Gtk.Widget? current_focus = get_focus ();
            if ((event.is_modifier == 0) && (current_focus == null || !current_focus.is_ancestor (current_card))) {
                current_card.grab_focus ();
            }

            return false;
        });

        add_events (Gdk.EventMask.SCROLL_MASK);

        scroll_event.connect ((event) => {
            switch (event.direction) {
                case Gdk.ScrollDirection.UP:
                case Gdk.ScrollDirection.LEFT:
                    activate_action ("previous", null);
                    break;
                case Gdk.ScrollDirection.DOWN:
                case Gdk.ScrollDirection.RIGHT:
                    activate_action ("next", null);
                    break;
            }
            return false;
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
        int x, y;
        var display = Gdk.Display.get_default ();
        display.get_pointer (null, out x, out y, null);
        var monitor = display.get_monitor_at_point (x, y);
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
                lightdm_greeter.start_session_sync (action_group.get_action_state ("select").get_string ());
                return;
            } catch (Error e) {
                var error_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Unable to Log In"),
                    _("Starting the session has failed."),
                    "dialog-error",
                    Gtk.ButtonsType.CLOSE
                );
                error_dialog.show_error_details (e.message);
                error_dialog.run ();
                error_dialog.destroy ();
            }
        }

        if (current_card is Greeter.UserCard) {
            switch_to_card ((Greeter.UserCard) current_card);
        }

        current_card.connecting = false;
        current_card.wrong_credentials ();
    }

    private async void load_users () {
        try {
            yield lightdm_greeter.connect_to_daemon (null);
        } catch (Error e) {
            critical (e.message);
        }

        lightdm_greeter.notify_property ("show-manual-login-hint");
        lightdm_greeter.notify_property ("has-guest-account-hint");

        if (lightdm_greeter.default_session_hint != null) {
            get_action_group ("session").activate_action ("select", new GLib.Variant.string (lightdm_greeter.default_session_hint));
        }

        if (lightdm_user_list.length > 0) {
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
                unowned Greeter.UserCard user_card = (Greeter.UserCard) user_cards.peek_head ();
                user_card.show_input = true;
                switch_to_card (user_card);
            }
        } else {
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
                    error_dialog.run ();
                    error_dialog.destroy ();
                }

                return Source.REMOVE;
            });
        }

        lightdm_greeter.notify_property ("hide-users-hint");
    }

    private void add_card (LightDM.User lightdm_user) {
        var user_card = new Greeter.UserCard (lightdm_user);
        user_card.show_all ();
        manual_login_button.bind_property ("active", user_card, "reveal-child", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
        main_overlay.add_overlay (user_card);
        user_card.focus_requested.connect (() => {
            switch_to_card (user_card);
        });

        user_card.go_left.connect (() => {
            if (get_style_context ().direction == Gtk.TextDirection.RTL) {
                activate_action ("next", null);
            } else {
                activate_action ("previous", null);
            }
        });

        user_card.go_right.connect (() => {
            if (get_style_context ().direction == Gtk.TextDirection.RTL) {
                activate_action ("previous", null);
            } else {
                activate_action ("next", null);
            }
        });

        user_card.do_connect.connect (do_connect);

        card_size_group.add_widget (user_card);
        user_cards.push_tail (user_card);
    }

    int distance = 0;
    int next_delta = 0;
    weak GLib.Binding? binding = null;
    private void switch_to_card (Greeter.UserCard user_card) {
        if (next_delta != index_delta) {
            return;
        }

        current_card = user_card;
        if (binding != null) {
            binding.unbind ();
        }

        binding = user_card.bind_property ("is-24h", datetime_widget, "is-24h", GLib.BindingFlags.SYNC_CREATE);
        next_delta = user_cards.index (user_card);
        int minimum_width, natural_width;
        user_card.get_preferred_width (out minimum_width, out natural_width);
        distance = (next_delta - index_delta) * natural_width;
        user_card.notify["reveal-ratio"].connect (notify_cb);
        user_card.show_input = true;
        user_card.grab_focus ();
        if (index_delta != next_delta) {
            ((Greeter.UserCard) user_cards.peek_nth (index_delta)).show_input = false;
        }

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

    private void notify_cb (GLib.Object obj, GLib.ParamSpec spec) {
        unowned Greeter.UserCard user_card = (Greeter.UserCard) obj;
        if (user_card.reveal_ratio == 1.0) {
            index_delta = next_delta;
            animation_delta = 0;
            distance = 0;
            user_card.notify["reveal-ratio"].disconnect (notify_cb);
            user_card.queue_allocate ();
            return;
        }

        animation_delta = (int) (user_card.reveal_ratio * distance);
        main_overlay.queue_allocate ();
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
    }

    private void go_previous (GLib.SimpleAction action, GLib.Variant? parameter) {
        unowned Greeter.UserCard? next_card = (Greeter.UserCard) user_cards.peek_nth (index_delta - 1);
        if (next_card != null) {
            switch_to_card (next_card);
        }
    }

    private void go_next (GLib.SimpleAction action, GLib.Variant? parameter) {
        unowned Greeter.UserCard? next_card = (Greeter.UserCard) user_cards.peek_nth (index_delta + 1);
        if (next_card != null) {
            switch_to_card (next_card);
        }
    }
}
