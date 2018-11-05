public class Greeter.ManualCard : Gtk.Revealer {
    private const string STYLESHEET =
    """.rounded {
        border-radius: 4px 4px 4px 4px;
    }""";

    construct {
        width_request = 350;
        reveal_child = true;
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;

        var label = new Gtk.Label (_("Manual Login"));
        label.xalign = 0.5f;
        label.hexpand = true;
        label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var username_entry = new Gtk.Entry ();
        username_entry.hexpand = true;
        username_entry.placeholder_text = _("Username");
        username_entry.input_purpose = Gtk.InputPurpose.FREE_FORM;

        var password_entry = new Gtk.Entry ();
        password_entry.primary_icon_name = "dialog-password-symbolic";
        password_entry.placeholder_text = _("Password");
        password_entry.hexpand = true;
        password_entry.visibility = false;
        password_entry.input_purpose = Gtk.InputPurpose.PASSWORD;

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

        var main_grid = new Gtk.Grid ();
        main_grid.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        main_grid.add (form_grid);

        var css_provider = new Gtk.CssProvider ();

        try {
            css_provider.load_from_data (STYLESHEET, -1);
            main_grid.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            main_grid.get_style_context ().add_class ("rounded");
        } catch (Error e) {}

        add (main_grid);
    }
}
