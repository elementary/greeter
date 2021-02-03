public class Greeter.BackgroundImage : Gtk.EventBox {
    private uint last_size_hash = 0;
    private Gdk.Pixbuf full_pixbuf;
    private Gdk.Pixbuf fitting_pixbuf;

    construct {
        int x, y;
        var display = Gdk.Display.get_default ();
        display.get_pointer (null, out x, out y, null);
        var monitor = display.get_monitor_at_point (x, y);
        var rect = monitor.get_geometry ();

        // NOTE: display height / 4
        height_request = rect.height / get_scale_factor () / 4;
    }

    public BackgroundImage (string? path) {
        if (path == null) {
            path = "/usr/share/backgrounds/elementaryos-default";
        }

        try {
            full_pixbuf = new Gdk.Pixbuf.from_file (path);
        } catch (GLib.Error e) {
            critical (e.message);
            critical ("Fallback to default wallpaper");

            try {
                full_pixbuf = new Gdk.Pixbuf.from_file ("/usr/share/backgrounds/elementaryos-default");
            } catch (GLib.Error e) {
                critical (e.message);
            }
        }
    }

    public override bool draw (Cairo.Context cr) {
        var scale = get_scale_factor ();
        var width = get_allocated_width () * scale;
        var height = get_allocated_height () * scale;
        var radius = 5 * scale; // Off-by-one to prevent light bleed

        var new_hash = GLib.int_hash (width) + GLib.int_hash (height);
        if (new_hash != last_size_hash) {
            last_size_hash = new_hash;
            double full_ratio = (double)full_pixbuf.height / (double)full_pixbuf.width;
            fitting_pixbuf = new Gdk.Pixbuf (full_pixbuf.colorspace, full_pixbuf.has_alpha, full_pixbuf.bits_per_sample, width, height);

            // Get a scaled pixbuf that preserves aspect ratio but is at least as big as the desired destination pixbuf
            Gdk.Pixbuf scaled_pixbuf;
            if ((int)(width * full_ratio) < height) {
                scaled_pixbuf = full_pixbuf.scale_simple ((int)(width * (1 / full_ratio)), height, Gdk.InterpType.BILINEAR);
            } else {
                scaled_pixbuf = full_pixbuf.scale_simple (width, (int)(width * full_ratio), Gdk.InterpType.BILINEAR);
            }

            // Find the offset we need to center the source pixbuf on the destination
            int y = ((height - scaled_pixbuf.height) / 2).abs ();
            int x = ((width - scaled_pixbuf.width) / 2).abs ();

            scaled_pixbuf.copy_area (x, y, width, height, fitting_pixbuf, 0, 0);
        }

        cr.save ();
        cr.scale (1.0 / scale, 1.0 / scale);
        cr.new_sub_path ();
        cr.arc (width - radius, radius, radius, -Math.PI_2, 0);
        cr.line_to (width, height);
        cr.line_to (0, height);

        cr.arc (radius, radius, radius, Math.PI, Math.PI + Math.PI_2);
        cr.close_path ();
        Gdk.cairo_set_source_pixbuf (cr, fitting_pixbuf, 0, 0);
        cr.clip ();
        cr.paint ();
        cr.restore ();
        return true;
    }
}
