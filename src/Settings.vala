/*
 * Copyright 2018 elementary, Inc. (https://elementary.io)
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
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class Greeter.Settings : GLib.Object {
    private GLib.KeyFile settings;
    private GLib.Settings power_settings;

    public int sleep_inactive_ac_timeout {
        set {
            if (power_settings != null) {
                power_settings.set_int ("sleep-inactive-ac-timeout", value);
            }
        }
    }

    public int sleep_inactive_ac_type {
        set {
            if (power_settings != null) {
                power_settings.set_enum ("sleep-inactive-ac-type", value);
            }
        }
    }

    public int sleep_inactive_battery_timeout {
        set {
            if (power_settings != null) {
                power_settings.set_int ("sleep-inactive-battery-timeout", value);
            }
        }
    }

    public int sleep_inactive_battery_type {
        set {
            if (power_settings != null) {
                power_settings.set_enum ("sleep-inactive-battery-type", value);
            }
        }
    }

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

        power_settings = new GLib.Settings ("org.gnome.settings-daemon.plugins.power");
    }
}
