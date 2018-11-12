public class Greeter.UserCard : Gtk.Revealer {
    public signal void go_left ();
    public signal void go_right ();
    public signal void focus_requested ();
    public signal void do_connect (string? credential = null);

    public LightDM.User lightdm_user { get; construct; }
    public bool show_input { get; set; default = false; }
    public bool need_password { get; set; default = true; }
    public double reveal_ratio { get; private set; default = 0.0; }

    private Gtk.Revealer form_revealer;

    construct {
        width_request = 350;
        reveal_child = true;
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;

        var username_label = new Gtk.Label (lightdm_user.display_name);
        username_label.margin_bottom = 12;
        username_label.margin_top = 24;
        username_label.hexpand = true;
        username_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var password_entry = new Gtk.Entry ();
        password_entry.tooltip_text = _("Password");
        password_entry.placeholder_text = _("Password");
        password_entry.primary_icon_name = "dialog-password-symbolic";
        password_entry.secondary_icon_name = "go-jump-symbolic";
        password_entry.secondary_icon_tooltip_text = _("Log In");
        password_entry.hexpand = true;
        password_entry.visibility = false;
        password_entry.input_purpose = Gtk.InputPurpose.PASSWORD;
        var fingerprint_image = new Gtk.Image.from_icon_name ("fingerprint-symbolic", Gtk.IconSize.BUTTON);
        var session_button = new Greeter.SessionButton ();

        var password_grid = new Gtk.Grid ();
        password_grid.orientation = Gtk.Orientation.HORIZONTAL;
        password_grid.column_spacing = 6;
        password_grid.add (password_entry);
        password_grid.add (fingerprint_image);

        var login_button = new Gtk.Button.with_label (_("Log In"));
        login_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var login_stack = new Gtk.Stack ();
        login_stack.add_named (password_grid, "password");
        login_stack.add_named (login_button, "button");

        var form_grid = new Gtk.Grid ();
        form_grid.column_spacing = 6;
        form_grid.row_spacing = 12;
        form_grid.margin = 12;
        form_grid.margin_top = 0;
        form_grid.attach (login_stack, 0, 1, 1, 1);
        form_grid.attach (session_button, 1, 1, 1, 1);

        form_revealer = new Gtk.Revealer ();
        form_revealer.reveal_child = true;
        form_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        form_revealer.add (form_grid);

        var background_image = new Greeter.BackgroundImage (lightdm_user.background);

        form_revealer.bind_property ("reveal-child", background_image, "round-bottom", GLib.BindingFlags.INVERT_BOOLEAN|GLib.BindingFlags.SYNC_CREATE);
        bind_property ("show-input", form_revealer, "reveal-child", GLib.BindingFlags.SYNC_CREATE);

        var main_grid = new Gtk.Grid ();
        main_grid.margin_bottom = 48;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (background_image);
        main_grid.add (username_label);
        main_grid.add (form_revealer);

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/greeter/Card.css");

        var main_grid_style_context = main_grid.get_style_context ();
        main_grid_style_context.add_class (Granite.STYLE_CLASS_CARD);
        main_grid_style_context.add_class ("rounded");
        main_grid_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        Granite.Widgets.Avatar avatar;
        if (lightdm_user.image != null) {
            avatar = new Granite.Widgets.Avatar.from_file (lightdm_user.image, 64);
        } else {
            avatar = new Granite.Widgets.Avatar.with_default_icon (64);
        }

        avatar.valign = Gtk.Align.START;
        avatar.margin_top = 108;

        var card_overlay = new Gtk.Overlay ();
        card_overlay.margin = 12;
        card_overlay.add (main_grid);
        card_overlay.add_overlay (avatar);

        add (card_overlay);

        card_overlay.focus.connect ((direction) => {
            if (direction == Gtk.DirectionType.LEFT) {
                go_left ();
                return true;
            } else if (direction == Gtk.DirectionType.RIGHT) {
                go_right ();
                return true;
            }

            return false;
        });

        card_overlay.button_release_event.connect ((event) => {
            if (!show_input) {
                focus_requested ();
            }

            return false;
        });

        // This makes all the animations synchonous
        form_revealer.size_allocate.connect ((alloc) => {
            var total_height = form_grid.get_allocated_height () + form_grid.margin_top + form_grid.margin_bottom;
            reveal_ratio = (double)alloc.height/(double)total_height;
        });

        notify["child-revealed"].connect (() => {
            reveal_ratio = child_revealed ? 1.0 : 0.0;
        });

        password_entry.activate.connect (() => do_connect (password_entry.text));

        password_entry.icon_press.connect ((pos, event) => {
            if (pos == Gtk.EntryIconPosition.SECONDARY) {
                do_connect (password_entry.text);
            }
        });

        login_button.clicked.connect (() => do_connect ());

        notify["need-password"].connect (() => {
            if (need_password) {
                login_stack.visible_child = password_grid;
            } else {
                login_stack.visible_child = login_button;
            }
        });
    }

    public UserCard (LightDM.User lightdm_user) {
        Object (lightdm_user: lightdm_user);
    }
}
