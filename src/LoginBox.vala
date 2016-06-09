// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
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
            credentials_actor.remove_credentials ();
            credentials_actor.reveal = value;
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
        avatar = new SelectableAvatar (user);
        add_child (avatar);
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
}
