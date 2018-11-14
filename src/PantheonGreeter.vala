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
    GtkClutter.Actor wallpaper_actor;
    GtkClutter.Actor time_actor;

    Clutter.Actor greeterbox;
    UserListActor userlist_actor;
    UserList userlist;

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
    private static SettingsDaemon settings_daemon;

    //from this width on we use the shrinked down version
    const int NORMAL_WIDTH = 1200;
    //from this width on the clock wont fit anymore
    const int NO_CLOCK_WIDTH = 920;

    public static bool TEST_MODE { get; private set; }

    public PantheonGreeter () {
        //singleton
        assert (instance == null);
        decorated = false;
        type_hint = Gdk.WindowTypeHint.DESKTOP;
        instance = this;

        TEST_MODE = Environment.get_variable ("LIGHTDM_TO_SERVER_FD") == null;

        if (TEST_MODE) {
            message ("Using dummy LightDM because LIGHTDM_TO_SERVER_FD was not found.");
            login_gateway = new DummyGateway ();
        } else {
            login_gateway = new LightDMGateway ();
            settings_daemon = new SettingsDaemon ();
            settings_daemon.start ();

            try {
                var panel = AppInfo.create_from_commandline ("wingpanel -g", null, GLib.AppInfoCreateFlags.NONE);
                panel.launch (null, null);
            } catch (Error e) {
                warning ("Failed to start panel: %s", e.message);
            }
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
            settings.load_from_file (Path.build_filename (Constants.CONF_DIR, "io.elementary.greeter.conf"), KeyFileFlags.KEEP_COMMENTS);
        } catch (Error e) {
            warning (e.message);
        }

        clutter = new GtkClutter.Embed ();
        clutter.add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);

        var stage = clutter.get_stage () as Clutter.Stage;
        stage.background_color = {0, 0, 0, 255};

        userlist = new UserList (LightDM.UserList.get_instance ());
        userlist_actor = new UserListActor (userlist);

        var time_label = new TimeLabel ();

        time_actor = new GtkClutter.Actor ();
        ((Gtk.Container) time_actor.get_widget ()).add (time_label);

        wallpaper = new Wallpaper ();

        wallpaper_actor = new GtkClutter.Actor ();
        ((Gtk.Container) wallpaper_actor.get_widget ()).add (wallpaper);

        monitors_changed ();

        greeterbox = new Clutter.Actor ();
        greeterbox.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
        greeterbox.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.HEIGHT, 0));
        greeterbox.opacity = 0;
        greeterbox.save_easing_state ();
        greeterbox.set_easing_mode (Clutter.AnimationMode.EASE_OUT_QUART);
        greeterbox.set_easing_duration (250);
        greeterbox.set_opacity (255);
        greeterbox.restore_easing_state ();

        greeterbox.add_child (wallpaper_actor);
        greeterbox.add_child (time_actor);
        greeterbox.add_child (userlist_actor);

        stage.add_child (greeterbox);

        add (clutter);

        bool activate_numlock = false;
        try {
            activate_numlock = settings.get_boolean ("greeter", "activate-numlock");
        } catch (Error e) {
            warning (e.message);
        }
        if (activate_numlock) {
            Granite.Services.System.execute_command ("/usr/bin/numlockx on");
        }

        var screensaver_timeout = 60;
        try {
            screensaver_timeout = settings.get_integer ("greeter", "screensaver-timeout");
        } catch (Error e) {
            warning (e.message);
        }

        unowned X.Display display = (Gdk.Display.get_default () as Gdk.X11.Display).get_xdisplay ();

        display.get_screensaver (out timeout, out interval, out prefer_blanking, out allow_exposures);
        display.set_screensaver (screensaver_timeout, 0, Screensaver.ACTIVE, Exposures.DEFAULT_EXPOSURES);

        if (login_gateway.lock) {
            display.force_screensaver (Screensaver.ACTIVE);
        }

        connect_signals ();

        var select_user = login_gateway.select_user;
        var switch_to_user = (select_user != null) ? select_user : get_greeter_state ("last-user");

        if (switch_to_user != null) {
            for (var i = 0; i < userlist.size; i++) {
                if (userlist.get_user (i).name == switch_to_user) {
                    userlist.current_user = userlist.get_user (i);
                    break;
                }
            }
        }

        if (userlist.current_user == null) {
            userlist.current_user = userlist.get_user (0);
        }

        get_style_context ().add_class ("greeter");

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("io/elementary/greeter/Greeter.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        show_all ();

        this.get_window ().focus (Gdk.CURRENT_TIME);
    }

    void connect_signals () {
        get_screen ().monitors_changed.connect (monitors_changed);

        login_gateway.login_successful.connect (() => {
            fade_out_ui ();
            /* restore screensaver setting, just like lightdm-gtk-greeter.c*/
            unowned X.Display display = (Gdk.Display.get_default () as Gdk.X11.Display).get_xdisplay ();
            message ("restore user timeout: %d", timeout);
            display.set_screensaver (timeout, interval, prefer_blanking, allow_exposures);
        });

        configure_event.connect (() => {
            reposition ();
            return false;
        });

        delete_event.connect (() => {
            if (TEST_MODE) {
                Posix.exit (Posix.EXIT_SUCCESS);
            }
            return !TEST_MODE;
        });

        userlist.current_user_changed.connect ((user) => {
            wallpaper.set_wallpaper (user.background);
        });

        clutter.key_press_event.connect (keyboard_navigation);

        scroll_event.connect (scroll_navigation);
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
        var anim = fade_out_actor (time_actor);
        fade_out_actor (userlist_actor);

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

        Gdk.Rectangle geometry;
        get_screen ().get_monitor_geometry (get_screen ().get_primary_monitor (), out geometry);

        width = geometry.width;
        height = geometry.height;

        if (width > NORMAL_WIDTH) {
            userlist_actor.x = 243;
        } else {
            userlist_actor.x = 120 * ((float) (width) / NORMAL_WIDTH);
        }

        userlist_actor.y = Math.floorf (height / 2.0f);

        time_actor.x = width - time_actor.width - time_actor.width / 2 - 100;
        time_actor.y = height / 2 - time_actor.height / 2;

        time_actor.visible = width > NO_CLOCK_WIDTH + time_actor.width / 2;

        wallpaper_actor.width = width;
        wallpaper_actor.height = height;

        wallpaper.screen_width = width;
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
                                     screen.get_width () * root_window.get_scale_factor (),
                                     screen.get_height () * root_window.get_scale_factor (),
                                     visual.get_depth ());

        /* Convert into a Cairo surface */
        var surface = new Cairo.XlibSurface (display, (int) pixmap,
                                             xvisual,
                                             screen.get_width () * root_window.get_scale_factor (),
                                             screen.get_height () * root_window.get_scale_factor ());

        return surface;
    }

    void draw_wallpaper_on_surface (Cairo.Surface surface) {
        var ctx = new Cairo.Context (surface);
        ctx.save ();
        ctx.set_source_rgba (0.0, 0.0, 0.0, 0.0);

        int scale_factor = get_screen ().get_root_window ().get_scale_factor ();
        int width = get_screen ().get_width () * scale_factor;
        int height = get_screen ().get_height () * scale_factor;

        var current_pixbuf = Wallpaper.scale_to_rect (wallpaper.background_pixbuf, width, height);

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
    var compositor = new Greeter.ComponentWatcher ("io.elementary.greeter-compositor");

    /* Protect memory from being paged to disk, as we deal with passwords */
    Posix.mlockall (Posix.MCL_CURRENT | Posix.MCL_FUTURE);

    var init = GtkClutter.init (ref args);

    if (init != Clutter.InitError.SUCCESS) {
        error ("Clutter could not be intiailized");
    }

    GLib.Unix.signal_add (GLib.ProcessSignal.TERM, () => {
        compositor.terminate (false);
        Gtk.main_quit ();
        return true;
    });

    /*some settings*/
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (Constants.GETTEXT_PACKAGE);

    var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (),
                                             Gdk.CursorType.LEFT_PTR);
    Gdk.get_default_root_window ().set_cursor (cursor);

    var icon_theme = Gtk.IconTheme.get_default ();
    icon_theme.add_resource_path ("/io/elementary/greeter/icons");

    new PantheonGreeter ();
    Gtk.main ();
    compositor.terminate (false);
    return Posix.EXIT_SUCCESS;
}
