
public const string LIGHT_WINDOW_STYLE = """
    .content-view-window {
        background-image:none;
        background-color:@bg_color;
        
        border-radius: 6px;
        
        border-width:1px;
        border-style: solid;
        border-color: alpha (#000, 0.25);
    }
""";

public class LoginBox : GtkClutter.Actor {
    
    public const string DEFAULT_WALLPAPER = "/usr/share/backgrounds/16.jpg";
    
    public LightDM.User current_user { get; private set; }
    public string      current_session { get; private set; }
    
    public Gtk.EventBox avatar;
    public Gtk.Label    username;
    public Gtk.Entry    password;
    public Gtk.Button   login;
    public Gtk.ToggleButton settings;
    Gtk.Grid             grid;
    Gtk.Spinner          spinner;
    Gdk.Pixbuf           image;
    
    public Clutter.Texture background;   //not added to the box
    public Clutter.Texture background_s; //double buffered!
    
    Granite.Drawing.BufferSurface buffer;
    int shadow_blur = 30;
    int shadow_x    = 0;
    int shadow_y    = 0;
    double shadow_alpha = 0.5;
    
    LightDM.Greeter greeter;
    
    bool _working;
    public bool working {
        get { return _working; }
        set {
            _working = value;
            grid.remove ((_working)?avatar as Gtk.Widget:spinner as Gtk.Widget);
            grid.attach ((_working)?spinner as Gtk.Widget:avatar as Gtk.Widget, 0, 0, 1, 3);
            grid.show_all ();
            if (_working)
                spinner.start ();
            else
                spinner.stop ();
        }
    }
    
    public void set_wallpaper (string path) {
        this.background_s.opacity = 0;
        try {
            this.background_s.set_from_file (path);
        } catch (Error e) { warning (e.message); }
        this.background_s.animate (Clutter.AnimationMode.EASE_OUT_QUAD, 400, opacity:255).
            completed.connect ( () => {
            try {
                this.background.set_from_file (path);
            } catch (Error e) { warning (e.message); }
            this.background_s.opacity = 0;
        });
    }
    
    public LoginBox (LightDM.Greeter greeter) {
        
        this.greeter = greeter;
        
        this.reactive = true;
        this.scale_gravity = Clutter.Gravity.CENTER;
        
        this.background = new Clutter.Texture.from_file (DEFAULT_WALLPAPER);
        this.background_s = new Clutter.Texture ();
        this.background_s.opacity = 0;
        this.background.load_async = true;
        this.background_s.load_async = true;
        
        //this.background.add_effect (new Clutter.BlurEffect ());
        //this.background_s.add_effect (new Clutter.BlurEffect ());
        
        try {
            this.image   = Gtk.IconTheme.get_default ().load_icon ("avatar-default", 96, 0);
        } catch (Error e) { warning (e.message); }
        
        this.avatar   = new Gtk.EventBox ();
        this.username = new Gtk.Label ("");
        this.password = new Gtk.Entry ();
        this.login    = new Gtk.Button.with_label (_("Login"));
        this.settings = new Gtk.ToggleButton ();
        
        /*avatar.margin_top = 15;
        avatar.margin_left = 15;*/
        avatar.set_size_request (97, 97);
        avatar.valign = Gtk.Align.START;
        avatar.visible_window = false;
        username.hexpand = true;
        username.halign  = Gtk.Align.START;
        username.ellipsize = Pango.EllipsizeMode.END;
        username.margin_top = 10;
        login.expand    = false;
        login.height_request = 1;
        login.width_request = 140;
        login.margin_top    = 30;
        login.halign = Gtk.Align.END;
        settings.valign  = Gtk.Align.START;
        settings.relief  = Gtk.ReliefStyle.NONE;
        settings.add (new Gtk.Image.from_icon_name ("application-menu-symbolic", Gtk.IconSize.MENU));
        password.caps_lock_warning = true;
        password.set_visibility (false);
        password.key_release_event.connect ( (e) => {
            if (e.keyval == Gdk.Key.Return) {
                login.clicked ();
                return true;
            } else 
                return false;
        });
        
        spinner = new Gtk.Spinner ();
        spinner.valign = Gtk.Align.START;
        spinner.set_size_request (97, 97);
        
        grid = new Gtk.Grid ();
        
        grid.attach (avatar,   0, 0, 1, 3);
        grid.attach (settings, 2, 0, 1, 1);
        grid.attach (username, 1, 0, 1, 1);
        grid.attach (password, 1, 1, 1, 1);
        grid.attach (login,    1, 2, 2, 1);
        
        grid.margin = shadow_blur + 12;
        grid.column_spacing = 12;
        
        avatar.draw.connect ( (ctx) => {
            Granite.Drawing.Utilities.cairo_rounded_rectangle (ctx, 0.5, 0.5, 
                avatar.get_allocated_width ()-1, avatar.get_allocated_height ()-1, 5);
            Gdk.cairo_set_source_pixbuf (ctx, image, 0.5, 0.5);
            ctx.fill_preserve ();
            ctx.set_line_width (1);
            ctx.set_source_rgba (0, 0, 0, 0.3);
            ctx.stroke ();
            return false;
        });
        
        /*session choose popover*/
        this.settings.toggled.connect ( () => {
            if (!settings.active)
                return;
            var pop = new PopOver ();
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            ((Gtk.Container)pop.get_content_area ()).add (box);
            
            var but = new Gtk.RadioButton.with_label (null, LightDM.
                get_sessions ().nth_data (0).name);
            box.pack_start (but, false);
            if (LightDM.get_sessions ().nth_data (0).key == current_session)
                but.active = true;
            but.toggled.connect ( () => {
                this.current_session = LightDM.get_sessions ().nth_data (0).key;
            });
            
            for (var i=1;i<LightDM.get_sessions ().length ();i++) {
                var rad = new Gtk.RadioButton.with_label_from_widget (but, 
                    LightDM.get_sessions ().nth_data (i).name);
                box.pack_start (rad, false);
                if (LightDM.get_sessions ().nth_data (i).key == current_session)
                    rad.active = true;
                var identifier = LightDM.get_sessions ().nth_data (i).key;
                rad.toggled.connect ( () => { this.current_session = identifier; });
            }
            
            this.get_stage ().add_child (pop);
            pop.x = this.x + this.width - 265;
            pop.y = this.y + 50;
            pop.get_widget ().show_all ();
            pop.destroy.connect ( () => {
                this.settings.active = false;
            });
        });
        
        /*draw the window stylish!*/
        var css = new Gtk.CssProvider ();
        try {
            css.load_from_data (LIGHT_WINDOW_STYLE, -1);
        } catch (Error e) { warning (e.message); }
        
        var draw_ref = new Gtk.Window ();
        draw_ref.get_style_context ().add_class ("content-view-window");
        draw_ref.get_style_context ().add_provider (css, Gtk.STYLE_PROVIDER_PRIORITY_FALLBACK);
        
        var w = -1; var h = -1;
        this.get_widget ().size_allocate.connect ( () => {
            if (w == this.get_widget ().get_allocated_width () && 
                h == this.get_widget ().get_allocated_height ())
                return;
            w = this.get_widget ().get_allocated_width ();
            h = this.get_widget ().get_allocated_height ();
            
            this.buffer = new Granite.Drawing.BufferSurface (w, h);
            
            this.buffer.context.rectangle (shadow_blur + shadow_x, 
                shadow_blur + shadow_y, w - shadow_blur*2 + shadow_x, h - shadow_blur*2 + shadow_y);
            this.buffer.context.set_source_rgba (0, 0, 0, shadow_alpha);
            this.buffer.context.fill ();
            this.buffer.exponential_blur (shadow_blur / 2);
            
            draw_ref.get_style_context ().render_activity (this.buffer.context, shadow_blur + shadow_x, 
                shadow_blur + shadow_y, w - shadow_blur*2 + shadow_x, h - shadow_blur*2 + shadow_y);
        });
        
        this.get_widget ().draw.connect ( (ctx) => {
            ctx.rectangle (0, 0, w, h);
            ctx.set_operator (Cairo.Operator.SOURCE);
            ctx.set_source_rgba (0, 0, 0, 0);
            ctx.fill ();
            
            ctx.set_source_surface (buffer.surface, 0, 0);
            ctx.paint ();
            
            return false;
        });
        
        ((Gtk.Container)this.get_widget ()).add (grid);
        this.get_widget ().show_all ();
        this.get_widget ().get_style_context ().add_class ("content-view");
    }
    
    public static string get_user_markup (LightDM.User user, bool title=false) {
        var color = (title)?"color='#808080'":"";
        var first_name = user.real_name.substring (0, user.real_name.index_of (" "));
        return "<span face='Open Sans Light' font='32'>"+first_name+"</span>"+
            "    <span face='Open Sans Normal' font='16' "+color+">"+user.name+"</span>";
    }
    
    public void wrong_pw () {
        this.password.text = "";
        this.animate (Clutter.AnimationMode.EASE_IN_BOUNCE, 200, scale_x:1.3f, scale_y:1.3f).
            completed.connect ( () => {
                Clutter.Threads.Timeout.add (1, () => {
                this.animate (Clutter.AnimationMode.EASE_OUT_BOUNCE, 200, scale_x:1.0f, scale_y:1.0f);
                return false;
                });
            });
    }
    
    public void set_user (LightDM.User ?user) { //guest if null
        this.password.text = "";
        if (user == null) {
            this.username.set_markup ("<span face='Open Sans Light' font='24'>"+
                "Guest session</span>");
            this.set_wallpaper (DEFAULT_WALLPAPER);
            
            this.current_user = null;
            this.current_session = greeter.default_session_hint;
            this.password.set_sensitive (false);
        } else {
            this.username.set_markup (get_user_markup (user, true));
            
            try {
                this.image = new Gdk.Pixbuf.from_file (user.image);
            } catch (Error e) { warning (e.message); }  
            this.avatar.queue_draw ();
            this.set_wallpaper (user.background);
            
            this.current_user = user;
            this.current_session = user.session;
            
            this.password.set_sensitive (true);
            this.password.grab_focus ();
        }
        
        if (LightDM.get_sessions ().length () == 1)
            settings.hide ();
    }
}


