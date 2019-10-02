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

public class Greeter.SubprocessSupervisor : GLib.Object {
    public signal void spawned (GLib.Subprocess subprocess);

    private GLib.Subprocess subprocess;
    private string[] exec;
    private GLib.SubprocessFlags flags;
    public SubprocessSupervisor (string[] exec) throws GLib.Error {
        this.exec = exec;
        flags = GLib.SubprocessFlags.STDIN_INHERIT | GLib.SubprocessFlags.STDOUT_SILENCE | GLib.SubprocessFlags.STDERR_MERGE;
        ensure_run.begin ();
    }

    ~SubprocessSupervisor () {
        exec = {};
        subprocess.force_exit ();
    }

    private async void ensure_run () {
        try {
            subprocess = new GLib.Subprocess.newv (exec, flags);
            if (!yield subprocess.wait_check_async ()) {
                ensure_run.begin ();
            }
        } catch (Error e) {
            critical (e.message);
        }
    }
}
