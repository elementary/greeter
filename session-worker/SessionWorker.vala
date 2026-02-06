/*
 * Copyright 2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[DBus (name = "io.elementary.GreeterSessionWorker")]
public class SessionWorker.SessionWorker : Object {
    [DBus (visible = false)]
    [CCode (cheader_filename = "grp.h", cname = "initgroups")]
    public static extern int initgroups (string user, uint gid);

    public void launch_session (string username, HashTable<string, Variant> env_variables, string[] argvp) throws Error {
        unowned var passwd = Posix.getpwnam (username);

        var fork_pid = Posix.fork ();
        if (fork_pid < 0) {
            throw new SpawnError.FORK ("Fork failed");
        }

        if (fork_pid == 0) {
            Posix.setgid (passwd.pw_gid);
            initgroups (passwd.pw_name, (uint) passwd.pw_gid);
            Posix.setuid (passwd.pw_uid);

            foreach (unowned var key in env_variables.get_keys ()) {
                Environment.set_variable (key, env_variables[key].get_string (), true);
            }

            Posix.execv (argvp[0], argvp);
            Posix.exit (1); // Only reached if execv failed
        } else {
            //  Posix.waitpid (Posix.pid_t pid, out int status, int options)
        }
    }
}
