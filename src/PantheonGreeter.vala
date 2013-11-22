// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2013 elementary Developers

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
    LightDM.Greeter greeter;
    GtkClutter.Embed clutter;
    LoginBox loginbox;

    Clutter.Rectangle fadein;
    Clutter.Actor greeterbox;
    UserListActor userlist_actor;
    UserList userlist;

    TimeLabel time;
    Indicators indicators;
    Wallpaper wallpaper;

    Settings settings;

    //from this width on we use the shrinked down version
    const int MIN_WIDTH = 1200;
    //from this width on the clock wont fit anymore
    const int NO_CLOCK_WIDTH = 920;

    public PantheonGreeter () {
        settings = new Settings ("org.pantheon.desktop.greeter");
        greeter = new LightDM.Greeter ();
        /*start*/
        try {
            greeter.connect_sync ();
        } catch (Error e) {
            warning ("Couldn't connect: %s", e.message);
            Posix.exit (Posix.EXIT_FAILURE);
        }

        clutter = new GtkClutter.Embed ();
        fadein = new Clutter.Rectangle.with_color ({0, 0, 0, 255});
        greeterbox = new Clutter.Actor ();
        userlist = new UserList (LightDM.UserList.get_instance (), greeter);

        loginbox = new LoginBox (greeter);

        userlist_actor = new UserListActor (userlist);
        time = new TimeLabel ();
        indicators = new Indicators (loginbox, settings);
        wallpaper = new Wallpaper ();

        PantheonUser.load_default_avatar ();

        userlist.user_changed.connect ((user) => {
            wallpaper.set_wallpaper (user.background);
            indicators.user_changed_cb(user);
            loginbox.set_user (user);
        });

        greeter.show_message.connect (wrong_pw);
        greeter.show_prompt.connect (send_pw);
        greeter.authentication_complete.connect (authenticated);

        loginbox.login_requested.connect (authenticate);

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
        greeterbox.add_child (loginbox);
        greeterbox.add_child (indicators);

        greeterbox.add_effect_with_name ("mirror", new MirrorEffect ());
        greeterbox.depth = -1500;

        stage.add_child (greeterbox);

        greeterbox.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
        greeterbox.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.HEIGHT, 0));
        indicators.add_constraint (new Clutter.BindConstraint (greeterbox, Clutter.BindCoordinate.WIDTH, 0));

        reposition ();

        clutter.key_release_event.connect (keyboard_navigation);

        add (clutter);
        show_all ();

        reposition ();
        get_screen ().monitors_changed.connect (reposition);

        /*opening animation*/
        var d_left  = new Clutter.Rectangle.with_color ({0, 0, 0, 255});
        var d_right = new Clutter.Rectangle.with_color ({0, 0, 0, 255});

        stage.add_child (d_left);
        stage.add_child (d_right);

        d_left.width = d_right.width = stage.width / 2;
        d_left.height = d_right.height = stage.height;
        d_right.x = stage.width / 2;

        d_left.animate  (Clutter.AnimationMode.EASE_IN_CUBIC, 750, x:-d_left.width);
        d_right.animate (Clutter.AnimationMode.EASE_IN_CUBIC, 750, x:stage.width);

        greeterbox.animate (Clutter.AnimationMode.EASE_OUT_CUBIC, 1000, depth:0.0f).completed.connect ( () => {
                greeterbox.remove_effect_by_name ("mirror");
        });

        var last_user = settings.get_string ("last-user");
        if (last_user == "")
            userlist.current_user = userlist.get_user (0);
        else {
            for (var i = 0; i < userlist.size; i++) {
                if (userlist.get_user (i).name == last_user) {
                    userlist.current_user = userlist.get_user (i);
                    break;
                }
            }
        }

        indicators.bar.grab_focus ();

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

    void reposition () {
        Gdk.Rectangle geometry;
        get_screen ().get_monitor_geometry (get_screen ().get_primary_monitor (), out geometry);
        bool small = geometry.width < MIN_WIDTH;

        loginbox.x = small ? 10 : 100;

        resize (geometry.width, geometry.height);
        move (geometry.x, geometry.y);

        loginbox.y = Math.floorf (geometry.height / 2 - loginbox.height / 2);

        userlist_actor.x = loginbox.x + 143;
        userlist_actor.y = loginbox.y + 90;

        time.x = geometry.width - time.width - (small ? 10 : 100);
        time.y = geometry.height / 2 - time.height / 2;

        time.visible = geometry.width > NO_CLOCK_WIDTH;

        wallpaper.width = geometry.width;
        wallpaper.screen_width = geometry.width;
        wallpaper.height = geometry.height;
        wallpaper.screen_height = geometry.height;
        wallpaper.resize ();
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

    void authenticate () {
        loginbox.working = true;
        if (loginbox.current_user.is_guest ())
            greeter.authenticate_as_guest ();
        else
            greeter.authenticate (loginbox.get_username ());
    }

    void wrong_pw (string text, LightDM.MessageType type) {
        loginbox.wrong_pw ();
    }

    void send_pw (string text, LightDM.PromptType type) {
        greeter.respond (loginbox.get_password ());
    }

    void authenticated () {
        loginbox.working = false;

        settings.set_string ("last-user", loginbox.current_user.name);

        if (greeter.is_authenticated) {
            fadein.show ();
            fadein.animate (Clutter.AnimationMode.EASE_OUT_QUAD, 200, opacity:255);

            try {
                greeter.start_session_sync (loginbox.current_session);
            } catch (Error e) {
                warning (e.message);
            }

            Gtk.main_quit ();
        } else {
            loginbox.wrong_pw ();
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
