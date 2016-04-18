// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
* Copyright (c) 2011-2016 APP Developers (http://launchpad.net/pantheon-greeter)
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

public class LoginBox : GtkClutter.Actor, LoginMask {

    SelectableAvatar avatar = null;

    CredentialsAreaActor credentials_actor;

    LoginOption user;

    bool _selected = false;
    public bool selected {
        get {
            return _selected;
        }
        set {
            _selected = value;
            int opacity = 0;
            credentials_actor.remove_credentials ();
            if (value) {
                opacity = 255;
                if (avatar != null) {
                    avatar.select ();
                }

            } else {

                if (avatar != null) {
                    avatar.deselect ();
                }
            }

            credentials_actor.save_easing_state ();
            credentials_actor.set_easing_mode (Clutter.AnimationMode.EASE_IN_OUT_QUAD);
            credentials_actor.set_easing_duration (200);
            credentials_actor.opacity = opacity;
            credentials_actor.restore_easing_state ();
        }
    }

    public LoginBox (LoginOption user) {
        this.user = user;
        this.reactive = true;
        this.pivot_point = Clutter.Point.alloc ().init (0.5f, 0.5f);

        create_credentials ();

        if (user.avatar_ready) {
            update_avatar ();
        } else {
            user.avatar_updated.connect (() => {
                update_avatar ();
            });
        }
    }

    void create_credentials () {
        credentials_actor = new CredentialsAreaActor (this, user);
        credentials_actor.x = this.x + 124;
        credentials_actor.y = 5;
        add_child (credentials_actor);

        credentials_actor.replied.connect ((answer) => {
            credentials_actor.remove_credentials ();
            PantheonGreeter.login_gateway.respond (answer);
        });

        credentials_actor.entered_login_name.connect ((name) => {
            start_login ();
        });
    }

    /**
     * Starts the login procedure. Necessary to call this before the user
     * can enter something so that the LoginGateway can tell
     * us what kind of prompt he wants.
     */
    void start_login () {
        PantheonGreeter.login_gateway.login_with_mask (this, user.is_guest);
    }

    void update_avatar () {
        if (avatar != null) {
            avatar.dismiss ();
        }

        avatar = new SelectableAvatar (user);
        add_child (avatar);

        if (selected) {
            avatar.select ();
        }
    }

    public void pass_focus () {
        // We can't start the login when the login option isn't
        // providing a name without user interaction.
        if (user.provides_login_name) {
            start_login ();
        }
        credentials_actor.pass_focus ();
    }

    /* The relative positions to the previous one the shake function should
     * use. The values get smaller because the shaking should fade out to
     * look smooth.
     */
    float[] shake_positions = {50, -80, 60, -30, 50, -80, 30};

    /**
     * Shakes the LoginBox and then sets selected back to true.
     */
    void shake (int num = 0) {
        if (num >= shake_positions.length) {
            start_login ();
            return;
        }
        var transition = new Clutter.PropertyTransition ("x");
        transition.animatable = this;
        transition.set_duration (60);
        transition.set_progress_mode (Clutter.AnimationMode.EASE_IN_OUT_CIRC);
        transition.set_from_value (this.x);
        transition.set_to_value (this.x + shake_positions[num]);
        transition.remove_on_complete = true;
        transition.auto_reverse = false;
        transition.completed.connect (() => {
            shake (num + 1);
        });
        this.add_transition ("shake" + num.to_string (), transition);
    }

    /* LoginMask interface */
    public string login_session {
        get {
            return credentials_actor.current_session;
        }
    }

    public string login_name {
        get {
            if (user.provides_login_name) {
                return user.name;
            }
            return credentials_actor.login_name;
        }
    }

    public void show_prompt (PromptType type) {
        credentials_actor.show_prompt (type);
    }

    public void show_message (MessageType type) {
        credentials_actor.remove_credentials ();
        shake ();
    }


    public void login_aborted () {
        credentials_actor.remove_credentials ();
    }

    /* End of LoginMask interface */

    /**
     * Actor that holds the entries for entering name, password, login-button
     * etc. Will fade out when the LoginBox is deselected to keep the UI
     * clean.
     */
    class CredentialsAreaActor : GtkClutter.Actor {
        CredentialsArea credentials;
        public string current_session { get; set; }

        /**
         * Fired when the user has replied to a prompt (aka: password,
         * login-button was pressed). Should get forwarded to the
         * LoginGateway.
         */
        public signal void replied (string text);
        public signal void entered_login_name (string name);

        Gtk.Entry? login_name_entry = null;
        Gtk.Grid grid;
        Gtk.Grid settings_grid;
        Gtk.Popover settings_popover;
        Gtk.ToggleButton settings;

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

            var login_name_label = new Gtk.Label (login_option.get_markup ());
            login_name_label.get_style_context ().add_class ("h2");
            login_name_label.set_xalign (0);
            login_name_label.width_request = 260;

            login_name_entry = new Gtk.Entry ();
            login_name_entry.halign = Gtk.Align.START;
            login_name_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "avatar-default-symbolic");
            login_name_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "go-jump-symbolic");
            login_name_entry.width_request = 260;

            settings = new Gtk.ToggleButton ();
            settings.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            settings.add (new Gtk.Image.from_icon_name ("application-menu-symbolic", Gtk.IconSize.MENU));
            settings.set_size_request (32, 32);
            settings.valign = Gtk.Align.CENTER;

            settings_grid = new Gtk.Grid ();
            settings_grid.margin_bottom = 3;
            settings_grid.margin_top = 3;
            settings_grid.orientation = Gtk.Orientation.VERTICAL;

            settings_popover = new Gtk.Popover (settings);
            settings_popover.set_position (Gtk.PositionType.BOTTOM);
            settings_popover.add (settings_grid);

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

            connect_signals ();

            ((Gtk.Container) this.get_widget ()).add (grid);
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

            settings_popover.closed.connect (() => {
                settings.active = false;
            });

            settings.toggled.connect (() => {
                settings_popover.show_all ();
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
            var but = new Gtk.RadioButton.with_label (null, LightDM.get_sessions ().nth_data (0).name);
            but.get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);
            but.active = LightDM.get_sessions ().nth_data (0).key == current_session;

            but.toggled.connect (() => {
                if (but.active) {
                    current_session = LightDM.get_sessions ().nth_data (0).key;
                }
            });

            settings_grid.add (but);

            for (var i = 1; i < LightDM.get_sessions ().length (); i++) {
                var rad = new Gtk.RadioButton.with_label_from_widget (but, LightDM.get_sessions ().nth_data (i).name);
                rad.get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);
                settings_grid.add (rad);

                rad.active = LightDM.get_sessions ().nth_data (i).key == current_session;
                var identifier = LightDM.get_sessions ().nth_data (i).key;
                rad.toggled.connect ( () => {
                    if (rad.active)
                        current_session = identifier;
                });
            }
        }
    }
}
