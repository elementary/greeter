public class KeyboardLayoutMenu : Gtk.MenuItem {

    const string pantheon_greeter_layout_string = "pgl";

    Gtk.Label keyboard_label;

    LayoutItemNode[] layout_item_nodes = {};

    public KeyboardLayoutMenu () {

        var keyboard_hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);

        keyboard_hbox.add ( new Gtk.Image.from_icon_name ("keyboard", Gtk.IconSize.LARGE_TOOLBAR));
        keyboard_label = new Gtk.Label ("");
        keyboard_label.set_use_markup (true);
        keyboard_label.width_chars = 2;
        keyboard_hbox.add (keyboard_label);

        add (keyboard_hbox);
        create_menu ();
    }

    private void create_menu () {
        var submenu = new Gtk.Menu ();
        set_submenu (submenu as Gtk.Widget);

        var layouts = LightDM.get_layouts ().copy ();
        layouts.sort (cmp_layout);

        layout_item_nodes.resize ((int) layouts.length ());

        int i = 0;

        Gtk.RadioMenuItem? default_item = null;
        Gtk.RadioMenuItem? last_item = null;
        foreach (var layout in layouts)
        {
            var item = new Gtk.RadioMenuItem.with_label (last_item == null ? null : last_item.get_group (), layout.description);
            last_item = item;

            if (i == 0)
                default_item = item;

            /* LightDM does not change its layout list during its lifetime, so this is safe */
            item.set_data (pantheon_greeter_layout_string, layout);

            item.toggled.connect (layout_toggled_cb);

            submenu.append (item);
            layout_item_nodes[i] = {layout, item};
            i++;
        }
    }

    public void user_changed_cb (LoginOption user) {

        var layouts = new List <LightDM.Layout> ();
        if (!user.is_guest () && !user.is_manual ()) {
            foreach (var name in user.get_lightdm_user ().get_layouts ())
            {
                var layout = PantheonGreeter.get_layout_by_name (name);
                if (layout != null)
                    layouts.append (layout);
            }
        }
        set_layouts (layouts);
    }

    private void set_layouts (List<LightDM.Layout> layouts)
    {
        if (layouts == null || layouts.length () == 0) {
            foreach (var n in layout_item_nodes) {
                n.item.visible = false;
            }
            return;
        }
        else {
            foreach (var n in layout_item_nodes) {
                n.item.visible = false;
            }
            foreach (var layout in layouts) {
                get_item_for_layout (layout).visible = true;
            }
        }

        var default_layout = layouts.data;
        if (default_layout == null) {
            default_layout = layout_item_nodes[0].layout;
        }
        var default_item = get_item_for_layout (default_layout);

        /* Activate first item */
        if (default_item != null)
        {
            if (default_item.active) /* Started active, have to manually trigger callback */
                layout_toggled_cb (default_item);
            else
                default_item.active = true; /* will trigger callback to do rest of work */
        }
    }

    private Gtk.RadioMenuItem get_item_for_layout (LightDM.Layout layout) {
        foreach (var n in layout_item_nodes) {
            if (layout == n.layout) {
                return n.item;
            }
        }
        error ("blub");
    }

    private void layout_toggled_cb (Gtk.CheckMenuItem item) {
        if (!item.active)
            return;

        var layout = item.get_data<LightDM.Layout> (pantheon_greeter_layout_string);
        if (layout == null)
            return;

        var desc = layout.short_description;
        if (desc == null || desc == "") {
            var parts = layout.name.split ("\t", 2);
            if (parts[0] == layout.name) {
                desc = layout.name;
            } else {
                /* Lookup parent layout, get its short_description */
                var parent_layout = PantheonGreeter.get_layout_by_name (parts[0]);
                if (parent_layout.short_description == null ||
                    parent_layout.short_description == "") {
                    desc = parts[0];
                } else {
                    desc = parent_layout.short_description;
                }
            }
        }
        keyboard_label.label = "<span foreground=\"white\">"+desc+"</span>";

        LightDM.set_layout (layout);
    }

    private static int cmp_layout (LightDM.Layout? a, LightDM.Layout? b)
    {
        if (a == null && b == null)
            return 0;
        else if (a == null)
            return 1;
        else if (b == null)
            return -1;
        else
        {
            /* Use a dumb, ascii comparison for now.  If it turns out that some
               descriptions can be in unicode, we'll have to use libicu's collation
               algorithms. */
            return strcmp (a.description, b.description);
        }
    }

    struct LayoutItemNode {
        LightDM.Layout layout;
        Gtk.RadioMenuItem item;
    }

}