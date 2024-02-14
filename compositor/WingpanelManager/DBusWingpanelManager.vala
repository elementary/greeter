/*
 * Copyright (c) 2011-2015 Wingpanel Developers (http://launchpad.net/wingpanel)
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
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

[DBus (name = "org.pantheon.gala.WingpanelInterface")]
public class GreeterCompositor.DBusWingpanelManager : Object {
    private WingpanelManager background_manager;
    private static DBusWingpanelManager? instance;
    static WindowManager wm;

    [DBus (visible = false)]
    public static void init (WindowManager _wm) {
        wm = _wm;

        Bus.own_name (BusType.SESSION, "org.pantheon.gala.WingpanelInterface", BusNameOwnerFlags.NONE,
            (connection) => {
                if (instance == null)
                    instance = new DBusWingpanelManager ();

                try {
                    connection.register_object ("/org/pantheon/gala/WingpanelInterface", instance);
                } catch (Error e) {
                    warning (e.message);
                }
            },
            () => {},
            () => warning ("Could not acquire name\n")
        );
    }

    public signal void state_changed (BackgroundState state, uint animation_duration);

    public void initialize (int monitor, int panel_height) throws GLib.Error {
        background_manager = new WingpanelManager (wm, panel_height);
        background_manager.state_changed.connect ((state, animation_duration) => {
            state_changed (state, animation_duration);
        });
     }

    public bool begin_grab_focused_window (int x, int y, int button, uint time, uint state) throws GLib.Error {
        return false;
    }

    public void remember_focused_window () throws GLib.Error {}
    public void restore_focused_window () throws GLib.Error {}
 }
