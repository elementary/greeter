/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2018-2025 elementary, Inc. (https://elementary.io)
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class Greeter.Settings : GLib.Object {
    private GLib.KeyFile settings;

    public bool activate_numlock {
        get {
            try {
                return settings.get_boolean ("greeter", "activate-numlock");
            } catch (Error e) {
                debug (e.message);
                return false;
            }
        }
    }

    construct {
        settings = new GLib.KeyFile ();
        try {
            var greeter_conf_file = GLib.Path.build_filename (Constants.CONF_DIR, "io.elementary.greeter.conf");
            settings.load_from_file (greeter_conf_file, GLib.KeyFileFlags.NONE);
        } catch (Error e) {
            critical (e.message);
        }
    }
}
