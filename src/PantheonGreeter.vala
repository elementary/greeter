// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2014 elementary Developers

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/

public class PantheonGreeter : Gtk.Window {

    public static LoginGateway login_gateway { get; private set; }

    GtkClutter.Embed clutter;

    Clutter.Actor greeterbox;
    UserListActor userlist_actor;
    UserList userlist;

    TimeLabel time;
    Indicators.IndicatorBar indicator_bar;
    Wallpaper wallpaper;

    int timeout;
    int interval;
    int prefer_blanking;
    int allow_exposures;

    /* taken from X11/X.h */
    enum Blanking {
        DONT_PREFER_BLANKING,
        PREFER_BLANKING,
        DEFAULT_BLANKING
    }
    enum Exposures {
        DONT_PREFER_EXPOSURES,
        PREFER_EXPOSURES,
        DEFAULT_EXPOSURES
    }
    enum Screensaver {
        RESET,
        ACTIVE
    }

    //public Settings settings { get; private set; }
    public KeyFile settings;
    public KeyFile state;
    private string state_file;

    public static PantheonGreeter instance { get; private set; }

    //from this width on we use the shrinked down version
    const int NORMAL_WIDTH = 1200;
    //from this width on the clock wont fit anymore
    const int NO_CLOCK_WIDTH = 920;

    public static bool TEST_MODE { get; private set; }

    public PantheonGreeter () {
        //singleton
        assert (instance == null);
        instance = this;

        TEST_MODE = Environment.get_variable ("LIGHTDM_TO_SERVER_FD") == null;

        if (TEST_MODE) {
            message ("Using dummy LightDM because LIGHTDM_TO_SERVER_FD was not found.");
            login_gateway = new DummyGateway ();
        } else {
            login_gateway = new LightDMGateway ();
        }

        var state_dir = Path.build_filename (Environment.get_user_cache_dir (), "unity-greeter");
        DirUtils.create_with_parents (state_dir, 0775);

        var xdg_seat = GLib.Environment.get_variable("XDG_SEAT");
        var state_file_name = xdg_seat != null && xdg_seat != "seat0" ? xdg_seat + "-state" : "state";

        state_file = Path.build_filename (state_dir, state_file_name);
        state = new KeyFile ();
        try {
            state.load_from_file (state_file, KeyFileFlags.NONE);
        } catch (Error e) {
            if (!(e is FileError.NOENT)) {
                warning ("Failed to load state from %s: %s\n", state_file, e.message);
            }
        }
        
        settings = new KeyFile ();
        try {
            settings.load_from_file (Constants.CONF_DIR+"/pantheon-greeter.conf",
                    KeyFileFlags.KEEP_COMMENTS);
        } catch (Error e) {
            warning (e.message);
        }

        delete_event.connect (() => {
            message ("Window got closed. Exiting...");
            Posix.exit (Posix.EXIT_SUCCESS);
            return false;
        });

        message ("Loading default-avatar...");
        LoginOption.load_default_avatar ();

        message ("Building UI...");
        clutter = new GtkClutter.Embed ();
        greeterbox = new Clutter.Actor ();

        userlist = new UserList (LightDM.UserList.get_instance ());
        userlist_actor = new UserListActor (userlist);

        time = new TimeLabel ();

        indicator_bar = new Indicators.IndicatorBar ();

        wallpaper = new Wallpaper ();

        message ("Connecting signals...");
        get_screen ().monitors_changed.connect (monitors_changed);

        login_gateway.login_successful.connect (() => {
            fade_out_ui ();

            /* restore screensaver setting, just like lightdm-gtk-greeter.c*/
            unowned X.Display display = (Gdk.Display.get_default () as Gdk.X11.Display).get_xdisplay ();
            message ("restore user timeout: %d", timeout);
            display.set_screensaver (timeout, interval, prefer_blanking,
                allow_exposures);
        });

        configure_event.connect (() => {
            reposition ();
            return false;
        });

        monitors_changed ();

        userlist.current_user_changed.connect ((user) => {
            wallpaper.set_wallpaper (user.background);
        });

        /*activate the numlock if needed*/
        bool activate_numlock = false;
        try {
            activate_numlock = settings.get_boolean ("greeter", "activate-numlock");
        } catch (Error e) {
            warning (e.message);
        }
        if (activate_numlock)
            Granite.Services.System.execute_command ("/usr/bin/numlockx on");

        /* activate screensaver, just like lightdm-gtk-greeter.c*/
        var screensaver_timeout = 60;
        try {
            screensaver_timeout = settings.get_integer ("greeter", "screensaver-timeout");
        } catch (Error e) {
            warning (e.message);
        }

        unowned X.Display display = (Gdk.Display.get_default () as Gdk.X11.Display).get_xdisplay ();

        display.get_screensaver (out timeout, out interval,
                out prefer_blanking, out allow_exposures);
        message ("saving Screensaver timeout %d", timeout);
        message ("set greeter screensaver timeout %d", screensaver_timeout);
        display.set_screensaver (screensaver_timeout, 0, Screensaver.ACTIVE,
                Exposures.DEFAULT_EXPOSURES);
        if (login_gateway.lock) {
            display.force_screensaver (Screensaver.ACTIVE);
        }

        /*build up UI*/
        clutter.add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);
        var stage = clutter.get_stage () as Clutter.Stage;
        stage.background_color = {0, 0, 0, 255};

        greeterbox.add_child (wallpaper);
        greeterbox.add_child (time);
        greeterbox.add_child (userlist_actor);
        greeterbox.add_child (indicator_bar);

        greeterbox.opacity = 0;

        stage.add_child (greeterbox);

        greeterbox.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
        greeterbox.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.HEIGHT, 0));

        indicator_bar.add_constraint (new Clutter.BindConstraint (greeterbox, Clutter.BindCoordinate.WIDTH, 0));

        clutter.key_press_event.connect (keyboard_navigation);

        add (clutter);
        show_all ();

        scroll_event.connect (scroll_navigation);

        greeterbox.animate (Clutter.AnimationMode.EASE_OUT_QUART, 250, opacity: 255);

        message ("Selecting last used user...");

        var last_user = get_greeter_state ("last-user");

        if (last_user == null) {
            warning ("last user not set");
        } else {
            for (var i = 0; i < userlist.size; i++) {
                if (userlist.get_user (i).name == last_user) {
                    userlist.current_user = userlist.get_user (i);
                    break;
                }
            }
        }

        if (userlist.current_user == null)
            userlist.current_user = userlist.get_user (0);

        message ("Finished building UI...");
        this.get_window ().focus (Gdk.CURRENT_TIME);
    }

    /**
     * Fades out an actor and returns the used transition that we can
     * connect us to its completed-signal.
     */
    Clutter.PropertyTransition fade_out_actor (Clutter.Actor actor) {
        var transition = new Clutter.PropertyTransition ("opacity");
        transition.animatable = actor;
        transition.set_duration (300);
        transition.set_progress_mode (Clutter.AnimationMode.EASE_OUT_CIRC);
        transition.set_from_value (actor.opacity);
        transition.set_to_value (0);
        actor.add_transition ("fadeout", transition);
        return transition;
    }

    /**
     * Fades out the ui and then starts the session.
     * Only call this if the LoginGateway has signaled it is awaiting
     * start_session by firing login_successful!.
     */
    void fade_out_ui () {
        refresh_background ();

        // The animations are always the same. If they would have different
        // lengths we need to use a TransitionGroup to determine
        // the correct time everything is faded out.
        var anim = fade_out_actor (time);
        fade_out_actor (userlist_actor);
        if (!TEST_MODE)
            fade_out_actor (indicator_bar);

        anim.completed.connect (() => {
            login_gateway.start_session ();
        });
    }

    void monitors_changed () {
        Gdk.Rectangle geometry;
        get_screen ().get_monitor_geometry (get_screen ().get_primary_monitor (), out geometry);
        resize (geometry.width, geometry.height);
        move (geometry.x, geometry.y);
        reposition ();
    }

    void reposition () {
        int width = 0;
        int height = 0;

        get_size (out width, out height);

        if (width > NORMAL_WIDTH) {
            userlist_actor.x = 243;
        } else {
            userlist_actor.x = 120 * ((float) (width) / NORMAL_WIDTH);
        }
        userlist_actor.y = Math.floorf (height / 2.0f);

        time.x = width - time.width - 100;
        time.y = height / 2 - time.height / 2;

        time.visible = width > NO_CLOCK_WIDTH;

        wallpaper.width = width;
        wallpaper.screen_width = width;
        wallpaper.height = height;
        wallpaper.screen_height = height;
        wallpaper.reposition ();
    }

    bool keyboard_navigation (Gdk.EventKey e) {
        switch (e.keyval) {
            case Gdk.Key.Num_Lock:
                var activate_numlock = false;
                try {
                    activate_numlock = settings.get_boolean ("greeter", "activate-numlock");
                } catch (Error e) {
                    warning (e.message);
                }

                settings.set_boolean ("greeter", "activate-numlock", !activate_numlock);
                break;
            case Gdk.Key.Up:
                userlist.select_prev_user ();
                break;
            case Gdk.Key.Down:
                userlist.select_next_user ();
                break;
            default:
                return false;
        }

        return true;
    }

    bool scroll_navigation (Gdk.EventScroll e) {
        switch (e.direction) {
        case Gdk.ScrollDirection.UP:
            userlist.select_prev_user ();
            break;
        case Gdk.ScrollDirection.DOWN:
            userlist.select_next_user ();
            break;
        }

        return false;
    }

    public string? get_greeter_state (string key) {
        try {
            return state.get_value ("greeter", key);
        } catch (Error e) {
            return null;
        }
    }

    public void set_greeter_state (string key, string value) {
        state.set_value ("greeter", key, value);
        var data = state.to_data ();

        try {
            FileUtils.set_contents (state_file, data);
        } catch (Error e) {
            warning ("Failed to write state: %s", e.message);
        }
    }

    Cairo.XlibSurface? create_root_surface (Gdk.Screen screen) {
        var visual = screen.get_system_visual ();
        var xvisual = (visual as Gdk.X11.Visual).get_xvisual ();

        var gdk_display = (screen.get_display () as Gdk.X11.Display);
        unowned X.Display display = gdk_display.get_xdisplay ();

        var root_window = (screen.get_root_window () as Gdk.X11.Window);
        var pixmap = X.create_pixmap (display,
                                     root_window.get_xid (),
                                     screen.get_width (),
                                     screen.get_height (),
                                     visual.get_depth ());

        /* Convert into a Cairo surface */
        var surface = new Cairo.XlibSurface (display, (int) pixmap,
                                             xvisual,
                                             screen.get_width (),
                                             screen.get_height ());

        return surface;
    }

    void draw_wallpaper_on_surface (Cairo.Surface surface) {
        var ctx = new Cairo.Context (surface);
        ctx.save ();
        ctx.set_source_rgba (0.0, 0.0, 0.0, 0.0);

        var current_pixbuf = wallpaper.background_pixbuf;

        var img_surface = new Cairo.Surface.similar (surface, Cairo.Content.COLOR_ALPHA,
                                                     current_pixbuf.width,
                                                     current_pixbuf.height);

        var img_ctx = new Cairo.Context (img_surface);

        Gdk.cairo_set_source_pixbuf (img_ctx, current_pixbuf,
                                     0, 0);

        img_ctx.paint ();

        ctx.set_source_surface (img_surface, 0, 0);
        ctx.paint ();
        ctx.restore ();
    }

    void refresh_background () {
        var screen = get_screen ();
        var root_window = (screen.get_root_window () as Gdk.X11.Window);
        var background_surface = create_root_surface (screen);

        draw_wallpaper_on_surface (background_surface);

        Gdk.flush ();

        var x_display = (screen.get_display () as Gdk.X11.Display);
        unowned X.Display display = x_display.get_xdisplay ();

        /* Ensure Cairo has actually finished it's drawing */
        background_surface.flush ();

        /* Use this pixmap for the background */
        X.set_window_background_pixmap (display,
                                     root_window.get_xid (),
                                     background_surface.get_drawable ());

        X.clear_window (display, root_window.get_xid ());
    }
}

public static int main (string [] args) {
    message ("Starting pantheon-greeter...");
    /* Protect memory from being paged to disk, as we deal with passwords */
    Posix.mlockall (Posix.MCL_CURRENT | Posix.MCL_FUTURE);

    var init = GtkClutter.init (ref args);
    if (init != Clutter.InitError.SUCCESS)
        error ("Clutter could not be intiailized");

    message ("Registering TERM signal...");
    GLib.Unix.signal_add (GLib.ProcessSignal.TERM, () => {
        message ("SIGTERM received, exiting...");
        Gtk.main_quit ();
        return true;
    });

    message ("Applying settings...");
    /*some settings*/
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bind_textdomain_codeset ("pantheon-greeter", "UTF-8");
    Intl.textdomain ("pantheon-greeter");

    Gdk.get_default_root_window ().set_cursor (new Gdk.Cursor (Gdk.CursorType.LEFT_PTR));

    var settings = Gtk.Settings.get_default ();
    settings.gtk_theme_name = "elementary";
    settings.gtk_icon_theme_name = "elementary";
    settings.gtk_font_name = "Droid Sans";
    settings.gtk_xft_dpi= (int) (1024 * 96);
    settings.gtk_xft_antialias = 1;
    settings.gtk_xft_hintstyle = "hintslight";
    settings.gtk_xft_rgba = "rgb";
    settings.gtk_cursor_blink = true;

    new PantheonGreeter ();
    message ("Entering main-loop...");
    Gtk.main ();
    message ("Gtk.main exited - shutting down.");
    return Posix.EXIT_SUCCESS;
}
