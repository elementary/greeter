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

public class SelectableAvatar : GtkClutter.Actor {
    Avatar normal_avatar;

    public SelectableAvatar (LoginOption user) {
        normal_avatar = new Avatar (user);
        add_child (normal_avatar);

        if (user.logged_in) {
            var logged_in = new LoggedInIcon ();
            logged_in.x = logged_in.y = 80;
            add_child (logged_in);
        }
    }
}

public class LoggedInIcon : GtkClutter.Actor {
    public LoggedInIcon () {
        var container_widget = (Gtk.Container)this.get_widget ();

        var image = new Gtk.Image.from_icon_name ("selection-checked", Gtk.IconSize.LARGE_TOOLBAR);

        container_widget.add (image);
    }
}

public class Avatar : GtkClutter.Actor {
    Gdk.Pixbuf image;

    public Avatar (LoginOption user) {
        var container_widget = (Gtk.Container)this.get_widget ();

        image = user.avatar;

        var avatar = new Granite.Widgets.Avatar ();
        avatar.pixbuf = image;

        container_widget.add (avatar);
    }

    public void fade_in () {
        save_easing_state ();
        set_easing_mode (Clutter.AnimationMode.EASE_IN_OUT_QUAD);
        set_easing_duration (400);
        set_opacity (255);
        restore_easing_state ();
    }

    public void fade_out () {
        save_easing_state ();
        set_easing_mode (Clutter.AnimationMode.EASE_IN_OUT_QUAD);
        set_easing_duration (400);
        set_opacity (0);
        restore_easing_state ();
    }

    public void dismiss () {
        fade_out ();
        ulong sid = 0;
        sid = transitions_completed.connect (() => {
            get_parent ().remove_child (this);
            disconnect (sid);
        });
    }

}
