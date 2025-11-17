

namespace Greeter.SessionLauncher {
    private struct Session {
        string session_id;
        GLib.ObjectPath object_path;
        string runtime_path;
        int fifo_fd;
        uint uid;
        string seat_id;
        uint vtnr;
        bool existing;
    }

    [DBus (name = "org.freedesktop.login1.Manager")]
    private interface LogindManager : Object {
        public abstract void activate_session (string session_id) throws Error;
        public abstract Session create_session (
            uint uid,
            uint pid,
            string service,
            string type,
            string @class,
            string desktop,
            string seat_id,
            uint vtnr,
            string tty,
            string display,
            bool remote,
            string remote_user,
            string remote_host,
            HashTable<string, Variant> properties
        ) throws Error;
    }

    [DBus (name = "org.freedesktop.login1.Session")]
    private interface LogindSession : Object {
        public abstract void take_control (bool force) throws Error;
    }

    [DBus (name = "org.elementary.GreeterSessionWorker")]
    private interface SessionWorker : Object {
        public abstract void launch_session (string username, HashTable<string, Variant> env_variables, string[] argvp) throws Error;
    }

    private const string[] optional_environment_variables = {
        "GI_TYPELIB_PATH",
        "LANG",
        "LANGUAGE",
        "LC_ADDRESS",
        "LC_ALL",
        "LC_COLLATE",
        "LC_CTYPE",
        "LC_IDENTIFICATION",
        "LC_MEASUREMENT",
        "LC_MESSAGES",
        "LC_MONETARY",
        "LC_NAME",
        "LC_NUMERIC",
        "LC_PAPER",
        "LC_TELEPHONE",
        "LC_TIME",
        "LD_LIBRARY_PATH",
        "PATH",
        "WINDOWPATH",
        "XCURSOR_PATH",
        "XDG_CONFIG_DIRS"
    };

    public static void launch_session (string username, string desktop) throws Error {
        unowned var passwd = Posix.getpwnam (username);

        var logind_manager = Bus.get_proxy_sync<LogindManager> (SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
        var session = logind_manager.create_session (
            (uint) passwd.pw_uid,
            Posix.getpid (),
            "lightdm",
            "tty",
            "user",
            desktop,
            Environment.get_variable ("XDG_SEAT") ?? "seat0",
            2,
            "/dev/tty2",
            "",
            false, // TODO: ??
            "",
            "",
            new HashTable<string, GLib.Variant> (str_hash, str_equal)
        );

        var session_dbus = Bus.get_proxy_sync<LogindSession> (SYSTEM, "org.freedesktop.login1", session.object_path);
        session_dbus.take_control (true);

        var env_variables = new HashTable<string, Variant> (str_hash, str_equal);
        env_variables["LOGNAME"] = new Variant.string (passwd.pw_name);
        env_variables["USER"] = new Variant.string (passwd.pw_name);
        env_variables["USERNAME"] = new Variant.string (passwd.pw_name);
        env_variables["HOME"] = new Variant.string (passwd.pw_dir);
        env_variables["PWD"] = new Variant.string (passwd.pw_dir);
        env_variables["SHELL"] = new Variant.string (passwd.pw_shell);
        for (var i = 0; i < optional_environment_variables.length; i++) {
            unowned var env_value = Environment.get_variable (optional_environment_variables[i]);
            if (env_value != null) {
                env_variables[optional_environment_variables[i]] = new Variant.string (env_value);
            }
        }

        var keyfile = new KeyFile ();
        keyfile.load_from_file ("/usr/share/wayland-sessions/%s.desktop".printf (desktop), NONE);
        var exec_line = keyfile.get_string ("Desktop Entry", "Exec");

        string[] argvp;
        Shell.parse_argv (exec_line, out argvp);

        var session_worker = Bus.get_proxy_sync<SessionWorker> (SYSTEM, "org.freedesktop.GreeterSessionWorker", "/io/elementary/greeter-session-worker");
        session_worker.launch_session (username, env_variables, argvp);

        logind_manager.activate_session (session.session_id);
    }
}
