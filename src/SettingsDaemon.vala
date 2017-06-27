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

public class SettingsDaemon : Object {
    private SessionManagerInterface session_manager;
    private int n_names = 0;

    private Mutex mutex = Mutex ();
    private Cond condition = Cond ();
    private int ready1 = 0;
    private int ready2 = 0;
    public signal void xsettings_ready1 ();
    public signal void xsettings_ready2 ();
    private SettingsDaemonDBusInterface  settings_daemon_proxy;

    public void start () {
        string[] disabled = { "org.gnome.settings-daemon.plugins.background",
                              "org.gnome.settings-daemon.plugins.clipboard",
                              "org.gnome.settings-daemon.plugins.font",
                              "org.gnome.settings-daemon.plugins.gconf",
                              "org.gnome.settings-daemon.plugins.gsdwacom",
                              "org.gnome.settings-daemon.plugins.housekeeping",
                              "org.gnome.settings-daemon.plugins.keybindings",
                              "org.gnome.settings-daemon.plugins.keyboard",
                              "org.gnome.settings-daemon.plugins.media-keys",
                              "org.gnome.settings-daemon.plugins.mouse",
                              "org.gnome.settings-daemon.plugins.print-notifications",
                              "org.gnome.settings-daemon.plugins.smartcard",
                              "org.gnome.settings-daemon.plugins.sound",
                              "org.gnome.settings-daemon.plugins.wacom" };

        string[] enabled =  { "org.gnome.settings-daemon.plugins.a11y-keyboard",
                              "org.gnome.settings-daemon.plugins.a11y-settings",
                              "org.gnome.settings-daemon.plugins.color",
                              "org.gnome.settings-daemon.plugins.cursor",
                              "org.gnome.settings-daemon.plugins.power",
                              "org.gnome.settings-daemon.plugins.xrandr",
                              "org.gnome.settings-daemon.plugins.xsettings" };

        foreach (var schema in disabled) {
            set_plugin_enabled (schema, false);
        }

        foreach (var schema in enabled) {
            set_plugin_enabled (schema, true);
        }

        /* Pretend to be GNOME session */
        session_manager = new SessionManagerInterface ();
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

    private void set_plugin_enabled (string schema_name, bool enabled) {
        var source = SettingsSchemaSource.get_default ();
        var schema = source.lookup (schema_name, false);
        if (schema != null) {
            var settings = new Settings (schema_name);
            settings.set_boolean ("active", enabled);
        }
    }

    private void start_settings_daemon () {
        n_names--;
        if (n_names != 0) {
            return;
        }

        debug ("All bus names acquired, starting gnome-settings-daemon");

        try {
            Process.spawn_command_line_async ("gnome-settings-daemon");
        } catch (SpawnError e) {
            debug ("Could not start gnome-settings-daemon: %s", e.message);
        }

        /* Render things after xsettings is ready */

        xsettings_ready1.connect ( xsettings_ready1_cb );
        xsettings_ready2.connect ( xsettings_ready2_cb );

        while (AtomicInt.@get (ref ready1) == 0) {
            Gtk.main_iteration_do (true);
            GLib.Bus.watch_name (BusType.SESSION, "org.gnome.SettingsDaemon", BusNameWatcherFlags.NONE,
                                 (c, name, owner) =>
                                 {
                                    xsettings_ready1 ();
                                    try {
                                        settings_daemon_proxy = GLib.Bus.get_proxy_sync (
                                            BusType.SESSION, "org.gnome.SettingsDaemon", "/org/gnome/SettingsDaemon");
                                        settings_daemon_proxy.plugin_activated.connect (
                                            (name) =>
                                            {
                                                if (name == "xsettings") {
                                                    debug ("xsettings is ready");
                                                    xsettings_ready2 ();
                                                }
                                            }
                                        );
                                    }
                                    catch (Error e)
                                    {
                                        debug ("Failed to get GSD proxy, proceed anyway");
                                        xsettings_ready2 ();
                                    }
                                },
                                (c, name) =>
                                {
                                    debug ("Non existent bus name");
                                });
        }
    }

    public void wait_for_ready1 () {
        while (AtomicInt.@get (ref ready1) == 0) {
            Gtk.main_iteration_do (true);
        }
    }

    public void wait_for_ready2 () {
        mutex.lock ();
        if (AtomicInt.@get (ref ready2) == 0) {
            int64 until = GLib.get_monotonic_time () + 1 * TimeSpan.SECOND;
            condition.wait_until (mutex, until);
        }
        mutex.unlock ();
    }

    private void xsettings_ready1_cb () {
        AtomicInt.inc (ref ready1);
    }

    private void xsettings_ready2_cb () {
        AtomicInt.inc (ref ready2);
    }
}

[DBus (name="org.gnome.SessionManager")]
public class SessionManagerInterface : Object
{
    public bool session_is_active { get { return true; } }
    public string session_name { get { return "pantheon"; } }
    public uint32 inhibited_actions { get { return 0; } }
}

[DBus (name="org.gnome.SettingsDaemon")]
private interface SettingsDaemonDBusInterface : Object
{
    public signal void plugin_activated (string name);
    public signal void plugin_deactivated (string name);
}
