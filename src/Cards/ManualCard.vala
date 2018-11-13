public class Greeter.ManualCard : Greeter.BaseCard {
    private Greeter.PasswordEntry password_entry;
    private Gtk.Entry username_entry;
    private Gtk.Grid main_grid;

    construct {
        width_request = 350;

        var label = new Gtk.Label (_("Manual Login"));
        label.xalign = 0.5f;
        label.hexpand = true;
        label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        username_entry = new Gtk.Entry ();
        this.bind_property ("connecting", username_entry, "sensitive", GLib.BindingFlags.INVERT_BOOLEAN);
        username_entry.hexpand = true;
        username_entry.placeholder_text = _("Username");
        username_entry.input_purpose = Gtk.InputPurpose.FREE_FORM;

        password_entry = new Greeter.PasswordEntry ();
        this.bind_property ("connecting", password_entry, "sensitive", GLib.BindingFlags.INVERT_BOOLEAN);

        var session_button = new Greeter.SessionButton ();

        var form_grid = new Gtk.Grid ();
        form_grid.orientation = Gtk.Orientation.VERTICAL;
        form_grid.column_spacing = 6;
        form_grid.row_spacing = 12;
        form_grid.margin = 12;
        form_grid.attach (label, 0, 0, 2, 1);
        form_grid.attach (username_entry, 0, 1, 1, 1);
        form_grid.attach (password_entry, 0, 2, 1, 1);
        form_grid.attach (session_button, 1, 1, 1, 2);

        main_grid = new Gtk.Grid ();
        main_grid.add (form_grid);

        var main_grid_style_context = main_grid.get_style_context ();
        main_grid_style_context.add_class (Granite.STYLE_CLASS_CARD);
        main_grid_style_context.add_class ("rounded");
        main_grid_style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        add (main_grid);

        password_entry.activate.connect (on_login);
    }

    private void on_login () {
        connecting = true;
        do_connect_username (username_entry.text);
        do_connect (password_entry.text);

        password_entry.text = "";
    }

    public override void wrong_credentials () {
        weak Gtk.StyleContext style_context = main_grid.get_style_context ();
        style_context.add_class (Gtk.STYLE_CLASS_ERROR);
        style_context.add_class ("shake");
        GLib.Timeout.add (450, () => {
            style_context.remove_class ("shake");
            style_context.remove_class (Gtk.STYLE_CLASS_ERROR);
            return GLib.Source.REMOVE;
        });
    }
}
