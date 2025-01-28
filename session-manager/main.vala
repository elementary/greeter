public class GreeterSessionManager.Application : GLib.Object {
    public static int main (string[] args) {
        var settings_daemon = new SettingsDaemon ();
        settings_daemon.start ();

        var loop = new GLib.MainLoop (GLib.MainContext.default (), true);
        loop.run ();

        return 0;
	}
}
