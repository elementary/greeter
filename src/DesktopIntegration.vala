/*
 * Copyright 2026 elementary, Inc. <https://elementary.io>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[DBus (name="org.pantheon.gala.DesktopIntegration")]
public interface Greeter.DesktopIntegration : GLib.Object {
    public struct RunningApplication {
        string app_id;
        GLib.HashTable<string, Variant> details;
    }

    public struct Window {
        uint64 uid;
        GLib.HashTable<string, Variant> properties;
    }

    public abstract uint version { get; default = 1; }

    public signal void running_applications_changed ();
    public signal void windows_changed ();
    public signal void active_workspace_changed ();
    public signal void workspace_removed (int index);
    public signal void caps_lock_state_changed ();
    public signal void num_lock_state_changed ();

    public abstract async RunningApplication[] get_running_applications () throws GLib.DBusError, GLib.IOError;
    public abstract async Window[] get_windows () throws GLib.DBusError, GLib.IOError;
    public abstract async void show_windows_for (string app_id) throws GLib.DBusError, GLib.IOError;
    public abstract async void focus_window (uint64 uid) throws GLib.DBusError, GLib.IOError;
    public abstract async void move_window_to_workspace (uint64 window, int workspace) throws GLib.DBusError, GLib.IOError;
    public abstract async void activate_workspace (int index) throws GLib.DBusError, GLib.IOError;
    public abstract async int get_n_workspaces () throws GLib.DBusError, GLib.IOError;
    public abstract async int get_active_workspace () throws GLib.DBusError, GLib.IOError;
    public abstract async void reorder_workspace (int index, int new_index) throws GLib.DBusError, GLib.IOError;
    public abstract async bool get_caps_lock_state () throws GLib.DBusError, GLib.IOError;
    public abstract async bool get_num_lock_state () throws GLib.DBusError, GLib.IOError;
}
