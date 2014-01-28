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


public class UserListActor : Clutter.Actor {
    UserList userlist;

    Gee.HashMap<PantheonUser, LoginBox> boxes = new Gee.HashMap<PantheonUser, LoginBox> ();
    Gee.HashMap<PantheonUser, ShadowedLabel> labels = new Gee.HashMap<PantheonUser, ShadowedLabel> ();
    Gee.HashMap<PantheonUser, ShadowedLabel> dark_labels = new Gee.HashMap<PantheonUser, ShadowedLabel> ();


    public UserListActor (UserList userlist) {
        this.userlist = userlist;

        userlist.user_changed.connect ((user) => {
            animate_list (user, 400);
        });

        build_labels ();
    }

    private void build_labels () {
        for (int i = 0; i < userlist.size; i++) {
            ShadowedLabel label = new ShadowedLabel (userlist.get_user (i).get_markup ());
            ShadowedLabel dark_label = new ShadowedLabel (userlist.get_user (i).get_markup (), true);
            dark_label.height = label.height = 75;
            dark_label.width  = label.width = 600;
            dark_label.y = label.y = i * 200 + label.height;
            dark_label.reactive = label.reactive = true;
            add_child (label);
            add_child (dark_label);
            labels.set (userlist.get_user (i), label);
            dark_labels.set (userlist.get_user (i), dark_label);
        }
    }

    private float[] get_y_for_users (PantheonUser current_user) {
        float[] result = new float[userlist.size];

        float run_y = 0;

        float current_user_y = 0;

        for (int i = 0; i < userlist.size; i++) {
            PantheonUser user = userlist.get_user (i);

            result[i] = run_y;

            run_y += 50;
            if (user != current_user && userlist.get_next (user) == current_user) {
                run_y += 150;
            }
            if (user == current_user) {
                current_user_y = run_y;
                run_y += 150;
            }

        }

        for (int i = 0; i < userlist.size; i++) {
            result[i] = result[i] - current_user_y;
        }

        return result;
    }


    private void animate_list (PantheonUser current_user, int duration) {
        float[] y_vars = get_y_for_users (current_user);

        for (int i = 0; i < userlist.size; i++) {
            PantheonUser user = userlist.get_user (i);
            ShadowedLabel label = labels.get (user);
            ShadowedLabel dark_label = dark_labels.get (user);

            label.animate (Clutter.AnimationMode.EASE_OUT_QUAD, 400, y: y_vars[i]);
            dark_label.animate (Clutter.AnimationMode.EASE_OUT_QUAD, 400, y: y_vars[i]);

            uint opacity = 0;

            if (user == current_user && !user.is_manual ()) {
                opacity = 255;
            }

            label.animate (Clutter.AnimationMode.EASE_OUT_QUAD, duration, "opacity", opacity);

            opacity = 0;
            if (user != current_user)
                opacity = 255;
            dark_label.animate (Clutter.AnimationMode.EASE_OUT_QUAD, duration, "opacity", opacity);

        }

    }
}
