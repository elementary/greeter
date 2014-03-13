

public class PowerMenu : Gtk.MenuItem {

    public PowerMenu () {
        try {
            add (new Gtk.Image.from_pixbuf (Gtk.IconTheme.get_default ().lookup_by_gicon (
                                                  new GLib.ThemedIcon.with_default_fallbacks ("system-shutdown-symbolic"), 16, 0)
                                                  .load_symbolic ({1,1,1,1})));
        } catch (Error e) {
            warning (e.message);
        }

        submenu = new Gtk.Menu ();

        var poweroff = new Gtk.MenuItem.with_label (_("Shutdown"));
        var suspend = new Gtk.MenuItem.with_label (_("Suspend"));
        var restart = new Gtk.MenuItem.with_label (_("Restart"));
        var hibernate = new Gtk.MenuItem.with_label (_("Hibernate"));

        if (LightDM.get_can_hibernate ())
            submenu.append (hibernate);

        if (LightDM.get_can_suspend ())
            submenu.append (suspend);

        if (LightDM.get_can_restart ())
            submenu.append (restart);

        if (LightDM.get_can_shutdown ())
            submenu.append (poweroff);

        poweroff.activate.connect (() => {
            try { LightDM.shutdown (); } catch (Error e) { warning (e.message); }
        });
        suspend.activate.connect (() => {
            try { LightDM.suspend (); } catch (Error e) { warning (e.message); }
        });
        restart.activate.connect (() => {
            try { LightDM.restart (); } catch (Error e) { warning (e.message); }
        });
        hibernate.activate.connect (() => {
            try { LightDM.hibernate (); } catch (Error e) { warning (e.message); }
        });
    }

}