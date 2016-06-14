/*
* Copyright (c) 2011-2016 elementary LLC. (http://launchpad.net/pantheon-greeter)
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
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
*/

public class CredentialsAreaActor : GtkClutter.Actor {
    CredentialsArea credentials;
    public string current_session { get; set; }

    const string SHAKE_STYLE_CSS = """
        @keyframes shake {
	        0% { padding-left: 0 }
	        25% { padding-left: 64px }
	        50% { padding-left: 0 }
	        75% { padding-left: 32px }
	        100% { padding-left: 0}
        }

        .shake {
	        animation: shake 0.4s ease-in-out 1;
        }
    """;

    /**
     * Fired when the user has replied to a prompt (aka: password,
     * login-button was pressed). Should get forwarded to the
     * LoginGateway.
     */
    public signal void replied (string text);
    public signal void entered_login_name (string name);

    Gtk.Entry? login_name_entry = null;
    Gtk.Grid grid;
    Gtk.Revealer revealer;
    Gtk.ListBox settings_list;

    LoginBox login_box;

    public string login_name {
        get {
            return login_name_entry.text;
        }
    }

    public CredentialsAreaActor (LoginBox login_box, LoginOption login_option) {
        this.login_box = login_box;
        current_session = login_option.session;
        height = 188;
        credentials = null;

        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_data (SHAKE_STYLE_CSS, SHAKE_STYLE_CSS.length);
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            critical (e.message);
        }        

        var login_name_label = new Gtk.Label (login_option.get_markup ());
        login_name_label.get_style_context ().add_class ("h2");
        login_name_label.set_xalign (0);
        login_name_label.width_request = 260;

        login_name_entry = new Gtk.Entry ();
        login_name_entry.halign = Gtk.Align.START;
        login_name_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "avatar-default-symbolic");
        login_name_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "go-jump-symbolic");
        login_name_entry.width_request = 260;

        var settings = new Gtk.ToggleButton ();
        settings.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings.image = new Gtk.Image.from_icon_name ("application-menu-symbolic", Gtk.IconSize.MENU);
        settings.set_size_request (32, 32);
        settings.valign = Gtk.Align.CENTER;

        settings_list = new Gtk.ListBox ();
        settings_list.margin_bottom = 3;
        settings_list.margin_top = 3;

        var settings_popover = new Gtk.Popover (settings);
        settings_popover.position = Gtk.PositionType.BOTTOM;
        settings_popover.add (settings_list);
        settings_popover.bind_property ("visible", settings, "active", GLib.BindingFlags.BIDIRECTIONAL);

        grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.row_spacing = 12;

        if (login_option.provides_login_name) {
            grid.attach (login_name_label, 0, 0, 1, 1);
        } else {
            grid.attach (login_name_entry, 0, 0, 1, 1);
        }

        if (LightDM.get_sessions ().length () > 1) {
            create_settings_items ();
            grid.attach (settings, 1, 0, 1, 1);
        }

        revealer = new Gtk.Revealer ();
        revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        revealer.add (grid);

        connect_signals ();

        ((Gtk.Container) this.get_widget ()).add (revealer);
        this.get_widget ().show_all ();
    }

    void connect_signals () {
        login_name_entry.activate.connect (() => {
            entered_login_name (login_name_entry.text);
        });

        login_name_entry.focus_in_event.connect ((e) => {
            remove_credentials ();
            return false;
        });

        login_name_entry.icon_press.connect ((pos, event) => {
            if (pos == Gtk.EntryIconPosition.SECONDARY) {
                entered_login_name (login_name_entry.text);
            }
        });

        replied.connect ((answer) => {
            login_name_entry.sensitive = false;
        });
    }

    public bool reveal {
        set {
            revealer.reveal_child = value;
        }
    }

    public void shake () {
        revealer.get_style_context ().add_class ("shake");
        Timeout.add (500, () => {
            revealer.get_style_context ().remove_class ("shake");
            return false;
        });
    }

    public void remove_credentials () {
        if (credentials != null) {
            grid.remove (credentials);
            credentials = null;
        }
    }

    public void pass_focus () {
        if (credentials != null) {
            credentials.pass_focus ();
        }
        if (login_name_entry != null) {
            login_name_entry.grab_focus ();
        }
    }

    public void show_prompt (PromptType type) {
        remove_credentials ();

        switch (type) {
            case PromptType.PASSWORD:
                credentials = new PasswordArea ();
                break;
            case PromptType.CONFIRM_LOGIN:
                credentials = new LoginButtonArea ();
                break;
            default:
                warning (@"Not implemented $(type.to_string ())");
                return;
        }
        grid.attach (credentials, 0, 1, 1, 1);
        credentials.replied.connect ((answer) => {
            this.replied (answer);
        });
        grid.show_all ();

        // We have to check if we are selected as we don't want to steal
        // the focus from other logins. This would for example happen
        // with the manual login as it can't directly start the login
        // and therefore the previous login is still communicating with
        // the LoginGateway until the manual login got a username (and is
        // now the LoginMask that recieves the LightDM-responses).
        if (login_box.selected)
            credentials.pass_focus ();

        // Prevents that the user changes his login name during
        // the authentication process.
        if (login_name_entry != null)
            login_name_entry.sensitive = true;
    }

    void create_settings_items () {
        var button = new Gtk.RadioButton.with_label (null, LightDM.get_sessions ().nth_data (0).name);
        button.margin_left = 6;
        button.margin_right = 6;
        button.active = LightDM.get_sessions ().nth_data (0).key == current_session;

        button.toggled.connect (() => {
            if (button.active) {
                current_session = LightDM.get_sessions ().nth_data (0).key;
            }
        });

        var button_row = new Gtk.ListBoxRow ();
        button_row.get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);
        button_row.add (button);
        settings_list.add (button_row);

        for (var i = 1; i < LightDM.get_sessions ().length (); i++) {
            var radio = new Gtk.RadioButton.with_label_from_widget (button, LightDM.get_sessions ().nth_data (i).name);
            radio.margin_left = 6;
            radio.margin_right = 6;

            var radio_row = new Gtk.ListBoxRow ();
            radio_row.get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);
            radio_row.add (radio);
            settings_list.add (radio_row);

            var identifier = LightDM.get_sessions ().nth_data (i).key;
            radio.active = identifier == current_session;
            radio.toggled.connect ( () => {
                if (radio.active) {
                    current_session = identifier;
                }
            });
        }

        settings_list.show_all ();
    }
}
