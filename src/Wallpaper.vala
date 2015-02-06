// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2014 elementary Developers

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/

/**
 * Represents a area on the screen where the current wallpaper of a user gets
 * displayed.
 */
public class Wallpaper : Clutter.Group {
    /**
     *
     */
    List<GtkClutter.Texture> wallpapers = new List<GtkClutter.Texture> ();
    List<Cancellable> loading_wallpapers = new List<Cancellable> ();

    /**
     * Contains old Textures that were used for wallpapers. They are recycled
     * in the @make_texture method.
     */
    Queue<GtkClutter.Texture> unused_wallpapers = new Queue<GtkClutter.Texture> ();

    int gpu_limit;

    string[] cache_path = {};
    Gdk.Pixbuf[] cache_pixbuf = {};
    int max_cache = 3;

    string last_loaded = "";

    public int screen_width { get; set; }
    public int screen_height { get; set; }

    public Wallpaper () {
        GL.GLint result = 1;
        GL.glGetIntegerv(GL.GL_MAX_TEXTURE_SIZE, out result);
        gpu_limit = result;
    }

    string get_default () {
        var settings = new KeyFile();
        string default_wallpaper = "/usr/share/backgrounds/elementaryos-default";
        try{
            settings.load_from_file(Constants.CONF_DIR+"/pantheon-greeter.conf",
                    KeyFileFlags.KEEP_COMMENTS);
            default_wallpaper = settings.get_string ("greeter", "default-wallpaper");
        } catch (Error e) {
            warning (e.message);
        }
        return default_wallpaper;
    }

    public void reposition () {
        set_wallpaper (last_loaded);
    }

    public void set_wallpaper (string? path) {
        var file_path = (path == null || path == "") ? get_default () : path;

        var file = File.new_for_path (file_path);

        if (!file.query_exists ()) {
            warning ("File %s does not exist!\n", file_path);
            return;
        }

        last_loaded = file_path;

        clean_cache ();
        load_wallpaper.begin (file_path, file);
    }

    async void load_wallpaper (string path, File file) {

        try {
            Gdk.Pixbuf? buf = try_load_from_cache (path);
            //if we still dont have a wallpaper now, load from file
            if (buf == null) {
                var cancelable = new Cancellable ();
                loading_wallpapers.append (cancelable);
                InputStream stream = yield file.read_async (GLib.Priority.DEFAULT);
                buf = yield new Gdk.Pixbuf.from_stream_async (stream, cancelable);
                loading_wallpapers.remove (cancelable);
                // we downscale the pixbuf as far as we can on the CPU
                buf = validate_pixbuf (buf);
                //add loaded wallpapers and paths to cache
                cache_path += path;
                cache_pixbuf += buf;
            }
            //check if the currently loaded wallpaper is the one we loaded in this method
            if (last_loaded != path)
                return; //if not, abort

            var new_wallpaper = make_texture ();
            new_wallpaper.opacity = 0;
            new_wallpaper.set_from_pixbuf (buf);
            resize (new_wallpaper);
            add_child (new_wallpaper);
            new_wallpaper.animate (Clutter.AnimationMode.EASE_OUT_QUINT, 500, opacity: 255);

            // abort all currently loading wallpapers
            foreach (var c in loading_wallpapers) {
                c.cancel ();
            }
            foreach (var other_wallpaper in wallpapers) {
                wallpapers.remove (other_wallpaper);
                other_wallpaper.animate (Clutter.AnimationMode.EASE_IN_QUINT, 500, opacity: 0).completed.connect (() => {
                    remove_child (other_wallpaper);
                    unused_wallpapers.push_tail (other_wallpaper);
                });
            }
            wallpapers.append (new_wallpaper);

        } catch (IOError.CANCELLED e) {
            message (@"Cancelled to load '$path'");
            // do nothing, we cancelled on purpose
        } catch (Error e) {
            if (get_default() != path) {
                set_wallpaper (get_default ());
            }
            warning (@"Can't load: '$path' due to $(e.message)");
        }
    }

    /**
     * Creates a texture. It also recycles old unused wallpapers if possible
     * as spamming constructors is expensive.
     */
    GtkClutter.Texture make_texture () {
        if (unused_wallpapers.is_empty ()) {
            return new GtkClutter.Texture ();
        } else {
            return unused_wallpapers.pop_head ();
        }
    }

    /**
     * Resizes the cache if there are more pixbufs cached then max_mache allows
     */
    void clean_cache () {
        int l = cache_path.length;
        if (l > max_cache) {
            cache_path = cache_path [l - max_cache : l];
            cache_pixbuf = cache_pixbuf [l - max_cache : l];
        }
    }

    /**
     * Looks up the pixbuf of the image-file with the given path in the cache.
     * Returns null if there is no pixbuf for that file in cache
     */
    Gdk.Pixbuf? try_load_from_cache (string path) {
        for (int i = 0; i < cache_path.length; i++) {
            if (cache_path[i] == path)
                return cache_pixbuf[i];
        }
        return null;
    }

    /**
     * makes the pixbuf fit inside the GPU limit and scales it to
     * screen size to save memory.
     */
    Gdk.Pixbuf validate_pixbuf (Gdk.Pixbuf pixbuf) {
        Gdk.Pixbuf result = scale_to_rect (pixbuf, gpu_limit, gpu_limit);
        result = scale_to_rect (pixbuf, screen_width, screen_height);
        return result;
    }

    /**
     * Scales the pixbuf down to fit in the given dimensions.
     */
    Gdk.Pixbuf scale_to_rect (Gdk.Pixbuf pixbuf, int rw, int rh) {
        int h = pixbuf.height;
        int w = pixbuf.width;

        if (h > rh || w > rw) {
            float hw = (float)h/w*rw;
            float wh = (float)w/h*rh;
            if (h < w) {
                return pixbuf.scale_simple (rw, (int) (hw), Gdk.InterpType.BILINEAR);
            } else {
                return pixbuf.scale_simple ((int) (wh), rh, Gdk.InterpType.BILINEAR);
            }
        }
        return pixbuf;
    }

    void resize (GtkClutter.Texture tex) {
        int w, h;
        tex.get_base_size (out w, out h);

        if (width > (w * height) / h) {
            tex.width = width;
            tex.height = (int) (h * width / w);

            if (height > tex.height) {
                tex.height = height;
                tex.width = (int) (w * height / h);
            }
        } else {
            tex.height = height;
            tex.width = (int) (w * height / h);
        }
    }
}
