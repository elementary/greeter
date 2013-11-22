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


public class UserList : Object {

    public int size { get; private set; }

    Gee.ArrayList<PantheonUser> users = new Gee.ArrayList<PantheonUser> ();

    PantheonUser _current_user;

    public PantheonUser current_user {
        get {
            return _current_user;
        }

        set {
            if (value != current_user) {
                _current_user = value;
                user_changed (value);
            }
        }

    }

    public signal void user_changed (PantheonUser user);

    public UserList (LightDM.UserList ld_users, LightDM.Greeter greeter) {
        int index = 0;
        if (!greeter.hide_users_hint) {
            foreach (LightDM.User this_user in ld_users.users) {
                users.add (new PantheonUser (index, this_user));
                index++;
            }
        }

        if (greeter.has_guest_account_hint) {
            users.add (new PantheonUser.Guest (index));
            index++;
        }
        { //if (greeter.show_manual_login_hint) {
            users.add (new PantheonUser.Manual (index));
            index++;
        }
        size = index;

        foreach (PantheonUser user in users) {
            user.load_avatar ();
        }
    }

    public PantheonUser get_user (int i) {
        return users.get (i);
    }

    public void select_next_user () {
        current_user = get_next (current_user);
    }

    public void select_prev_user () {
        current_user = get_prev (current_user);
    }

    public PantheonUser get_next (PantheonUser user) {
        int i = user.index;
        if(i < size - 1)
            return get_user (i + 1);
        return get_user (i);
    }

    public PantheonUser get_prev (PantheonUser user) {
        int i = user.index;
        if(i > 0)
            return get_user (i - 1);
        return get_user (i);
    }

}
