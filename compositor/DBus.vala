/*
 * Copyright 2012-2014 Tom Beckmann, Jacob Parker
 * Copyright 2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

[DBus (name="org.pantheon.greeter")]
public class GreeterCompositor.DBus {
    public static DBus? instance;
    static WindowManager wm;

    [DBus (visible = false)]
    public static void init (WindowManager _wm) {
        wm = _wm;

        Bus.own_name (BusType.SESSION, "org.pantheon.greeter", BusNameOwnerFlags.NONE,
            (connection) => {
                if (instance == null)
                    instance = new DBus ();

                try {
                    connection.register_object ("/org/pantheon/greeter", instance);
                } catch (Error e) {
                    warning (e.message);
                }
            },
            () => {},
            () => warning ("Could not acquire name\n")
        );

        Bus.own_name (BusType.SESSION, "org.gnome.Shell", BusNameOwnerFlags.NONE,
            (connection) => {
                try {
                    connection.register_object ("/org/gnome/Shell", DBusAccelerator.init (wm));
                } catch (Error e) {
                    warning (e.message);
                }
            },
            () => {},
            () => critical ("Could not acquire name")
        );
    }

    [DBus (visible = false)]
    public signal void change_wallpaper (string path);

    public void set_wallpaper (string path) throws GLib.Error {
        wm.set_wallpaper (path);
    }

    private DBus () {

    }
}
