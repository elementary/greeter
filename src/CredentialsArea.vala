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

public abstract class CredentialsArea : Grid {

    public signal void request_login ();
    public signal void pass_focus ();
    public signal void reset_pw ();

    private string _userpassword = "";

    public string userpassword {
        get {
            return _userpassword;
        }
    }

    public PantheonUser? user { get; private set; }

    public virtual string get_username () {
        return user.name;
    }

    public CredentialsArea (PantheonUser? user) {
        this.user = user;
    }

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
        if(grab_focus) {
            pass_focus.connect (() => {
                password.grab_focus ();
            });
        }
        return password;
    }
}

public class UserLogin : CredentialsArea {

    public UserLogin (PantheonUser user) {
        base (user);

        var password = create_password_field (true);
        password.margin_top = 52;
        attach (password, 0, 0, 1, 1);

        password.focus_out_event.connect (() => {
            password.grab_focus ();
            return false;
        });
    }
}

public class ManualLogin : CredentialsArea {
    private Entry username;

    public ManualLogin (PantheonUser user) {
        base (user);
        username = new Entry();
        username.hexpand = true;
        username.margin_top = 8;

        attach (username, 0, 0, 1, 1);

        pass_focus.connect (() => {
            username.grab_focus ();
        });

        var password = create_password_field (false);
        password.margin_top = 16;
        attach (password, 0, 1, 2, 1);

        password.focus_out_event.connect (() => {
            username.grab_focus ();
            return false;
        });

        username.focus_out_event.connect (() => {
            password.grab_focus ();
            return false;
        });
    }

    public override string get_username () {
        return username.text;
    }
}

public class GuestLogin : CredentialsArea {

    public GuestLogin (PantheonUser user) {
        base (user);

        var login_btn = new Button.with_label (_("Login"));
        login_btn.clicked.connect (() => {
            request_login ();
        });
        pass_focus.connect (() => {
            login_btn.grab_focus ();
        });

        login_btn.focus_out_event.connect (() => {
            login_btn.grab_focus ();
            return false;
        });
        login_btn.margin_top = 52;

        attach (login_btn, 0, 1, 1, 1);
    }
}

public class DummyLogin : CredentialsArea {
    public DummyLogin () {
        base (null);
    }
}
