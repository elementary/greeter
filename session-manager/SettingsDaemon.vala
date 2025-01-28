public class GreeterSessionManager.SettingsDaemon : Object {
    private GreeterSessionManager.GnomeSessionManager session_manager;
    private SubprocessSupervisor[] supervisors = {};

    public void start () {
        /* Pretend to be GNOME session */
        session_manager = new GnomeSessionManager ();
        GLib.Bus.own_name (BusType.SESSION, "org.gnome.SessionManager", BusNameOwnerFlags.NONE,
                           (c) => {
                               try {
                                   c.register_object ("/org/gnome/SessionManager", session_manager);
                               } catch (Error e) {
                                   warning ("Failed to register /org/gnome/SessionManager: %s", e.message);
                               }
                           },
                           () => {
                            warning ("Acquired org.gnome.SessionManager");
                               start_settings_daemon ();
                           },
                           () => warning ("Failed to acquire name org.gnome.SessionManager"));
    }

    private void start_settings_daemon () {
        warning ("All bus names acquired, starting gnome-settings-daemon");

        string[] daemons = {
            "gsd-a11y-settings",
            "gsd-color",
            "gsd-media-keys",
            "gsd-sound",
            "gsd-power",
            "gsd-xsettings"
        };

        foreach (var daemon in daemons) {
            try {
                supervisors += new SubprocessSupervisor ({Constants.GSD_DIR + daemon});
            } catch (GLib.Error e) {
                critical ("Could not start %s: %s", daemon, e.message);
            }
        }
    }
}