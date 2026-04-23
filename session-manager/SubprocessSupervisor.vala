/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2018, 2025 elementary, Inc. (https://elementary.io)
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class GreeterSessionManager.SubprocessSupervisor : GLib.Object {
    public string[] exec { get; construct; }

    private GLib.Subprocess? subprocess = null;

    public SubprocessSupervisor (string[] exec) throws GLib.Error {
        Object (exec: exec);
    }

    construct {
        ensure_run.begin ();
    }

    ~SubprocessSupervisor () {
        if (subprocess != null) {
            subprocess.force_exit ();
        }
    }

    private async void ensure_run () {
        try {
            subprocess = new GLib.Subprocess.newv (exec, GLib.SubprocessFlags.STDIN_INHERIT | GLib.SubprocessFlags.STDERR_MERGE);

            if (!yield subprocess.wait_check_async ()) {
                ensure_run.begin ();
            }
        } catch (Error e) {
            critical ("Couldn't create subprocess: %s", e.message);
        }
    }
}
