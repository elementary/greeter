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

public abstract class LoginOption : Object {

    protected static Gdk.Pixbuf default_avatar;


    private Gdk.Pixbuf _avatar;
    public Gdk.Pixbuf avatar {
        get {
            lock (_avatar) return _avatar;
        }
        protected set {
            lock (_avatar) _avatar = value;
        }
    }
    /**
     * True if and only if the avatar of this login option is from now on
     * considered constant and you can safely ignore the avatar_updated
     * signal.
     */
    public bool avatar_ready { get; protected set; default = true; }
    public signal void avatar_updated ();

    public int index { get; private set; }

    protected LoginOption (int index) {
        this.index = index;
        _avatar = default_avatar;
    }

    public string get_markup () {
        return "<span face='Open Sans Light' font='24'>"
                            + display_name + "</span>";
    }

    /**
     * Loads the default avatar and is called once at startup.
     */
    public static void load_default_avatar () {
        try {
            default_avatar = Gtk.IconTheme.get_default ().
                load_icon ("avatar-default", 96, 0);
        } catch {
            warning ("Couldn't load default wallpaper");
        }
    }

    /**
     * Each LoginOption can load their own avatar-image here.
     */
    public virtual async void load_avatar () { }

    /**
     * The name of this login how it shall be presented to the user.
     */
    public abstract string display_name { get; }

    /**
     * Path to the background-image of this user or ""
     * in case he has none.
     */
    public virtual string background {
        get {
            return "";
        }
    }

    /**
     * The login name for this LoginOption. This is also used to identify this object
     * from one session to another. Note that you still have to return a unique
     * string even if this LoginOption cannot directly provide a login name to
     * identify this entry.
     */
    public abstract string name { get; }

    /**
     * True if and only if this user is currently logged in.
     */
    public virtual bool logged_in {
        get {
            return false;
        }
    }

    /**
     * If this LoginOption is for a guest-user. This is necessary
     * as LightDM handles guests in a special way.
     */
    public virtual bool is_guest {
        get {
            return false;
        }
    }

    /**
     * True if this LoginOption provides the necessary information to determine
     * the login name. This is for example used by the LoginBox to decide if
     * a Entry for a login name is necessary or not.
     */
    public virtual bool provides_login_name {
        get {
            return true;
        }
    }

    /**
     * The name of the session that this user wants by default.
     */
    public virtual string session {
        get {
            return PantheonGreeter.login_gateway.default_session;
        }
    }
}

public class GuestLogin : LoginOption {

    public GuestLogin (int index) {
        base (index);
    }

    public override bool is_guest {
        get {
            return true;
        }
    }

    public override string name {
        get {
            return "?pantheon greeter guest?";
        }
    }

    public override string display_name {
        get {
            return _("Guest session");
        }
    }
}

public class ManualLogin : LoginOption {

    public ManualLogin (int index) {
        base (index);
    }

    public override string name {
        get {
            return "?pantheon greeter manual?";
        }
    }

    public override string display_name {
        get {
            return _("Manual Login");
        }
    }

    // We want that the LoginBox makes a Entry for the username.
    public override bool provides_login_name {
        get {
            return false;
        }
    }
}

public class UserLogin : LoginOption {

    public LightDM.User lightdm_user { get; private set; }

    public UserLogin (int index, LightDM.User user) {
        base (index);
        this.lightdm_user = user;
        avatar_ready = false;
    }

    public override string background {
        get {
            return lightdm_user.background;
        }
    }

    public override string display_name {
        get {
            return lightdm_user.display_name;
        }
    }

    public override string name {
        get {
            return lightdm_user.name;
        }
    }

    public override bool logged_in {
        get {
            return lightdm_user.logged_in;
        }
    }

    public override string session {
        get {
            return lightdm_user.session;
        }
    }

    public override async void load_avatar () {
        try {
            File file = File.new_for_path (lightdm_user.image);
            InputStream stream = yield file.read_async (GLib.Priority.DEFAULT);
            var buf = new Gdk.Pixbuf.from_stream_at_scale (stream, 96, 96, true);
            avatar = buf;
        } catch (Error e) {
            message ("Using default-avatar instead of " + lightdm_user.image);
        }
        Idle.add (() => {
            avatar_ready = true;
            avatar_updated ();
            return false;
        });
    }
}