/* -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*- */
/*
 * Copyright (C) 2018 elementary LLC. <https://elementary.io>
 *
 * Cerbere is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * Cerbere is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Cerbere; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA  02110-1301  USA
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class Greeter.ComponentWatcher : GLib.Object {
    public const double CRASH_TIME_INTERVAL = 3.5;
    public const uint MAX_CRASHES = 5;

    public enum Status {
        INACTIVE,  // not yet spawned
        STARTING,   // active (already spawned)
        RUNNING,   // active (already spawned)
        TERMINATED // killed/exited
    }

    private uint crash_count = 0;
    private string command;
    private Status status = Status.INACTIVE;
    private Pid pid = -1;
    private Timer? timer = null;

    public ComponentWatcher (string command) {
        this.command = command;
        run ();
    }

    public void reset_crash_count () {
        crash_count = 0;
    }

    public void run () {
        debug ("STARTING process: %s", command);

        if (status == Status.RUNNING || status == Status.STARTING) {
            warning ("Process %s is already running. Not starting it again...", command);
            return;
        }

        var default_display = Gdk.Display.get_default ();
        var launch_context = default_display.get_app_launch_context ();

        launch_context.launched.connect ((info, platform_data) => {
            // time starts counting here
            timer = new Timer ();
            platform_data.lookup ("pid", "i", out pid);
            status = Status.RUNNING;

            // Add watch
            ChildWatch.add (pid, on_process_watch_exit);
        });

       launch_context.launch_failed.connect (() => {
            status = Status.TERMINATED;
       });

        try {
            var appinfo = GLib.AppInfo.create_from_commandline (command, null, GLib.AppInfoCreateFlags.NONE);
            appinfo.launch (null, launch_context);
            status = Status.STARTING;
        } catch (Error e) {
            critical (e.message);
        }
    }

    private void on_process_watch_exit (Pid pid, int status) {
        if (pid != this.pid)
            return;

        message ("Process '%s' watch exit", command);

        // Check exit status
        if (Process.if_exited (status) || Process.if_signaled (status) || Process.core_dump (status)) {
            terminate ();
        }
    }

    public void terminate (bool restart = true) {
        if (status != Status.RUNNING)
            return;

        message ("Process %s is being terminated", command);

        Process.close_pid (pid);

        bool normal_exit = true;

        if (timer != null) {
            timer.stop ();

            double elapsed_secs = timer.elapsed ();
            message ("ET = %f secs\tMin allowed time = %f", elapsed_secs, CRASH_TIME_INTERVAL);
            if (elapsed_secs <= CRASH_TIME_INTERVAL) { // process crashed
                crash_count++;
                normal_exit = false;
                critical ("PROCESS '%s' CRASHED (#%u)", command, crash_count);
            }

            // Remove the current timer
            timer = null;
        }

        status = Status.TERMINATED;

        if (normal_exit)
            reset_crash_count ();

        /**
         * Respawning occurs here. If the process has crashed more times than
         * MAX_CRASHES, it's not respawned again. Otherwise, it is assumed that the
         * process exited normally and the crash count is reset to 0, which means
         * that only consecutive crashes are counted.
         */
        if (crash_count > MAX_CRASHES) {
            warning ("'%s' exceeded the maximum number of crashes allowed " +
                     "(%u). It won't be launched again", command, MAX_CRASHES);
            return;
        }

        if (restart) {
            run ();
        }
    }
}
