/*
 * Copyright 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

[DBus (name = "org.pantheon.gala.WingpanelInterface")]
public class GreeterCompositor.DBusWingpanelManager : GLib.Object {
    private static DBusWingpanelManager? instance;
    private static WindowManager wm;

    private WingpanelManager background_manager;
    private FocusManager focus_manager;

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

        focus_manager = new FocusManager (wm.get_display ());
     }

    public bool begin_grab_focused_window (int x, int y, int button, uint time, uint state) throws GLib.Error {
        return focus_manager.begin_grab_focused_window (x, y, button, time, state);
    }

    public void remember_focused_window () throws GLib.Error {
        focus_manager.remember_focused_window ();
    }

    public void restore_focused_window () throws GLib.Error {
        focus_manager.restore_focused_window ();
    }
}
