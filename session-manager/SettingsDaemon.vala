/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011 Canonical Ltd
 *                         2025 elementary, Inc. (https://elementary.io)
 */

public class GreeterSessionManager.SettingsDaemon : GLib.Object {
    private const string[] DAEMONS = {
        "gsd-a11y-settings",
        "gsd-color",
        "gsd-media-keys",
        "gsd-sound",
        "gsd-power",
        "gsd-xsettings"
    };

    private SubprocessSupervisor[] supervisors = {};

    construct {
        /* Pretend to be GNOME session */
        GLib.Bus.own_name (
            BusType.SESSION, "org.gnome.SessionManager", BusNameOwnerFlags.NONE,
            (connection) => {
                try {
                    connection.register_object ("/org/gnome/SessionManager", new GnomeSessionManager ());
                } catch (Error e) {
                    critical ("Failed to register /org/gnome/SessionManager: %s", e.message);
                }
            },
            () => {
                debug ("Acquired org.gnome.SessionManager");
                start_settings_daemon ();
            },
            () => {
                critical ("Lost org.gnome.SessionManager");
            }
        );
    }

    private void start_settings_daemon () {
        debug ("All bus names acquired, starting gnome-settings-daemon");

        foreach (unowned var daemon in DAEMONS) {
            try {
                supervisors += new SubprocessSupervisor ({ Constants.GSD_DIR + daemon });
            } catch (Error e) {
                critical ("Could not start %s: %s", daemon, e.message);
            }
        }
    }
}
