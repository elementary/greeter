// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2014 elementary Developers

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/

using Gtk;

public class LoginBox : GtkClutter.Actor, LoginMask {

    SelectableAvatar old_avatar = null;

    CredentialsAreaActor credentials_actor;
    ShadowedLabel label;

    LoginOption user;

    bool _selected = false;
    public bool selected {
        get {
            return _selected;
        }
        set {
            _selected = value;
            int opacity = 0;
            if (value) {
                opacity = 255;
                if (old_avatar != null)
                    old_avatar.select ();

                // LoginOption is not providing a name, so the CredentialsArea
                // will display a Gtk.Entry for that and we need to hide
                // the label that would otherwise be at the same position
                // as the mentioned entry.
                if (!user.provides_login_name)
                    label.animate (Clutter.AnimationMode.EASE_IN_OUT_QUAD, 200, "opacity", 0);
                credentials_actor.remove_credentials ();
                PantheonGreeter.login_gateway.login_with_mask (this, user.is_guest);
            } else {
                if (old_avatar != null)
                    old_avatar.deselect ();
                label.animate (Clutter.AnimationMode.EASE_IN_OUT_QUAD, 200, "opacity", 255);
            }
            credentials_actor.animate (Clutter.AnimationMode.EASE_IN_OUT_QUAD, 200, "opacity", opacity);
        }
    }

    public LoginBox (LoginOption user) {
        this.user = user;
        this.reactive = true;
        this.scale_gravity = Clutter.Gravity.CENTER;

        create_credentials ();

        credentials_actor.replied.connect ((answer) => {
            selected = false;
            PantheonGreeter.login_gateway.respond (answer);
        });

        create_label ();

        if (user.avatar_ready) {
            update_avatar ();
        } else {
            user.avatar_updated.connect (() => {
                update_avatar ();
            });
        }
        show_all ();
    }

    void create_credentials () {
        credentials_actor = new CredentialsAreaActor(user);
        credentials_actor.x = this.x + 100;
        add_child (credentials_actor);
    }

    void create_label () {
        label = new ShadowedLabel (user.get_markup ());
        label.height = 75;
        label.width = 600;
        label.y = 0;
        label.reactive = true;
        label.x = this.x + 100;
        add_child (label);
    }

    void update_avatar () {
        if (old_avatar != null)
            old_avatar.dismiss ();

        old_avatar = new SelectableAvatar (user);
        add_child (old_avatar);

        if (selected)
            old_avatar.select ();
    }

    public void pass_focus () {
        credentials_actor.pass_focus ();
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
        var transition = new Clutter.PropertyTransition ("x");
        transition.set_duration (10);
        transition.set_progress_mode (Clutter.AnimationMode.LINEAR);
        transition.animatable = this;
        transition.set_from_value (0.0);
        transition.set_to_value (500.0);
        transition.start ();
        this.selected = true;
    }

    public void login_aborted () {
        credentials_actor.remove_credentials ();
    }

    /* End of LoginMask interface */

    class CredentialsAreaActor : GtkClutter.Actor {
        CredentialsArea credentials;
        public string current_session { get; set; }

        public signal void replied (string text);

        Entry? login_name_entry = null;
        ToggleButton settings;

        // Grid that contains all elements of the ui
        Grid grid;

        public string login_name {
            get {
                return login_name_entry.text;
            }
        }

        public CredentialsAreaActor (LoginOption login_option) {
            current_session = login_option.session;
            width = 200;
            height = 188;
            credentials = null;

            grid = new Grid ();

            // If the login option doesn't provice a login name, we have to
            // show a entry for the user to enter one.
            // This is for example used in the manual login.
            if (login_option.provides_login_name) {
                create_entry_dummy ();
            } else {
                create_login_name_entry ();
            }

            // Only show settings if we actually have more than one session
            // to select from
            if (LightDM.get_sessions ().length () > 1) {
                create_settings ();
                create_popup ();
            }

            var w = -1; var h = -1;
            this.get_widget ().size_allocate.connect (() => {
                w = this.get_widget ().get_allocated_width ();
                h = this.get_widget ().get_allocated_height ();
            });

            // We override the draw call and just paint a transparent
            // rectangle. TODO: can we also just draw nothing?
            // Shouldn't change anything...
            this.get_widget ().draw.connect ((ctx) => {
                ctx.rectangle (0, 0, w, h);
                ctx.set_operator (Cairo.Operator.SOURCE);
                ctx.set_source_rgba (0, 0, 0, 0);
                ctx.fill ();

                return false;
            });

            ((Container) this.get_widget ()).add (grid);
            this.get_widget ().show_all ();
        }

        public void remove_credentials () {
            if (credentials != null) {
                grid.remove (credentials);
                credentials = null;
            }
        }

        public void pass_focus () {
            if (login_name_entry != null) {
                login_name_entry.grab_focus ();
            } else if (credentials != null) {
                credentials.pass_focus ();
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
                grid.sensitive = false;
                this.replied (answer);
            });
            grid.sensitive = true;
            grid.show_all ();
            credentials.pass_focus ();
        }

        void create_login_name_entry () {
            login_name_entry = new Entry();
            login_name_entry.hexpand = true;
            login_name_entry.margin_top = 8;
            grid.attach (login_name_entry, 0, 0, 1, 1);
        }

        void create_entry_dummy () {
            var dummy = new Grid();
            dummy.hexpand = true;
            dummy.margin_top = 8;
            grid.attach (dummy, 0, 0, 1, 1);
        }

        void create_settings () {
            settings = new ToggleButton ();
            settings.relief = ReliefStyle.NONE;
            settings.add (new Image.from_icon_name ("application-menu-symbolic", IconSize.MENU));
            settings.valign = Align.END;
            settings.set_size_request (30, 30);
            grid.attach (settings, 1, 0, 1, 1);
        }

        void create_popup () {
            PopOver pop = null;
            /*session choose popover*/
            this.settings.toggled.connect (() => {
                if (!settings.active) {
                    pop.destroy ();
                    return;
                }

                pop = new PopOver ();

                var box = new Box (Orientation.VERTICAL, 0);
                (pop.get_content_area () as Container).add (box);

                var but = new RadioButton.with_label (null, LightDM.get_sessions ().nth_data (0).name);
                box.pack_start (but, false);
                but.active = LightDM.get_sessions ().nth_data (0).key == current_session;

                but.toggled.connect (() => {
                    if (but.active)
                        current_session = LightDM.get_sessions ().nth_data (0).key;
                });

                for (var i = 1;i < LightDM.get_sessions ().length (); i++) {
                    var rad = new RadioButton.with_label_from_widget (but, LightDM.get_sessions ().nth_data (i).name);
                    box.pack_start (rad, false);
                    rad.active = LightDM.get_sessions ().nth_data (i).key == current_session;
                    var identifier = LightDM.get_sessions ().nth_data (i).key;
                    rad.toggled.connect ( () => {
                        if (rad.active)
                            current_session = identifier;
                    });
                }

                this.get_stage ().add_child (pop);

                float actor_x = 0;
                float actor_y = 0;

                this.get_transformed_position (out actor_x, out actor_y);

                int po_x;
                int po_y;
                settings.translate_coordinates (credentials, 10, 10, out po_x, out po_y);

                pop.width = 245;
                pop.x = actor_x + po_x - pop.width + 40;
                pop.y = actor_y + po_y;
                pop.get_widget ().show_all ();

                pop.destroy.connect (() => {
                    settings.active = false;
                });
            });
        }

    }
}