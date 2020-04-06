/* -*- Mode:Vala; indent-tabs-mode:nil; tab-width:4 -*-
 *
 * Copyright (C) 2011 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Michael Terry <michael.terry@canonical.com>
 */

public class Greeter.SettingsDaemon : Object {
    private Greeter.GnomeSessionManager session_manager;
    private int n_names = 0;
    private SubprocessSupervisor[] supervisors = {};

    public void start () {
#if UBUNTU_PATCHED_GSD
        string[] disabled = {
            "org.gnome.settings-daemon.plugins.background",
            "org.gnome.settings-daemon.plugins.clipboard",
            "org.gnome.settings-daemon.plugins.font",
            "org.gnome.settings-daemon.plugins.gconf",
            "org.gnome.settings-daemon.plugins.gsdwacom",
            "org.gnome.settings-daemon.plugins.housekeeping",
            "org.gnome.settings-daemon.plugins.keybindings",
            "org.gnome.settings-daemon.plugins.keyboard",
            "org.gnome.settings-daemon.plugins.mouse",
            "org.gnome.settings-daemon.plugins.print-notifications",
            "org.gnome.settings-daemon.plugins.smartcard",
            "org.gnome.settings-daemon.plugins.wacom"
        };

        string[] enabled = {
            "org.gnome.settings-daemon.plugins.a11y-keyboard",
            "org.gnome.settings-daemon.plugins.a11y-settings",
            "org.gnome.settings-daemon.plugins.color",
            "org.gnome.settings-daemon.plugins.cursor",
            "org.gnome.settings-daemon.plugins.media-keys",
            "org.gnome.settings-daemon.plugins.power",
            "org.gnome.settings-daemon.plugins.sound",
            "org.gnome.settings-daemon.plugins.xrandr",
            "org.gnome.settings-daemon.plugins.xsettings"
        };

        foreach (var schema in disabled) {
            set_plugin_enabled (schema, false);
        }

        foreach (var schema in enabled) {
            set_plugin_enabled (schema, true);
        }
#endif
        /* Pretend to be GNOME session */
        session_manager = new Greeter.GnomeSessionManager ();
        n_names++;
        GLib.Bus.own_name (BusType.SESSION, "org.gnome.SessionManager", BusNameOwnerFlags.NONE,
                           (c) => {
                               try {
                                   c.register_object ("/org/gnome/SessionManager", session_manager);
                               } catch (Error e) {
                                   warning ("Failed to register /org/gnome/SessionManager: %s", e.message);
                               }
                           },
                           () => {
                               debug ("Acquired org.gnome.SessionManager");
                               start_settings_daemon ();
                           },
                           () => debug ("Failed to acquire name org.gnome.SessionManager"));
    }

#if UBUNTU_PATCHED_GSD
    private void set_plugin_enabled (string schema_name, bool enabled) {
        var source = SettingsSchemaSource.get_default ();
        var schema = source.lookup (schema_name, true);
        if (schema != null) {
            var settings = new GLib.Settings (schema_name);
            settings.set_boolean ("active", enabled);
        }
    }
#endif

    private void start_settings_daemon () {
        n_names--;
        if (n_names != 0) {
            return;
        }

        debug ("All bus names acquired, starting gnome-settings-daemon");

        string[] daemons = {
            "gsd-a11y-settings",
            "gsd-color",
            "gsd-media-keys",
            "gsd-sound",
            "gsd-power",
            "gsd-xsettings"
        };

        foreach (var daemon in daemons) {
            try {
                supervisors += new Greeter.SubprocessSupervisor ({Constants.GSD_DIR + daemon});
            } catch (GLib.Error e) {
                critical ("Could not start %s: %s", daemon, e.message);
            }
        }
    }
}

[DBus (name="org.gnome.SessionManager")]
public class Greeter.GnomeSessionManager : GLib.Object {
    private Gee.ArrayList<Greeter.GnomeSessionManagerClient> clients;
    private Gee.ArrayList<unowned Greeter.GnomeSessionManagerClient> inhibitors;

    public string session_name { owned get; set; default = "pantheon"; }
    public string renderer { owned get; set; default = ""; }
    public bool session_is_active { get; set; default = true; }
    public uint inhibited_actions { get; set; default = 0; }

    public signal void client_added (GLib.ObjectPath id);
    public signal void client_removed (GLib.ObjectPath id);
    public signal void inhibitor_added (GLib.ObjectPath id);
    public signal void inhibitor_removed (GLib.ObjectPath id);
    public signal void session_running ();
    public signal void session_over ();

    construct {
        clients = new Gee.ArrayList<Greeter.GnomeSessionManagerClient> ();
        inhibitors = new Gee.ArrayList<unowned Greeter.GnomeSessionManagerClient> ();
    }

    public void setenv (string variable, string value) throws GLib.Error {
    }

    public string get_locale (int category) throws GLib.Error {
        return "C";
    }

    public void initialization_error (string message, bool fatal) throws GLib.Error {
        critical ("Initialization error: %s", message);
    }

    public GLib.ObjectPath register_client (string app_id, string client_startup_id, GLib.BusName sender) throws GLib.Error {
        foreach (var client in clients) {
            if (client.get_app_id () == app_id) {
                return new GLib.ObjectPath (client.object_path);
            }
        }

        uint32 process_id = 0;
        try {
            var session_bus = GLib.Bus.get_sync (GLib.BusType.SESSION);
            var pid_variant = session_bus.call_sync (
                "org.freedesktop.DBus",
                "/org/freedesktop/DBus",
                "org.freedesktop.DBus",
                "GetConnectionUnixProcessID",
                new Variant ("(s)", sender),
                new GLib.VariantType ("(u)"),
                GLib.DBusCallFlags.NONE,
                -1
            );
            pid_variant.get ("(u)", out process_id);
        } catch (Error e) {
            critical (e.message);
        }

        var client = new GnomeSessionManagerClient (app_id, client_startup_id, process_id);
        clients.add (client);
        return new GLib.ObjectPath (client.object_path);
    }

    public void unregister_client (GLib.ObjectPath client_id) throws GLib.Error {
        foreach (var client in clients) {
            if (client.object_path == (string)client_id) {
                clients.remove (client);
                return;
            }
        }
    }

    public uint inhibit (string app_id, uint toplevel_xid, string reason, uint flags) throws GLib.Error {
        return 0;
    }

    public void uninhibit (uint inhibit_cookie) throws GLib.Error {

    }

    public bool is_inhibited (uint flags) throws GLib.Error {
        return !inhibitors.is_empty;
    }

    public GLib.ObjectPath[] get_clients () throws GLib.Error {
        GLib.ObjectPath[] returned_array = null;
        return returned_array;
    }

    public GLib.ObjectPath[] get_inhibitors () throws GLib.Error {
        GLib.ObjectPath[] returned_array = null;
        return returned_array;
    }

    public bool is_autostart_condition_handled (string condition) throws GLib.Error {
        return true;
    }

    public void shutdown () throws GLib.Error {

    }

    public void reboot () throws GLib.Error {

    }

    public bool can_shutdown () throws GLib.Error {
        return true;
    }

    public void logout (uint mode) throws GLib.Error {

    }

    public bool is_session_running () throws GLib.Error {
        return true;
    }
}

[DBus (name = "org.gnome.SessionManager.Client")]
public class Greeter.GnomeSessionManagerClient : GLib.Object {
    static uint32 serial_id = 0;

    private string app_id;
    private string startup_id;
    private uint32 process_id;
    [DBus (visible = false)]
    public string object_path;

    construct {
        object_path = "/org/gnome/SessionManager/Client%u".printf (serial_id);
        serial_id++;

        try {
            var session_bus = GLib.Bus.get_sync (GLib.BusType.SESSION);
            session_bus.register_object<Greeter.GnomeSessionManagerClient> (object_path, this);
        } catch (Error e) {
            critical (e.message);
        }
    }

    public GnomeSessionManagerClient (string app_id, string startup_id, uint32 process_id) {
        this.app_id = app_id;
        this.startup_id = startup_id;
        this.process_id = process_id;
    }

    public string get_app_id () throws GLib.Error {
        return app_id;
    }

    public string get_startup_id () throws GLib.Error {
        return startup_id;
    }

    public uint get_restart_style_hint () throws GLib.Error {
        return 0;
    }

    public uint32 get_unix_process_id () throws GLib.Error {
        return process_id;
    }

    public uint get_status () throws GLib.Error {
        return 1;
    }

    public void stop () throws GLib.Error {
    }
}
