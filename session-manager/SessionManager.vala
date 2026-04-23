/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

[DBus (name="org.gnome.SessionManager")]
public class GreeterSessionManager.GnomeSessionManager : GLib.Object {
    private Gee.ArrayList<GnomeSessionManagerClient> clients;
    private Gee.ArrayList<unowned GnomeSessionManagerClient> inhibitors;

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
        clients = new Gee.ArrayList<GnomeSessionManagerClient> ();
        inhibitors = new Gee.ArrayList<unowned GnomeSessionManagerClient> ();
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
public class GreeterSessionManager.GnomeSessionManagerClient : GLib.Object {
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
            session_bus.register_object<GnomeSessionManagerClient> (object_path, this);
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
