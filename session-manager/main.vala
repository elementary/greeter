/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class GreeterSessionManager.Application : GLib.Object {
    public static int main (string[] args) {
        new SettingsDaemon ();

        var loop = new GLib.MainLoop (GLib.MainContext.default (), true);
        loop.run ();

        return 0;
	}
}
