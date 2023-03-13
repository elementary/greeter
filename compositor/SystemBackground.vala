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
 */

public class Greeter.SystemBackground : Clutter.Canvas {
    const Clutter.Color DEFAULT_BACKGROUND_COLOR = { 0x2e, 0x34, 0x36, 0xff };
    private const string DEFAULT_BACKGROUND_PATH = "/usr/share/backgrounds/elementaryos-default";
    private const string DEFAULT_GRAY_BACKGROUND = "default";
    private Gdk.Pixbuf background;
    private Clutter.Timeline timeline;

    public Meta.BackgroundActor background_actor { get; construct; }

    public signal void loaded ();

    public SystemBackground (Meta.Display display) {
        Object (background_actor: new Meta.BackgroundActor (display, 0));
    }

    construct {
        background_actor.background_color = DEFAULT_BACKGROUND_COLOR;
        background_actor.content = this;
        timeline = new Clutter.Timeline.for_actor (background_actor, 1500);
        timeline.new_frame.connect ((ms)=> {
            background_actor.opacity = (uint) ((ms * 1.7) / 10);
        });
        timeline.started.connect (()=> {
            background_actor.opacity = 255;
            re_draw ();
        });
    }

    private async void load_blured (string path, out Gdk.Pixbuf? blured) throws Error {
        blured = new Gdk.Pixbuf.from_file (path);
    }

    public async void set_wallpaper (string path) {
        if (path == null) {
            path = DEFAULT_GRAY_BACKGROUND;
        } else if (path == "") {
            path = DEFAULT_BACKGROUND_PATH;
        }
        timeline.stop ();
        if (path != DEFAULT_GRAY_BACKGROUND && GLib.FileUtils.test (path, GLib.FileTest.EXISTS)) {
            load_blured.begin (path, (obj, res)=> {
                try {
                    load_blured.end (res, out background);
                    timeline.start ();
                } catch (Error e) {
                    warning (e.message);
                }
            });
        }
    }

    private void re_draw () {
        int width, height;
        background_actor.meta_display.get_size (out width, out height);
        set_size (width, height);
        invalidate ();
    }

    public void refresh () {
        re_draw ();
    }

    public override bool draw (Cairo.Context cr, int cr_width, int cr_height) {
        Clutter.cairo_clear (cr);
        var scale = get_scale_factor ();
        var width = (int) (cr_width * scale).abs ();
        var height = (int) (cr_height * scale).abs ();
        Gdk.Pixbuf scaled_pixbuf;
        double full_ratio = (double)background.height / (double)background.width;
        if ((width * full_ratio) < height) {
            scaled_pixbuf = background.scale_simple ((int)(height * (1 / full_ratio)), height, Gdk.InterpType.BILINEAR);
        } else {
            scaled_pixbuf = background.scale_simple (width, (int)(width * full_ratio), Gdk.InterpType.BILINEAR);
        }
        int y = ((height - scaled_pixbuf.height) / 2).abs ();
        int x = ((width - scaled_pixbuf.width) / 2).abs ();
        var new_pixbuf = new Gdk.Pixbuf (background.colorspace, background.has_alpha, background.bits_per_sample, width, height);
        scaled_pixbuf.copy_area (x, y, width, height, new_pixbuf, 0, 0);
        var surface = new Gala.Drawing.BufferSurface (new_pixbuf.width, new_pixbuf.height);
        Gdk.cairo_set_source_pixbuf (surface.context, new_pixbuf, 0, 0);
        surface.context.paint ();
        surface.gaussian_blur (15);
        surface.context.paint ();
        Gdk.cairo_set_source_pixbuf (cr, surface.load_to_pixbuf (), 0, 0);
        cr.paint ();
        cr.restore ();
        return false;
    }
}
