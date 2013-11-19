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

public enum UserType { NORMAL, GUEST, MANUAL }

public class PantheonUser : Object {

    private static Gdk.Pixbuf default_avatar;

    private LightDM.User user;

    private Gdk.Pixbuf avatar;

    public int index { get; private set; }

    public UserType usertype { get; private set; }

    public PantheonUser (int index, LightDM.User user) {
        this.index = index;
        this.user = user;
        usertype = UserType.NORMAL;
    }

    public PantheonUser.Guest (int index) {
        this.index = index;
        usertype = UserType.GUEST;
        user = null;
    }

    public PantheonUser.Manual (int index) {
        this.index = index;
        usertype = UserType.MANUAL;
        user = null;
    }

    public string get_markup () {
        if (usertype == UserType.NORMAL)
            return "<span face='Open Sans Light' font='24'>"
                                + user.display_name + "</span>";
        return "<span face='Open Sans Light' font='24'>"
                            + _("Guest session") + "</span>";
    }

    public static void load_default_avatar () {
        try {
            default_avatar = Gtk.IconTheme.get_default ().load_icon ("avatar-default", 96, 0);
        } catch {
            error ("Couldn't load default wallpaper");
        }
    }

    public async void load_avatar () {
        if (!is_normal ())
            return;
        try {
            File file = File.new_for_path (user.image);
            InputStream stream = yield file.read_async (GLib.Priority.DEFAULT);
            var buf = new Gdk.Pixbuf.from_stream_at_scale (stream, 96, 96, true);
            lock(avatar) {
                avatar = buf;
            }
            Idle.add(() => {
                avatar_updated ();
                return false;
            });
        } catch (Error e) {
            message ("Using default-avatar instead of " + user.image);
        }
    }

    public signal void avatar_updated ();

    public Gdk.Pixbuf get_avatar () {
        lock(avatar) {
            if(avatar == null)
                return default_avatar;
            return avatar;
        }
    }

    public string background {
        get {
            switch(usertype) {
            case UserType.NORMAL: return get_lightdm_user ().background;
            case UserType.MANUAL: return "";
            case UserType.GUEST: return "";
            }
            return "";
        }
    }

    public string name {
        get {
            switch(usertype) {
            case UserType.NORMAL: return get_lightdm_user ().name;
            case UserType.MANUAL: return _("Manual Login");
            case UserType.GUEST: return _("Guest session");
            }
            return "";
        }
    }


    public LightDM.User? get_lightdm_user () {
        return user;
    }

    public bool is_guest () {
        return usertype == UserType.GUEST;
    }

    public bool is_manual () {
        return usertype == UserType.MANUAL;
    }

    public bool is_normal () {
        return usertype == UserType.NORMAL;
    }
}
