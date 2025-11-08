/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2018-2025 elementary, Inc. (https://elementary.io)
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class Greeter.MainWindow : Gtk.ApplicationWindow {
    public LightDM.Greeter lightdm_greeter { private get; construct; }

    private Pantheon.Desktop.Greeter? desktop_greeter;
    private Hdy.Carousel carousel;
    private Greeter.Settings settings;
    private GLib.Settings gsettings;
    private Gtk.Revealer datetime_revealer;
    private DateTimeWidget datetime_widget;

    private int current_user_card_index = 0;
    private unowned BaseCard? current_card;

    private bool installer_mode = false;

    private Gtk.EventControllerKey key_controller;

    public MainWindow (LightDM.Greeter lightdm_greeter) {
        Object (lightdm_greeter: lightdm_greeter);
    }

    construct {
        app_paintable = true;
        decorated = false;
        set_visual (get_screen ().get_rgba_visual ());

        gsettings = new GLib.Settings ("io.elementary.greeter");
        settings = new Greeter.Settings ();

        lightdm_greeter.show_message.connect (show_message);
        lightdm_greeter.show_prompt.connect (show_prompt);
        lightdm_greeter.authentication_complete.connect (authentication_complete);

        datetime_widget = new DateTimeWidget ();

        datetime_revealer = new Gtk.Revealer () {
            child = datetime_widget,
            transition_type = CROSSFADE,
            valign = CENTER,
            vexpand = true
        };

        carousel = new Hdy.Carousel () {
            allow_long_swipes = true,
            vexpand = true
        };

        // We need to load users here because guest and manual cards are supposed to be at the end
        load_users ();

        if (lightdm_greeter.has_guest_account_hint) {
            var guest_card = new GuestCard ();
            guest_card.show_all ();
            guest_card.do_connect.connect (() => {
                try {
                    lightdm_greeter.authenticate_as_guest ();
                } catch (Error e) {
                    critical (e.message);
                }
            });

            carousel.add (guest_card);
        }

        if (lightdm_greeter.show_manual_login_hint) {
            var manual_card = new ManualCard ();
            manual_card.show_all ();
            manual_card.do_connect_username.connect (do_connect_username);
            manual_card.do_connect.connect (do_connect);

            carousel.add (manual_card);
        }

        var main_box = new Gtk.Box (VERTICAL, 24) {
            margin_top = 24,
            margin_bottom = 24
        };
        main_box.add (datetime_revealer);
        main_box.add (carousel);

        child = main_box;

        key_controller = new Gtk.EventControllerKey (this) {
            propagation_phase = CAPTURE
        };
        key_controller.key_pressed.connect ((keyval, keycode, state) => {
            unowned var focused_entry = get_focus () as Gtk.Entry;
            if (focused_entry == null || !focused_entry.is_ancestor (current_card) || focused_entry.text != "") {
                return Gdk.EVENT_PROPAGATE;
            }

            var ltr = Gtk.StateFlags.DIR_LTR in get_state_flags ();

            if (keyval == Gdk.Key.Left && ltr || keyval == Gdk.Key.Right && !ltr) {
                go_previous ();
                return Gdk.EVENT_STOP;
            } else if (keyval == Gdk.Key.Right && ltr || keyval == Gdk.Key.Left && !ltr) {
                go_next ();
                return Gdk.EVENT_STOP;
            }

            return Gdk.EVENT_PROPAGATE;
        });

        carousel.page_changed.connect ((index) => {
            var children = carousel.get_children ();

            if (children.nth_data (index) is Greeter.UserCard) {
                current_user_card_index = (int) index;
            }
        });

        /* A significant delay is required in order for the window and card to be focused at
            * at boot.  TODO: Find whether boot sequence can be tweaked to fix this.
            */
        Timeout.add (500, () => {
            get_style_context ().add_class ("initialized");

            if (current_card != null) {
                current_card.grab_focus ();
            }

            return Source.REMOVE;
        });

        maximize ();

        if (settings.activate_numlock) {
            try {
                Process.spawn_async (null, { "numlockx", "on" }, null, SpawnFlags.SEARCH_PATH, null, null);
            } catch (Error e) {
                warning ("Unable to spawn numlockx to set numlock state");
            }
        }

        main_box.realize.connect (init_panel);
    }

    private void init_panel () {
        if (Gdk.Display.get_default () is Gdk.Wayland.Display) {
            // We have to wrap in Idle otherwise the Meta.Window of the WaylandSurface in Gala is still null
            Idle.add_once (init_wl);
        } else {
            init_x ();
        }
    }

    private static Wl.RegistryListener registry_listener;
    private void init_wl () {
        registry_listener.global = registry_handle_global;
        unowned var display = Gdk.Display.get_default ();
        if (display is Gdk.Wayland.Display) {
            unowned var wl_display = ((Gdk.Wayland.Display) display).get_wl_display ();
            var wl_registry = wl_display.get_registry ();
            wl_registry.add_listener (
                registry_listener,
                this
            );

            if (wl_display.roundtrip () < 0) {
                return;
            }
        }
    }

    public void registry_handle_global (Wl.Registry wl_registry, uint32 name, string @interface, uint32 version) {
        if (@interface == "io_elementary_pantheon_shell_v1") {
            var desktop_shell = wl_registry.bind<Pantheon.Desktop.Shell> (name, ref Pantheon.Desktop.Shell.iface, uint32.min (version, 1));
            unowned var window = get_window ();
            if (window is Gdk.Wayland.Window) {
                unowned var wl_surface = ((Gdk.Wayland.Window) window).get_wl_surface ();
                desktop_greeter = desktop_shell.get_greeter (wl_surface);
                desktop_greeter.init ();
            }
        }
    }

    private void init_x () {
        var display = Gdk.Display.get_default ();
        if (display is Gdk.X11.Display) {
            unowned var xdisplay = ((Gdk.X11.Display) display).get_xdisplay ();

            var window = ((Gdk.X11.Window) get_window ()).get_xid ();

            var prop = xdisplay.intern_atom ("_MUTTER_HINTS", false);

            var value = "greeter=1";

            xdisplay.change_property (window, prop, X.XA_STRING, 8, 0, (uchar[]) value, value.length);
        }
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
    }

    private void show_prompt (string text, LightDM.PromptType type) {
        if (current_card is ManualCard) {
            var manual_card = (ManualCard) current_card;

            switch (type) {
                case QUESTION:
                    manual_card.wrong_username ();
                    break;
                case SECRET:
                    manual_card.ask_password ();
                    break;
            }
        }
    }

    // Called after the credentials are checked, might be authenticated or not.
    private void authentication_complete () {
        var user_card = current_card as Greeter.UserCard;
        if (user_card != null) {
            gsettings.set_string ("last-user", user_card.lightdm_user.name);
        }

        if (lightdm_greeter.is_authenticated) {
            try {
                unowned var session = application.get_action_state ("select-session").get_string ();

                // If the greeter is running on the install medium, check if the Installer has signalled
                // that it wants the greeter to launch the live (demo) session by means of touching a file
                if (installer_mode) {
                    var demo_mode_file = File.new_for_path ("/var/lib/lightdm/demo-mode");
                    if (demo_mode_file.query_exists ()) {
                        demo_mode_file.@delete ();
                        session = "pantheon";
                    } else {
                        session = "installer";
                    }
                }

                gsettings.set_string ("last-session-type", session);
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

    private void load_users () {
        // Check if the installer is installed
        var installer_desktop = new DesktopAppInfo ("io.elementary.installer.desktop");
        if (installer_desktop != null) {
            installer_mode = true;
        }

        unowned var lightdm_user_list = LightDM.UserList.get_instance ();
        if (lightdm_user_list.length > 0) {
            datetime_revealer.reveal_child = true;

            lightdm_user_list.users.foreach (add_card);

            unowned var user_to_select = lightdm_greeter.select_user_hint ?? gsettings.get_string ("last-user");

            bool user_selected = false;
            foreach (unowned var carousel_child in carousel.get_children ()) {
                assert (carousel_child is BaseCard);
                unowned var card = (BaseCard) carousel_child;

                if (card is UserCard && ((UserCard) card).lightdm_user.name == user_to_select) {
                    switch_to_card (card);
                    user_selected = true;
                }
            }

            if (!user_selected) {
                unowned var first_carousel_child = carousel.get_children ().first ().data;
                assert (first_carousel_child is BaseCard);

                switch_to_card ((BaseCard) first_carousel_child);
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
    }

    private void switch_to_card (Greeter.BaseCard card) {
        if (!carousel.interactive) {
            return;
        }

        current_card?.hide_card_content ();

        card.reveal_card_content ();
        card.grab_focus ();
        carousel.scroll_to (card);
        current_card = card;

        if (lightdm_greeter.in_authentication) {
            try {
                lightdm_greeter.cancel_authentication ();
            } catch (Error e) {
                critical (e.message);
            }
        }

        if (card is UserCard) {
            var user_card = (UserCard) card;
            datetime_widget.is_24h = user_card.is_24h;
            user_card.set_settings ();

            if (user_card.lightdm_user.session != null) {
                application.activate_action ("select-session", new GLib.Variant.string (user_card.lightdm_user.session));
            }

            try {
                lightdm_greeter.authenticate (user_card.lightdm_user.name);
            } catch (Error e) {
                critical (e.message);
            }
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
        if (!carousel.interactive || current_user_card_index - 1 < 0) {
            return;
        }

        unowned var carousel_child = carousel.get_children ().nth_data (current_user_card_index - 1);
        if (carousel_child != null) {
            carousel.scroll_to (carousel_child);
        }
    }

    private void go_next () {
        if (!carousel.interactive || current_user_card_index + 1 >= carousel.n_pages) {
            return;
        }

        unowned var carousel_child = carousel.get_children ().nth_data (current_user_card_index + 1);
        if (carousel_child != null) {
            carousel.scroll_to (carousel_child);
        }
    }
}
