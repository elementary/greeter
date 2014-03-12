// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2013 elementary Developers

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

public class LoginBox : GtkClutter.Actor {
    public LoginOption user { get; private set; }
    public string current_session {
        get {
            return credentials_actor.current_session;
        }
        set {
            credentials_actor.current_session = value;
        }
    }

    CredentialsArea credentials;
    CredentialsAreaActor credentials_actor;
    ShadowedLabel label;

    public signal void login_requested ();

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
            }
            credentials_actor.animate (Clutter.AnimationMode.EASE_IN_OUT_QUAD, 200, "opacity", opacity);
        }
    }

    public LoginBox (LoginOption user) {
        this.user = user;
        this.reactive = true;
        this.scale_gravity = Clutter.Gravity.CENTER;


        if (user.is_guest ()) {
            credentials = new GuestLogin (user);
            credentials_actor = new CredentialsAreaActor (credentials);
            current_session = PantheonGreeter.lightdm.default_session_hint;
        }
        if (user.is_manual ()) {
            credentials = new ManualLogin (user);
            credentials_actor = new CredentialsAreaActor (credentials);
            current_session = PantheonGreeter.lightdm.default_session_hint;
        }

        if (user.is_normal ()) {
            credentials = new UserLogin (user);
            credentials_actor = new CredentialsAreaActor (credentials);
            current_session = user.get_lightdm_user ().session;
        }
        add_child (credentials_actor);


        credentials.request_login.connect (() => {
            login_requested ();
        });

        label = new ShadowedLabel (user.get_markup ());
        label.height = 75;
        label.width = 600;
        label.y = 0;
        label.reactive = true;
        label.x = this.x;
        add_child (label);

        pass_focus ();
    }

    public string get_password () {
        return credentials.userpassword;
    }

    public void wrong_pw () {
        credentials.reset_pw ();
        this.animate (Clutter.AnimationMode.EASE_IN_BOUNCE, 150, scale_x: 0.9f, scale_y: 0.9f).
        completed.connect (() => {
            Clutter.Threads.Timeout.add (1, () => {
                this.animate (Clutter.AnimationMode.EASE_OUT_BOUNCE, 150, scale_x: 1.0f, scale_y: 1.0f);
                return false;
            });
        });
    }

    public void pass_focus () {
        //credentials_actor.grab_key_focus ();
        credentials.pass_focus ();
    }

    private class CredentialsAreaActor : GtkClutter.Actor {
        public CredentialsArea credentials { get; private set; }
        public string current_session { get; set; }

        ToggleButton settings;
        Grid grid;

        public CredentialsAreaActor (CredentialsArea a) {
            credentials = a;
            width = 510;
            height = 188;

            this.settings = new ToggleButton ();

            settings.relief  = ReliefStyle.NONE;
            settings.add (new Image.from_icon_name ("application-menu-symbolic", IconSize.MENU));

            grid = new Grid ();

            grid.attach (credentials, 1, 0, 1, 3);
            grid.attach (settings, 2, 2, 1, 1);
            grid.column_spacing = 12;

            //create_popup ();

            var w = -1; var h = -1;
            this.get_widget ().size_allocate.connect (() => {
                w = this.get_widget ().get_allocated_width ();
                h = this.get_widget ().get_allocated_height ();
            });

            this.get_widget ().draw.connect ((ctx) => {
                ctx.rectangle (0, 0, w, h);
                ctx.set_operator (Cairo.Operator.SOURCE);
                ctx.set_source_rgba (0, 0, 0, 0);
                ctx.fill ();

                return false;
            });

            ((Container) this.get_widget ()).add (grid);
            this.get_widget ().show_all ();
            this.get_widget ().get_style_context ().add_class ("content-view");

            if (LightDM.get_sessions ().length () == 1)
                settings.hide ();
        }

        private void create_popup () {
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

                int po_x;
                int po_y;
                settings.translate_coordinates (this.grid, 10, 10, out po_x, out po_y);

                pop.width = 245;
                pop.x = po_x - pop.width/2 + 52;
                pop.y = this.y + po_y + pop.height;
                pop.get_widget ().show_all ();
                pop.destroy.connect (() => {
                    settings.active = false;
                });
            });
        }

    }
}
