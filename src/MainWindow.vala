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
    private const string STYLESHEET =
        ".composited { background-color: transparent; }";

    public MainWindow () {
        //Object (application: application);
    }

    private GLib.Queue<unowned Greeter.UserCard> user_cards;
    private Gtk.SizeGroup card_size_group;
    private int index_delta = 0;
    private int animation_delta = 0;
    private Gtk.Overlay main_overlay;
    private Greeter.ManualCard manual_card;
    private LightDM.Greeter lightdm_greeter;
    private Greeter.Settings settings;

    construct {
        decorated = false;
        app_paintable = true;
        window_position = Gtk.WindowPosition.CENTER;
        width_request = 200;
        height_request = 150;

        settings = new Greeter.Settings ();
        create_session_selection_action ();

        set_visual (get_screen ().get_rgba_visual());
        var css_provider = new Gtk.CssProvider ();

        try {
            css_provider.load_from_data (STYLESHEET, -1);
            get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            get_style_context ().add_class ("composited");
        } catch (Error e) {}

        destroy.connect (() => {
            Gtk.main_quit ();
        });

        main_overlay = new Gtk.Overlay ();
        main_overlay.margin_top = main_overlay.margin_bottom = 24;

        var guest_login_button = new Gtk.Button.with_label (_("Login as Guest"));
        guest_login_button.hexpand = true;
        var manual_login_button = new Gtk.ToggleButton.with_label (_("Manual Login…"));
        manual_login_button.hexpand = true;
        var extra_login_grid = new Gtk.Grid ();
        extra_login_grid.halign = Gtk.Align.CENTER;
        extra_login_grid.valign = Gtk.Align.END;
        extra_login_grid.orientation = Gtk.Orientation.HORIZONTAL;
        extra_login_grid.column_spacing = 12;
        extra_login_grid.column_homogeneous = true;
        extra_login_grid.add (guest_login_button);
        extra_login_grid.add (manual_login_button);

        try {
            var settings = Gtk.Settings.get_default ();
            css_provider = Gtk.CssProvider.get_named (settings.gtk_theme_name, "dark");
            guest_login_button.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            manual_login_button.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {}

        destroy.connect (() => {
            Gtk.main_quit ();
        });

        var datetime_widget = new Greeter.DateTimeWidget ();
        datetime_widget.halign = Gtk.Align.CENTER;
        datetime_widget.valign = Gtk.Align.START;
        datetime_widget.margin_top = 24;

        user_cards = new GLib.Queue<unowned Greeter.UserCard> ();

        manual_card = new Greeter.ManualCard ();
        manual_card.reveal_child = false;
        main_overlay.add_overlay (manual_card);

        add (main_overlay);
        main_overlay.add_overlay (extra_login_grid);
        main_overlay.add_overlay (datetime_widget);

        main_overlay.get_child_position.connect ((widget, out allocation) => {
            if (widget is Greeter.UserCard) {
                unowned Greeter.UserCard card = (Greeter.UserCard)widget;
                var index = user_cards.index (card) - index_delta;
                int minimum_width, natural_width;
                int minimum_height, natural_height;
                widget.get_preferred_width (out minimum_width, out natural_width);
                widget.get_preferred_height (out minimum_height, out natural_height);
                allocation.x = main_overlay.get_allocated_width ()/2 - natural_width/2 + index * natural_width - animation_delta;
                allocation.y = main_overlay.get_allocated_height ()/2 - natural_height/2;
                allocation.width = natural_width;
                allocation.height = natural_height;
                return true;
            }

            return false;
        });

        manual_login_button.toggled.connect (() => {
            if (manual_login_button.active) {
                user_cards.head.foreach ((card) => {
                    card.reveal_child = false;
                });
                manual_card.reveal_child = true;
            } else {
                manual_card.reveal_child = false;
                user_cards.head.foreach ((card) => {
                    card.reveal_child = true;
                });
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

        maximize ();
        stick ();
        set_keep_below (true);

        lightdm_greeter = new LightDM.Greeter ();
        lightdm_greeter.bind_property ("show-manual-login-hint", manual_login_button, "sensitive", GLib.BindingFlags.SYNC_CREATE);
        lightdm_greeter.bind_property ("has-guest-account-hint", guest_login_button, "sensitive", GLib.BindingFlags.SYNC_CREATE);
        lightdm_greeter.show_message.connect (show_message);
        lightdm_greeter.show_prompt.connect (show_prompt);
        lightdm_greeter.authentication_complete.connect (authentication_complete);
        load_users.begin ();
    }

    private void create_session_selection_action () {
        var select_session_action = new GLib.SimpleAction.stateful ("select", GLib.VariantType.STRING, new GLib.Variant.string (""));
        var vardict = new GLib.VariantDict ();
        unowned GLib.List<LightDM.Session> sessions = LightDM.get_sessions ();
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
        critical ("message: `%s' (%d)", text, type);
        /*var messagetext = string_to_messagetext(text);
        
        if (messagetext == MessageText.FPRINT_SWIPE || messagetext == MessageText.FPRINT_PLACE) {
            // For the fprint module, there is no prompt message from PAM.
            send_prompt (PromptType.FPRINT);
        }  
        
        current_login.show_message (type, messagetext, text);*/
    }

    private void show_prompt (string text, LightDM.PromptType type = LightDM.PromptType.QUESTION) {
        var current_prompt = Greeter.PromptText.from_string (text);
        critical ("prompt: `%s' (%d)", text, type);
        /*send_prompt (lightdm_prompttype_to_prompttype(type), string_to_prompttext(text), text);
        
        had_prompt = true;

        current_login.show_prompt (type, prompttext, text);*/
    }

    private void authentication_complete () {
        var action_group = get_action_group ("session");
        try {
            lightdm_greeter.start_session_sync (action_group.get_action_state ("select").get_string ());
        } catch (Error e) {
            error (e.message);
        }
        /*if (lightdm.is_authenticated) {
            // Check if the LoginMask actually got userinput that confirms
            // that the user wants to start a session now.
            if (had_prompt) {
                // If yes, start a session
                awaiting_start_session = true;
                login_successful ();
            } else {
                message ("Auth complete, but we await user-interaction before we"
                        + "start a session");
                // If no, send a prompt and await the confirmation via respond.
                // This variables is checked in respond as a special case.
                awaiting_confirmation = true;
                current_login.show_prompt (PromptType.CONFIRM_LOGIN);
            }
        } else {
            current_login.not_authenticated ();
        }*/
    }

    private async void load_users () {
        try {
            yield lightdm_greeter.connect_to_daemon (null);
        } catch (Error e) {
            critical (e.message);
        }

        unowned LightDM.UserList lightdm_user_list = LightDM.UserList.get_instance ();
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
            try {
                lightdm_greeter.authenticate (user_card.lightdm_user.name);
            } catch (Error e) {
                critical (e.message);
            }
        }

        if (lightdm_greeter.default_session_hint != null) {
            get_action_group ("session").activate_action ("select", new GLib.Variant.string (lightdm_greeter.default_session_hint));
        }
    }

    private void add_card (LightDM.User lightdm_user) {
        var user_card = new Greeter.UserCard (lightdm_user);
        user_card.show_all ();
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

        user_card.notify["child-revealed"].connect (() => {
            if (user_card.child_revealed) {
                settings.last_user = user_card.lightdm_user.name;
            }
        });

        card_size_group.add_widget (user_card);
        user_cards.push_tail (user_card);
    }

    int distance = 0;
    int next_delta = 0;
    private void switch_to_card (Greeter.UserCard user_card) {
        if (next_delta != index_delta) {
            return;
        }

        next_delta = user_cards.index (user_card);
        int minimum_width, natural_width;
        user_card.get_preferred_width (out minimum_width, out natural_width);
        distance = (next_delta - index_delta) * natural_width;
        user_card.notify["reveal-ratio"].connect (notify_cb);
        user_card.show_input = true;
        if (index_delta != next_delta) {
            ((Greeter.UserCard) user_cards.peek_nth (index_delta)).show_input = false;
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
