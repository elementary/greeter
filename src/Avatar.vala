
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
        animate (Clutter.AnimationMode.EASE_IN_OUT_QUAD, 400, "opacity", 255);
    }

    public void dismiss () {
        animate (Clutter.AnimationMode.EASE_IN_OUT_QUAD, 400, "opacity", 0);
    }

}
