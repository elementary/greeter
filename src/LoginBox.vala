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
    private Avatar avatar = null;
    private CredentialsAreaActor credentials_actor;

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

    public string login_name {
        get {
            if (user.provides_login_name) {
                return user.name;
            }
            return credentials_actor.login_name;
        }
    }

    public string login_session {
        get {
            return credentials_actor.current_session;
        }
    }

    public LoginOption user { get; construct; }

    public LoginBox (LoginOption user) {
        Object (user: user);
    }

    construct {
        this.reactive = true;

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

        if (user.avatar_ready) {
            create_avatar ();
        } else {
            user.avatar_updated.connect (() => {
                create_avatar ();
            });
        }
    }

    /**
     * Starts the login procedure. Necessary to call this before the user
     * can enter something so that the LoginGateway can tell
     * us what kind of prompt he wants.
     */
    private void start_login () {
        PantheonGreeter.login_gateway.login_with_mask (this, user.is_guest);
    }

    private void create_avatar () {
        avatar = new Avatar (user);
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

    void shake () {
        credentials_actor.shake ();
        start_login ();
        return;
    }

    public void show_prompt (PromptType type, PromptText prompttext, string text = "") {
        credentials_actor.show_prompt (type);
    }
    
    public void show_message (LightDM.MessageType type, MessageText messagetext, string text = "") {
        credentials_actor.show_message (type, messagetext, text);
    }

    public void not_authenticated () {
        credentials_actor.remove_credentials ();
        shake ();
    }

    public void login_aborted () {
        credentials_actor.remove_credentials ();
    }
}
