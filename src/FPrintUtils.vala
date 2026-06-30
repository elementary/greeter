/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2018-2025 elementary, Inc. (https://elementary.io)
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

[DBus (name = "net.reactivated.Fprint.Manager")]
public interface FPrintManager : GLib.Object {
    public abstract ObjectPath get_default_device () throws GLib.Error;
    public abstract ObjectPath[] get_devices ();
}

[DBus (name = "net.reactivated.Fprint.Device")]
public interface FPrintDevice : GLib.Object {
    public abstract string name { owned get; }
    public abstract void claim (string username) throws GLib.Error;
    public abstract void release () throws GLib.Error;
    public abstract void verify_start (string finger) throws GLib.Error;
    public abstract void verify_stop () throws GLib.Error;
    public signal void verify_status (string result, bool done);
}

class FPrintUtil {
    private unowned FPrintManager manager;
    private FPrintDevice[] devices = {};

    public signal void verify_passed ();
    public signal void verify_failed ();

    public bool start (string username) {

        bool any_started = false;

        try {
            manager = Bus.get_proxy_sync (
                BusType.SYSTEM,
                "net.reactivated.Fprint",
                "/net/reactivated/Fprint/Manager",
                DBusProxyFlags.NONE
            );
        } catch (Error e) {
            debug (e.message);
            return false;
        }

        var device_paths = manager.get_devices ();

        foreach (var device_path in device_paths) {
            FPrintDevice device;
            try {
                device = GLib.Bus.get_proxy_sync (
                    GLib.BusType.SYSTEM,
                    "net.reactivated.Fprint",
                    device_path
                );
            } catch (Error e) {
                debug (e.message);
                continue;
            }
            devices += device;
        }

        foreach (var device in devices) {
            try {
                device.claim (username);
                device.verify_status.connect(status);
                device.verify_start ("any");
                any_started = true;
            } catch (Error e) {
                debug ("%s: %s", e.message, device.name);
            }
        }

        return any_started;
    }

    public void stop () {
        foreach (var device in devices) {
            try {
                device.release ();
            } catch (Error e) {
                debug ("%s: %s", e.message, device.name);
            }
        }
    }

    private void status (string result, bool done) {
        if (result == "verify-match") {
            foreach (var device in devices) {
                try {
                    device.verify_stop ();
                } catch (GLib.Error e) {
                    debug ("Device stop error: %s\n%s", device.name, e.message);
                }
            }
            stop ();
            verify_passed ();
        } else {
            verify_failed ();
        }
    }
}
