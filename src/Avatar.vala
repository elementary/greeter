


public class Avatar : GtkClutter.Actor {

    Gdk.Pixbuf image;

    Gtk.EventBox box = new Gtk.EventBox ();

    public Avatar (PantheonUser user) {

        box.set_size_request (92, 92);
        box.valign = Gtk.Align.START;
        box.visible_window = false;

        image = user.get_avatar ();
        user.avatar_updated.connect (() => {
            image = user.get_avatar ();
            box.queue_draw ();
        });

        box.draw.connect ((ctx) => {
            Granite.Drawing.Utilities.cairo_rounded_rectangle (ctx, 0, 0,
                box.get_allocated_width (), box.get_allocated_height (), 46);
            Gdk.cairo_set_source_pixbuf (ctx, image, 0, 0);
            ctx.fill_preserve ();
            ctx.set_line_width (1);
            ctx.set_source_rgba (0, 0, 0, 0.3);
            ctx.stroke ();
            return false;
        });

        this.contents = box;

    }

}
