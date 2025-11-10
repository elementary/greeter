/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2018-2025 elementary, Inc. (https://elementary.io)
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public abstract class Greeter.BaseCard : Gtk.Bin {
    public signal void do_connect (string? credential = null);

    protected const int ERROR_SHAKE_DURATION = 450;

    /*
     * Unique identifier of the card.
     * User card uses User + uid
     * Manual card -- "manual"
     * Guest card -- "guest"
     */
    public string card_identifier { protected get; construct; }
    public string selected_session { private get; construct; }

    public bool connecting { get; set; default = false; }
    public bool need_password { get; set; default = false; }
    public bool use_fingerprint { get; set; default = false; }

    public unowned string selected_session_type {
        get {
            return select_session_action.state.get_string ();
        }
    }

    protected SimpleAction select_session_action;

    private static bool has_pantheon_x11_session;
    private static GLib.Settings a11y_settings;
    private static bool sent_x11_a11y_notification = false;

    static construct {
        LightDM.get_sessions ().foreach ((session) => {
            if (session.key == "pantheon") {
                has_pantheon_x11_session = true;
            }
        });

        a11y_settings = new GLib.Settings ("org.gnome.desktop.a11y.applications");
    }

    protected BaseCard (string card_identifier, string selected_session) {
        Object (card_identifier: card_identifier, selected_session: selected_session);
    }

    construct {
        select_session_action = new GLib.SimpleAction.stateful ("select-session", GLib.VariantType.STRING, selected_session);
        var vardict = new GLib.VariantDict ();
        LightDM.get_sessions ().foreach ((session) => vardict.insert_value (session.name, new GLib.Variant.string (session.key)));
        select_session_action.set_state_hint (vardict.end ());

        var action_group = new SimpleActionGroup ();
        action_group.add_action (select_session_action);
        insert_action_group (card_identifier, action_group);

        select_session_action.change_state.connect ((value) => {
            select_session_action.set_state (value);

            if (value.get_string () != "pantheon") {
                sent_x11_a11y_notification = false;
            }
        });

        if (has_pantheon_x11_session) {
            a11y_settings.changed.connect ((key) => {
                if (key != "screen-keyboard-enabled" && key != "screen-reader-enabled") {
                    return;
                }

                if (!a11y_settings.get_boolean (key)) {
                    return;
                }

                if (select_session_action.state.get_string () != "pantheon-wayland") {
                    return;
                }

                select_session_action.set_state (new Variant.string ("pantheon"));
                send_x11_a11y_notification ();
            });
        }

        halign = CENTER;
        valign = CENTER;
        width_request = 350;
    }

    private static void send_x11_a11y_notification () {
        // Avoid sending notification for every card
        if (sent_x11_a11y_notification) {
            return;
        }

        sent_x11_a11y_notification = true;

        var notification = new Notification (_("Classic session automatically selected"));
        notification.set_body (_("Accessibility features may be unavailable in the Secure session"));
        notification.set_icon (new ThemedIcon ("preferences-desktop-accessibility"));

        GLib.Application.get_default ().send_notification ("session-type", notification);
    }

    public abstract void wrong_credentials ();
}
