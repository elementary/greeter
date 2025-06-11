/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.freedesktop.portal.Error")]
public errordomain Greeter.PortalError {
    FAILED,
    INVALID_ARGUMENT,
    NOT_FOUND,
    EXISTS,
    NOT_ALLOWED,
    CANCELLED,
    WINDOW_DESTROYED
}

[DBus (name = "org.freedesktop.portal.Settings")]
public class Greeter.SettingsPortal : Object {
    private static GLib.Once<SettingsPortal> instance;
    public static unowned SettingsPortal get_default () {
        return instance.once (() => {
            return new SettingsPortal ();
        });
    }

    private SettingsPortal () {}

    public signal void setting_changed (string namespace, string key, GLib.Variant value);

    private int _prefers_color_scheme = 0;
    public int prefers_color_scheme {
        get {
            return _prefers_color_scheme;
        }
        set {
            _prefers_color_scheme = value;
            setting_changed ("org.freedesktop.appearance", "color-scheme", new GLib.Variant.uint32 (prefers_color_scheme));
        }
    }

    public async GLib.HashTable<string, GLib.HashTable<string, GLib.Variant>> read_all (string[] namespaces) throws GLib.DBusError, GLib.IOError {
        var dict = new GLib.HashTable<string, GLib.Variant> (str_hash, str_equal);
        dict.insert ("color-scheme", new GLib.Variant.uint32 (prefers_color_scheme));

        var ret = new GLib.HashTable<string, GLib.HashTable<string, GLib.Variant>> (str_hash, str_equal);
        ret.insert ("org.freedesktop.appearance", dict);

        return ret;
    }

    public async GLib.Variant read (string namespace, string key) throws GLib.DBusError, GLib.Error {
        if (namespace == "org.freedesktop.appearance" && key == "color-scheme") {
            return new GLib.Variant.uint32 (prefers_color_scheme);
        }

        throw new PortalError.NOT_FOUND ("Requested setting not found");
    }
}
