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

public abstract class CredentialsArea : Gtk.Grid {
    public signal void replied (string answer);
    public abstract void pass_focus ();
}

public class PasswordArea : CredentialsArea {

    Gtk.Entry password;

    public PasswordArea () {
        create_password_field ();
    }

    void create_password_field () {
        password = new Gtk.Entry ();

        password.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "dialog-password-symbolic");
        password.caps_lock_warning = true;
        password.visibility = false;
        password.hexpand = true;
        password.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "go-jump-symbolic");
        password.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Log In"));
        password.icon_press.connect ((pos, event) => {
            if (pos == Gtk.EntryIconPosition.SECONDARY) {
                replied (password.text);
            }
        });
        password.key_release_event.connect ((e) => {
            if (e.keyval == Gdk.Key.Return || e.keyval == Gdk.Key.KP_Enter) {
                replied (password.text);
                return true;
            } else {
                return false;
            }
        });

        attach (password, 0, 0, 1, 1);
    }

    public override void pass_focus () {
        password.grab_focus ();
    }
}

public class LoginButtonArea : CredentialsArea {

    Gtk.Button login_btn;

    public LoginButtonArea () {
        login_btn = new Gtk.Button.with_label (_("Log In"));
        login_btn.clicked.connect (() => {
            // It doesn't matter what we anser, the confirmation
            // is that we reply at all.
            replied ("");
        });

        login_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        attach (login_btn, 0, 1, 1, 1);
    }

    public override void pass_focus () {
        login_btn.grab_focus ();
    }
}
