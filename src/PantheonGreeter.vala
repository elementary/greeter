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
    public static LightDM.Greeter lightdm { get; private set; }

    GtkClutter.Embed clutter;

    Clutter.Rectangle fadein;
    Clutter.Actor greeterbox;
    UserListActor userlist_actor;
    UserList userlist;

    TimeLabel time;
    Indicators indicators;
    Wallpaper wallpaper;

    Settings settings;

    public static PantheonGreeter instance { get; private set; }

    //from this width on we use the shrinked down version
    const int MIN_WIDTH = 1200;
    //from this width on the clock wont fit anymore
    const int NO_CLOCK_WIDTH = 920;

    public PantheonGreeter () {
        //singleton
        assert (instance == null);
        instance = this;

        settings = new Settings ("org.pantheon.desktop.greeter");
        lightdm = new LightDM.Greeter ();
        /*start*/
        try {
            lightdm.connect_sync ();
        } catch (Error e) {
            warning ("Couldn't connect: %s", e.message);
            Posix.exit (Posix.EXIT_FAILURE);
        }

        delete_event.connect (() => {
            Posix.exit (Posix.EXIT_SUCCESS);
            return false;
        });

        LoginOption.load_default_avatar ();

        clutter = new GtkClutter.Embed ();
        fadein = new Clutter.Rectangle.with_color ({0, 0, 0, 255});
        greeterbox = new Clutter.Actor ();
        userlist = new UserList (LightDM.UserList.get_instance ());

        userlist_actor = new UserListActor (userlist);
        time = new TimeLabel ();
        indicators = new Indicators (settings);
        wallpaper = new Wallpaper ();


        get_screen ().monitors_changed.connect (monitors_changed);

        configure_event.connect (() => {
            reposition ();
            return false;
        });

        monitors_changed ();

        userlist.current_user_changed.connect ((user) => {
            wallpaper.set_wallpaper (user.background);
            indicators.keyboard_menu.user_changed_cb (user);
        });

        lightdm.show_message.connect (wrong_pw);
        lightdm.show_prompt.connect (send_pw);
        lightdm.authentication_complete.connect (authenticated);

        /*activate the numlock if needed*/
        var activate_numlock = settings.get_boolean ("activate-numlock");
        if (activate_numlock)
            Granite.Services.System.execute_command ("/usr/bin/numlockx on");

        /*build up UI*/
        clutter.add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);
        var stage = clutter.get_stage () as Clutter.Stage;
        stage.background_color = {0, 0, 0, 255};

        greeterbox.add_child (wallpaper);
        greeterbox.add_child (time);
        greeterbox.add_child (userlist_actor);
        greeterbox.add_child (indicators);

        greeterbox.opacity = 0;

        stage.add_child (greeterbox);

        greeterbox.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
        greeterbox.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.HEIGHT, 0));
        indicators.add_constraint (new Clutter.BindConstraint (greeterbox, Clutter.BindCoordinate.WIDTH, 0));

        clutter.key_press_event.connect (keyboard_navigation);

        add (clutter);
        show_all ();

        greeterbox.animate (Clutter.AnimationMode.EASE_OUT_QUART, 1700, opacity: 255);

        var last_user = settings.get_string ("last-user");
        for (var i = 0; i < userlist.size; i++) {
            if (userlist.get_user (i).name == last_user) {
                userlist.current_user = userlist.get_user (i);
                break;
            }
        }
        if(userlist.current_user == null)
            userlist.current_user = userlist.get_user (0);

        this.get_window ().focus (Gdk.CURRENT_TIME);

        if (settings.get_boolean ("onscreen-keyboard")) {
            indicators.toggle_keyboard (true);
        }
    }

    public static LightDM.Layout? get_layout_by_name (string name) {
        foreach (var layout in LightDM.get_layouts ()) {
            if (layout.name == name)
                return layout;
        }
        return null;
    }

    void monitors_changed () {
        Gdk.Rectangle geometry;
        get_screen ().get_monitor_geometry (get_screen ().get_primary_monitor (), out geometry);
        bool small = geometry.width < MIN_WIDTH;
        resize (geometry.width, geometry.height);
        move (geometry.x, geometry.y);
        reposition ();
    }

    void reposition () {
        int width = 0;
        int height = 0;
        get_size (out width, out height);

        userlist_actor.x = 243;
        userlist_actor.y = Math.floorf (height / 2 - userlist_actor.height / 2);

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
                settings.set_boolean ("activate-numlock", !settings.get_boolean ("activate-numlock"));
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

    public void authenticate () {
        if (userlist.current_user.is_guest ())
            lightdm.authenticate_as_guest ();
        else
            lightdm.authenticate (userlist.current_user.name);
    }

    void wrong_pw (string text, LightDM.MessageType type) {
        userlist_actor.get_current_loginbox ().wrong_pw ();
    }

    void send_pw (string text, LightDM.PromptType type) {
        lightdm.respond (userlist_actor.get_current_loginbox ().get_password ());
    }

    void authenticated () {
        settings.set_string ("last-user", userlist.current_user.name);

        if (lightdm.is_authenticated) {
            fadein.show ();
            fadein.animate (Clutter.AnimationMode.EASE_OUT_QUAD, 200, opacity:255);

            try {
                lightdm.start_session_sync (userlist_actor.get_current_loginbox ().current_session);
            } catch (Error e) {
                warning (e.message);
            }
            Posix.exit (Posix.EXIT_SUCCESS);
        } else {
            userlist_actor.get_current_loginbox ().wrong_pw ();
        }
    }
}

public static int main (string [] args) {
    /* Protect memory from being paged to disk, as we deal with passwords */
    PosixMLock.mlockall (PosixMLock.MCL_CURRENT | PosixMLock.MCL_FUTURE);

    var init = GtkClutter.init (ref args);
    if (init != Clutter.InitError.SUCCESS)
        error ("Clutter could not be intiailized");

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

    Gtk.main ();

    return Posix.EXIT_SUCCESS;
}
