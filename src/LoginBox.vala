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

using Gtk;

public const string LIGHT_WINDOW_STYLE = """
    .content-view-window {
        background-image:none;
        background-color:@bg_color;

        border-radius: 5px;

        border-width: 1px;
        border-style: solid;
        border-color: alpha (#000, 0.4);
    }
""";

public class LoginBox : GtkClutter.Actor {
    public PantheonUser current_user { get; private set; }
    public string current_session { get; private set; }

    ulong avatar_handler = 0;

    EventBox avatar;
    ToggleButton settings;
    Grid grid;
    Spinner spinner;
    Gdk.Pixbuf image;
    EventBox credentials_box;
    CredentialsArea credentials;
    PantheonUser previous_user = null;

    Granite.Drawing.BufferSurface buffer;
    int shadow_blur = 25;
    int shadow_x = 0;
    int shadow_y = 6;
    double shadow_alpha = 0.6;

    LightDM.Greeter greeter;

    Window draw_ref;

    public bool high_contrast {
        set {
            if (value)
                draw_ref.get_style_context ().remove_class ("content-view-window");
            else
                draw_ref.get_style_context ().add_class ("content-view-window");
        }
    }

    public signal void login_requested ();

    bool _working;
    public bool working {
        get {
            return _working;
        } set {
            _working = value;
            grid.remove ((_working)?avatar as Widget:spinner as Widget);
            grid.attach ((_working)?spinner as Widget:avatar as Widget, 0, 0, 1, 3);
            grid.show_all ();
            spinner.start ();
            if (LightDM.get_sessions ().length () == 1)
                settings.hide ();
        }
    }

    public LoginBox (LightDM.Greeter greeter, PantheonUser start_user) {
        this.greeter = greeter;

        this.reactive = true;
        this.scale_gravity = Clutter.Gravity.CENTER;

        try {
            this.image = IconTheme.get_default ().load_icon ("avatar-default", 92, 0);
        } catch (Error e) {
            warning (e.message);
        }

        this.avatar = new EventBox ();
        this.settings = new ToggleButton ();
        this.credentials_box = new EventBox ();
        this.credentials = new GuestLogin (start_user);

        width = 510;
        height = 168;

        avatar.set_size_request (92, 92);
        avatar.valign = Align.START;
        avatar.visible_window = false;
        settings.valign  = Align.START;
        settings.relief  = ReliefStyle.NONE;
        settings.add (new Image.from_icon_name ("application-menu-symbolic", IconSize.MENU));

        spinner = new Spinner ();
        spinner.valign = Align.CENTER;
        spinner.start ();
        spinner.set_size_request (92, 92);

        grid = new Grid ();

        grid.attach (avatar, 0, 0, 1, 3);
        grid.attach (credentials_box, 1, 0, 1, 3);
        grid.attach (settings, 2, 0, 1, 1);
        grid.margin = shadow_blur + 12;
        grid.margin_top += 5;
        grid.margin_bottom -= 12;
        grid.column_spacing = 12;

        avatar.draw.connect ((ctx) => {
            Granite.Drawing.Utilities.cairo_rounded_rectangle (ctx, 0, 0,
                avatar.get_allocated_width (), avatar.get_allocated_height (), 3);
            Gdk.cairo_set_source_pixbuf (ctx, image, 0, 0);
            ctx.fill_preserve ();
            ctx.set_line_width (1);
            ctx.set_source_rgba (0, 0, 0, 0.3);
            ctx.stroke ();
            return false;
        });

        create_popup ();

        /* draw the window stylish! */
        var css = new CssProvider ();
        try {
            css.load_from_data (LIGHT_WINDOW_STYLE, -1);
        } catch (Error e) {
            warning (e.message);
        }

        draw_ref = new Window ();
        draw_ref.get_style_context ().add_class ("content-view-window");
        draw_ref.get_style_context ().add_provider (css, STYLE_PROVIDER_PRIORITY_FALLBACK);

        var w = -1; var h = -1;
        this.get_widget ().size_allocate.connect (() => {
            if (w == this.get_widget ().get_allocated_width () &&
                h == this.get_widget ().get_allocated_height ())
                return;

            w = this.get_widget ().get_allocated_width ();
            h = this.get_widget ().get_allocated_height ();

            this.buffer = new Granite.Drawing.BufferSurface (w, h);

            this.buffer.context.rectangle (shadow_blur + shadow_x + 3,
                                           shadow_blur + shadow_y*2, w - shadow_blur*2 + shadow_x - 6, h - shadow_blur*2 - shadow_y);
            this.buffer.context.set_source_rgba (0, 0, 0, shadow_alpha);
            this.buffer.context.fill ();
            this.buffer.exponential_blur (shadow_blur / 2-2);

            draw_ref.get_style_context ().render_activity (this.buffer.context, shadow_blur + shadow_x,
                                                           shadow_blur + shadow_y -2, w - shadow_blur*2 + shadow_x, h - shadow_blur*2);
        });

        this.get_widget ().draw.connect ((ctx) => {
            ctx.rectangle (0, 0, w, h);
            ctx.set_operator (Cairo.Operator.SOURCE);
            ctx.set_source_rgba (0, 0, 0, 0);
            ctx.fill ();

            ctx.set_source_surface (buffer.surface, 0, 0);
            ctx.paint ();

            return false;
        });

        ((Container) this.get_widget ()).add (grid);
        this.get_widget ().show_all ();
        this.get_widget ().get_style_context ().add_class ("content-view");
    }

    public string get_password () {
        return credentials.userpassword;
    }

    public void wrong_pw () {
        credentials.reset_pw ();
        this.animate (Clutter.AnimationMode.EASE_IN_BOUNCE, 150, scale_x:0.9f, scale_y: 0.9f).
        completed.connect (() => {
            Clutter.Threads.Timeout.add (1, () => {
                this.animate (Clutter.AnimationMode.EASE_OUT_BOUNCE, 150, scale_x:1.0f, scale_y: 1.0f);
                return false;
            });
        });
    }

    private void create_popup () {
        PopOver pop = null;
        /*session choose popover*/
        this.settings.toggled.connect (() => {
            if (!settings.active) {
                pop.destroy ();
                return;
            }

            pop = new PopOver ();

            var box = new Box (Orientation.VERTICAL, 0);
            (pop.get_content_area () as Container).add (box);

            var but = new RadioButton.with_label (null, LightDM.get_sessions ().nth_data (0).name);
            box.pack_start (but, false);
            but.active = LightDM.get_sessions ().nth_data (0).key == current_session;

            but.toggled.connect (() => {
                if (but.active)
                    current_session = LightDM.get_sessions ().nth_data (0).key;
            });

            for (var i = 1;i < LightDM.get_sessions ().length (); i++) {
                var rad = new RadioButton.with_label_from_widget (but, LightDM.get_sessions ().nth_data (i).name);
                box.pack_start (rad, false);
                rad.active = LightDM.get_sessions ().nth_data (i).key == current_session;
                var identifier = LightDM.get_sessions ().nth_data (i).key;
                rad.toggled.connect ( () => {
                    if (rad.active)
                        current_session = identifier;
                });
            }

            this.get_stage ().add_child (pop);

            pop.x = this.x + this.width - 265;
            pop.width = 245;
            pop.y = this.y + 50;
            pop.get_widget ().show_all ();
            pop.destroy.connect (() => {
                settings.active = false;
            });
        });
    }

    private void update_credentials () {
        if (credentials_box.get_child () != null)
            credentials_box.remove (credentials_box.get_child ());
        credentials_box.add (credentials);

        if (previous_user != null && avatar_handler != 0) {
            previous_user.disconnect (avatar_handler);
        }

        image = credentials.user.get_avatar ();
        avatar.queue_draw ();
        avatar_handler = credentials.user.avatar_updated.connect (() => {
            image = credentials.user.get_avatar ();
            avatar.queue_draw ();
        });

        credentials.request_login.connect (() => {
            login_requested ();
        });

        credentials_box.show_all ();
    }

    public void set_user (PantheonUser user) {
        credentials.reset_pw ();
        previous_user = credentials.user;

        if (user.is_guest ()) {
            credentials = new GuestLogin (user);
            update_credentials ();
            current_session = greeter.default_session_hint;
        }
        if (user.is_manual ()) {
            credentials = new ManualLogin (user);
            update_credentials ();
            current_session = greeter.default_session_hint;
        }

        if (user.is_normal ()) {
            credentials = new UserLogin (user);
            update_credentials ();
            current_session = user.get_lightdm_user ().session;
        }

        this.current_user = user;

        /*LightDM.Layout layout = null;
        LightDM.get_layouts ().foreach ((l) => {
                if (l.name == user.get_lightdm_user ().layout)
                    layout = l;
        });

        if (layout != null)
            LightDM.set_layout (layout);
        FIXME */
        credentials.pass_focus ();
        if (LightDM.get_sessions ().length () == 1)
            settings.hide ();
    }
}
