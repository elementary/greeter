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
        return display_name;
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
