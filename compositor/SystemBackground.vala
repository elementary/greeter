/*
 * Copyright 2018 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 *          TorikulHabib <torik.habib@gmail.io>
 */

public class Greeter.SystemBackground : Clutter.Canvas {
    private const string DEFAULT_BACKGROUND_PATH = "/usr/share/backgrounds/elementaryos-default";
    private const string DEFAULT_GRAY_BACKGROUND = "default";
    private unowned Meta.Display display;
    private Gdk.Pixbuf input_pixbuf;
    private Gdk.Pixbuf background;
    private Gdk.Pixbuf set_background;

    public SystemBackground (Meta.Plugin plugin) {
        display = plugin.get_display ();
        var stage = display.get_stage () as Clutter.Stage;
        stage.content = this;
    }

    public void refresh () {
        re_draw ();
    }

    private Gdk.Pixbuf load_file (string input) {
        Gdk.Pixbuf pixbuf = null;
        try {
            pixbuf = new Gdk.Pixbuf.from_file (input);
        } catch (Error e) {
            GLib.warning (e.message);
        }
        return pixbuf;
    }

    public async void set_wallpaper (string path) {
        if (path == null) {
            path = DEFAULT_GRAY_BACKGROUND;
        } else if (path == "") {
            path = DEFAULT_BACKGROUND_PATH;
        }

        var texture_file = File.new_for_path (path);
        if (path != DEFAULT_GRAY_BACKGROUND && texture_file.query_exists ()) {
            input_pixbuf = load_file (path);
        } else {
            input_pixbuf = null;
        }
        re_draw ();
    }

    private void re_draw () {
        int width, height;
        display.get_size (out width, out height);
        set_size (width, height);
        invalidate ();
    }

    public override bool draw (Cairo.Context cr, int cr_width, int cr_height) {
        var scale = get_scale_factor ();
        var width = (int) (cr_width * scale);
        var height = (int) (cr_height * scale);

        if (input_pixbuf == null) {
            //Gray Color
            cr.set_source_rgba (0.19, 0.21, 0.22, 1);
            cr.rectangle (0, 0, width, height);
            cr.fill ();
            return true;
        }

        if (background != input_pixbuf) {
            background = input_pixbuf;
            Gdk.Pixbuf scaled_pixbuf;
            double full_ratio = (double)background.height / (double)background.width;
            if ((width * full_ratio) < height) {
                scaled_pixbuf = background.scale_simple ((int)(width * (1 / full_ratio)), height, Gdk.InterpType.BILINEAR);
            } else {
                scaled_pixbuf = background.scale_simple (width, (int)(width * full_ratio), Gdk.InterpType.BILINEAR);
            }

            int y = ((height - scaled_pixbuf.height) / 2).abs ();
            int x = ((width - scaled_pixbuf.width) / 2).abs ();

            Gdk.Pixbuf new_pixbuf = new Gdk.Pixbuf (background.colorspace, background.has_alpha, background.bits_per_sample, width, height);
            scaled_pixbuf.copy_area (x, y, width, height, new_pixbuf, 0, 0);

            var surface = new Granite.Drawing.BufferSurface (new_pixbuf.width, new_pixbuf.height);
            Gdk.cairo_set_source_pixbuf (surface.context, new_pixbuf, 0, 0);
            surface.context.paint ();
            surface.exponential_blur (20);
            surface.context.paint ();
            set_background = Gdk.pixbuf_get_from_surface (surface.surface, 0, 0, new_pixbuf.width, new_pixbuf.height);
        }

        Gdk.cairo_set_source_pixbuf (cr, set_background, 0, 0);
        cr.paint ();
        cr.restore ();
        return true;
    }
}
