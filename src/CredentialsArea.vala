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

public abstract class CredentialsArea : Grid {

    public signal void request_login ();
    public signal void reset_pw ();

    private string _userpassword = "";

    public bool hide_username_when_selected { get; protected set; default = false; }

    public string userpassword {
        get {
            return _userpassword;
        }
    }

    public LoginOption? user { get; private set; }

    public virtual string get_username () {
        return user.name;
    }

    public CredentialsArea (LoginOption? user) {
        this.user = user;
    }

    public abstract void pass_focus ();

    public Entry create_password_field (bool grab_focus) {
        var password = new Entry ();
        password.caps_lock_warning = true;
        //replace the letters with dots
        password.set_visibility (false);
        password.hexpand = true;
        password.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "go-jump-symbolic");
        password.icon_press.connect ((pos, event) => {
            if (pos == Gtk.EntryIconPosition.SECONDARY) {
                request_login ();
            }
        });
        password.key_release_event.connect ((e) => {
            if (e.keyval == Gdk.Key.Return || e.keyval == Gdk.Key.KP_Enter) {
                request_login ();
                return true;
            } else {
                return false;
            }
        });
        password.changed.connect (() => {
            _userpassword = password.text;
        });

        reset_pw.connect (() => {
            password.text = "";
        });
        return password;
    }
}

public class UserLogin : CredentialsArea {

    Entry password;

    public UserLogin (LoginOption user) {
        base (user);

        password = create_password_field (true);
        password.margin_top = 52;
        attach (password, 0, 0, 1, 1);
    }

    public override void pass_focus () {
        password.grab_focus ();
    }

}

public class ManualLogin : CredentialsArea {
    private Entry username;

    public ManualLogin (LoginOption user) {
        base (user);
        username = new Entry();
        username.hexpand = true;
        username.margin_top = 8;

        attach (username, 0, 0, 1, 1);

        var password = create_password_field (false);
        password.margin_top = 16;
        attach (password, 0, 1, 2, 1);
        hide_username_when_selected = true;
    }

    public override void pass_focus () {
        username.grab_focus ();
    }

    public override string get_username () {
        return username.text;
    }
}

public class GuestLogin : CredentialsArea {

    Button login_btn;

    public GuestLogin (LoginOption user) {
        base (user);

        login_btn = new Button.with_label (_("Login"));
        login_btn.clicked.connect (() => {
            request_login ();
        });

        login_btn.margin_top = 52;

        attach (login_btn, 0, 1, 1, 1);
    }

    public override void pass_focus () {
        login_btn.grab_focus ();
    }
}

public class DummyLogin : CredentialsArea {
    public DummyLogin () {
        base (null);
    }

    public override void pass_focus () {
    }

}
