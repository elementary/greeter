public class Greeter.ManualCard : Greeter.BaseCard {
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

        password_entry = new Greeter.PasswordEntry ();

        var session_button = new Greeter.SessionButton ();

        var caps_lock_revealer = new Greeter.CapsLockRevealer ();

        var form_grid = new Gtk.Grid ();
        form_grid.orientation = Gtk.Orientation.VERTICAL;
        form_grid.column_spacing = 6;
        form_grid.row_spacing = 12;
        form_grid.margin = 24;
        form_grid.attach (icon, 0, 0, 2, 1);
        form_grid.attach (label, 0, 1, 2, 1);
        form_grid.attach (username_entry, 0, 2);
        form_grid.attach (password_entry, 0, 3);
        form_grid.attach (session_button, 1, 2, 1, 2);
        form_grid.attach (caps_lock_revealer, 0, 4, 2, 1);

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

        password_entry.activate.connect (on_login);
    }

    private void on_login () {
        connecting = true;
        do_connect_username (username_entry.text);
        do_connect (password_entry.text);

        password_entry.text = "";
    }

    public override void wrong_credentials () {
        weak Gtk.StyleContext grid_style_context = main_grid.get_style_context ();
        weak Gtk.StyleContext entry_style_context = password_entry.get_style_context ();
        entry_style_context.add_class (Gtk.STYLE_CLASS_ERROR);
        grid_style_context.add_class ("shake");
        GLib.Timeout.add (450, () => {
            grid_style_context.remove_class ("shake");
            entry_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);
            return GLib.Source.REMOVE;
        });
    }
}
