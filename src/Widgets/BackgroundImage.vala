public class Greeter.BackgroundImage : Gtk.Picture {
    construct {
        height_request = 150;
    }

    public BackgroundImage.from_path (string? path) {
        if (path == null) {
            path = "/usr/share/backgrounds/elementaryos-default";
        }

        set_filename (path);
    }

    public BackgroundImage.from_color (string color) {
        var pixbuf = new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, 1, 1);

        Gdk.RGBA rgba_color = {};
        rgba_color.parse (color);

        uint32 f = 0x0;
        f += (uint) Math.round (rgba_color.red * 255);
        f <<= 8;
        f += (uint) Math.round (rgba_color.green * 255);
        f <<= 8;
        f += (uint) Math.round (rgba_color.blue * 255);
        f <<= 8;
        f += 255;

        pixbuf.fill (f);

        paintable = Gdk.Texture.for_pixbuf (pixbuf);
    }
}
