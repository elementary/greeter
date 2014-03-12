

public class SelectableAvatar : GtkClutter.Actor {
    Avatar normal_avatar;
    Avatar desaturated_avatar;

    public SelectableAvatar (LoginOption user) {
        normal_avatar = new Avatar (user);
        desaturated_avatar = new Avatar (user);
        desaturated_avatar.add_effect (new Clutter.DesaturateEffect (1.0f));
        add_child (normal_avatar);
        add_child (desaturated_avatar);
        deselect ();
    }

    public void select () {
        normal_avatar.show ();
        desaturated_avatar.dismiss ();
    }

    public void deselect () {
        normal_avatar.dismiss ();
        desaturated_avatar.show ();
    }

    public void dismiss () {
        normal_avatar.dismiss ();
        desaturated_avatar.dismiss ();
    }
}

public class Avatar : GtkClutter.Actor {

    Gdk.Pixbuf image;

    Gtk.EventBox box = new Gtk.EventBox ();

    public Avatar (LoginOption user) {

        opacity = 0;
        box.set_size_request (96, 96);
        box.valign = Gtk.Align.START;
        box.visible_window = false;

        image = user.get_avatar ();

        box.draw.connect ((ctx) => {
            ctx.set_operator (Cairo.Operator.CLEAR);
            ctx.paint ();

            ctx.set_operator (Cairo.Operator.OVER);
            Granite.Drawing.Utilities.cairo_rounded_rectangle (ctx, 0, 0,
                box.get_allocated_width (), box.get_allocated_height (), 46);
            Gdk.cairo_set_source_pixbuf (ctx, image, 0, 0);
            ctx.fill_preserve ();
            ctx.set_line_width (0);
            ctx.set_source_rgba (0, 0, 0, 0.3);
            ctx.stroke ();
            return false;
        });
        this.contents = box;
    }

    public void show () {
        animate (Clutter.AnimationMode.EASE_IN_OUT_QUAD, 400, "opacity", 255);
    }

    public void dismiss () {
        animate (Clutter.AnimationMode.EASE_IN_OUT_QUAD, 400, "opacity", 0);
    }

}
