public class Greeter.ManualCard : Greeter.BaseCard {
    public signal void do_connect_username (string username);

    private Greeter.PasswordEntry password_entry;
    private Gtk.Entry username_entry;
    private Gtk.Grid main_grid;

    construct {
        width_request = 350;

        var icon = new Gtk.Image ();
        icon.icon_name = "avatar-default";
        icon.pixel_size = 64;

        var label = new Gtk.Label (_("Manual Login"));
        label.hexpand = true;
        label.margin_bottom = 16;
        label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        username_entry = new Gtk.Entry ();
        username_entry.hexpand = true;
        username_entry.placeholder_text = _("Username");
        username_entry.primary_icon_name = "avatar-default-symbolic";
        username_entry.input_purpose = Gtk.InputPurpose.FREE_FORM;
        username_entry.secondary_icon_name = "go-jump-symbolic";
        username_entry.secondary_icon_tooltip_text = _("Try username");

        password_entry = new Greeter.PasswordEntry ();
        password_entry.sensitive = false;
        password_entry.secondary_icon_name = "";

        var caps_lock_revealer = new Greeter.CapsLockRevealer ();
        var num_lock_revealer = new Greeter.NumLockRevealer ();

        var password_grid = new Gtk.Grid ();
        password_grid.row_spacing = 6;
        password_grid.orientation = Gtk.Orientation.VERTICAL;
        password_grid.add (password_entry);
        password_grid.add (caps_lock_revealer);
        password_grid.add (num_lock_revealer);

        var session_button = new Greeter.SessionButton ();

        var form_grid = new Gtk.Grid ();
        form_grid.orientation = Gtk.Orientation.VERTICAL;
        form_grid.column_spacing = 6;
        form_grid.row_spacing = 12;
        form_grid.margin = 24;
        form_grid.attach (icon, 0, 0, 2, 1);
        form_grid.attach (label, 0, 1, 2, 1);
        form_grid.attach (username_entry, 0, 2);
        form_grid.attach (password_grid, 0, 3);
        form_grid.attach (session_button, 1, 2, 1, 2);

        main_grid = new Gtk.Grid ();
        main_grid.margin = 12;
        main_grid.add (form_grid);

        var main_grid_style_context = main_grid.get_style_context ();
        main_grid_style_context.add_class (Granite.STYLE_CLASS_CARD);
        main_grid_style_context.add_class ("rounded");
        main_grid_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        add (main_grid);

        bind_property ("connecting", username_entry, "sensitive", GLib.BindingFlags.INVERT_BOOLEAN);
        bind_property ("connecting", password_entry, "sensitive", GLib.BindingFlags.INVERT_BOOLEAN);

        username_entry.activate.connect (() => do_connect_username (username_entry.text));
        password_entry.activate.connect (on_login);
        grab_focus.connect (() => {
            if (username_entry.sensitive) {
                username_entry.grab_focus_without_selecting ();
            } else {
                password_entry.grab_focus_without_selecting ();
            }
        });
    }

    private void on_login () {
        connecting = true;
        do_connect (password_entry.text);
        password_entry.text = "";
        password_entry.sensitive = false;
    }

    private void focus_username_entry () {
        password_entry.secondary_icon_name = "";
        password_entry.sensitive = false;
        username_entry.secondary_icon_name = "go-jump-symbolic";
        username_entry.sensitive = true;
        username_entry.grab_focus_without_selecting ();
    }

    private void focus_password_entry () {
        username_entry.secondary_icon_name = "";
        username_entry.sensitive = false;
        password_entry.secondary_icon_name = "go-jump-symbolic";
        password_entry.sensitive = true;
        password_entry.grab_focus_without_selecting ();
    }

    public override void wrong_credentials () {
        focus_username_entry ();
        weak Gtk.StyleContext grid_style_context = main_grid.get_style_context ();
        weak Gtk.StyleContext username_entry_style_context = username_entry.get_style_context ();
        weak Gtk.StyleContext password_entry_style_context = password_entry.get_style_context ();
        username_entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);
        password_entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);
        grid_style_context.add_class ("shake");
        GLib.Timeout.add (450, () => {
            grid_style_context.remove_class ("shake");
            username_entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);
            password_entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);
            return GLib.Source.REMOVE;
        });
    }

    public void ask_password () {
        focus_password_entry ();
    }

    public void wrong_username () {
        username_entry.grab_focus_without_selecting ();
        username_entry.secondary_icon_name = "";
        username_entry.text = "";
        weak Gtk.StyleContext grid_style_context = main_grid.get_style_context ();
        weak Gtk.StyleContext entry_style_context = username_entry.get_style_context ();
        entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);
        grid_style_context.add_class ("shake");
        GLib.Timeout.add (450, () => {
            grid_style_context.remove_class ("shake");
            entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);
            return GLib.Source.REMOVE;
        });
    }
}
