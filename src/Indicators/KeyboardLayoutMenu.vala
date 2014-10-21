public class KeyboardLayoutMenu : Gtk.MenuItem {

    const string pantheon_greeter_layout_string = "pgl";

    Gtk.Label keyboard_label;

    LayoutItemNode[] layout_item_nodes = {};

    Gtk.RadioMenuItem no_other_entries_item;

    public KeyboardLayoutMenu () {

        var keyboard_hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);

        try {
            add (new Gtk.Image.from_pixbuf (Gtk.IconTheme.get_default ().lookup_by_gicon (
                                                          new GLib.ThemedIcon.with_default_fallbacks ("input-keyboard-symbolic"),
                                                          16, 0).load_symbolic ({1,1,1,1})));
        } catch (Error e) {
            warning (e.message);
        }

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
        foreach (var layout in layouts) {
            var item = new Gtk.RadioMenuItem.with_label (last_item == null ? null : last_item.get_group (), layout.description);
            last_item = item;

            if (i == 0)
                default_item = item;

            /* LightDM does not change its layout list during its lifetime, so this is safe */
            item.set_data (pantheon_greeter_layout_string, layout);

            item.toggled.connect (layout_toggled_cb);

            submenu.append (item);
            layout_item_nodes[i] = new LayoutItemNode (layout, item, false);
            i++;
        }
        no_other_entries_item = new Gtk.RadioMenuItem.with_label (null, _("No other keyboard layouts available"));
        submenu.append (no_other_entries_item);
    }

    public void user_changed_cb (LoginOption user) {

        var layouts = new List <LightDM.Layout> ();
        UserLogin user_login = user as UserLogin;
        if (user_login != null) {
            foreach (var name in user_login.lightdm_user.get_layouts ()) {
                var layout = get_layout_by_name (name);
                if (layout != null)
                    layouts.append (layout);
            }
        }
        set_layouts (layouts);
        update_layout_visibility ();
    }

    private void update_layout_visibility () {
        foreach (var n in layout_item_nodes) {
            if (n.visible) {
                n.item.show ();
            } else {
                n.item.hide ();
            }
        }
    }

    static LightDM.Layout? get_layout_by_name (string name) {
        foreach (var layout in LightDM.get_layouts ()) {
            if (layout.name == name)
                return layout;
        }
        return null;
    }

    private void set_layouts (List<LightDM.Layout> layouts)
    {
        if (layouts == null || layouts.length () == 0) {
            foreach (var n in layout_item_nodes) {
                n.visible = false;
            }
            no_other_entries_item.show ();
            return;
        }
        else {
            foreach (var n in layout_item_nodes) {
                n.visible = false;
            }
            foreach (var layout in layouts) {
                get_node_for_layout (layout).visible = true;
            }
            no_other_entries_item.hide ();
        }

        var default_layout = layouts.data;
        if (default_layout == null) {
            default_layout = layout_item_nodes[0].layout;
        }
        var default_item = get_node_for_layout (default_layout).item;

        /* Activate first item */
        if (default_item != null) {
            if (default_item.active) /* Started active, have to manually trigger callback */
                layout_toggled_cb (default_item);
            else
                default_item.active = true; /* will trigger callback to do rest of work */
        }
    }

    private LayoutItemNode? get_node_for_layout (LightDM.Layout layout) {
        foreach (var n in layout_item_nodes) {
            if (cmp_layout (layout, n.layout) == 0) {
                return n;
            }
        }
        warning ("Couldn't find a layout that matches: " + layout.name);
        return null;
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
                var parent_layout = get_layout_by_name (parts[0]);
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
        else {
            /* Use a dumb, ascii comparison for now.  If it turns out that some
               descriptions can be in unicode, we'll have to use libicu's collation
               algorithms. */
            return strcmp (a.name, b.name);
        }
    }

    class LayoutItemNode {
        public LightDM.Layout layout { get; set; }
        public Gtk.RadioMenuItem item { get; set; }
        public bool visible { get; set; }

        public LayoutItemNode (LightDM.Layout layout, Gtk.RadioMenuItem item, bool visible) {
            this.layout = layout;
            this.item = item;
            this.visible = visible;
        }
    }

}