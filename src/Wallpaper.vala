/*
* Copyright (c) 2011-2016 elementary LLC. (http://launchpad.net/pantheon-greeter)
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
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
*/

public class Wallpaper : GtkClutter.Actor {
    List<Gtk.Image> wallpapers = new List<Gtk.Image> ();
    List<Cancellable> loading_wallpapers = new List<Cancellable> ();
    Queue<Gtk.Image> unused_wallpapers = new Queue<Gtk.Image> ();

    int gpu_limit;

    string[] cache_path = {};
    Gdk.Pixbuf[] cache_pixbuf = {};
    int max_cache = 3;

    string last_loaded = "";

    public Gtk.Stack stack;
    public Gdk.Pixbuf? background_pixbuf;
    public int screen_width { get; set; }
    public int screen_height { get; set; }

    public Wallpaper () {
        GL.GLint result = 1;
        GL.glGetIntegerv(GL.GL_MAX_TEXTURE_SIZE, out result);
        gpu_limit = result;
    }

    construct {
        var container_widget = (Gtk.Container)this.get_widget ();
        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        container_widget.add (stack);
    }

    string get_default () {
        var settings = new KeyFile ();
        string default_wallpaper = "/usr/share/backgrounds/elementaryos-default";
        try {
            settings.load_from_file (Constants.CONF_DIR + "/pantheon-greeter.conf", KeyFileFlags.KEEP_COMMENTS);
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
                background_pixbuf = buf;
            }
            //check if the currently loaded wallpaper is the one we loaded in this method
            if (last_loaded != path) {
                return; //if not, abort
            }

            var new_wallpaper = make_image ();
            new_wallpaper.pixbuf = buf;
            resize (new_wallpaper);
            stack.add (new_wallpaper);
            stack.show_all ();
            stack.visible_child = new_wallpaper;

            // abort all currently loading wallpapers
            foreach (var c in loading_wallpapers) {
                c.cancel ();
            }

            foreach (var other_wallpaper in wallpapers) {
                wallpapers.remove (other_wallpaper);

                Timeout.add (stack.transition_duration, () => {
                    stack.remove (other_wallpaper);
                    unused_wallpapers.push_tail (other_wallpaper);
                    return false;
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
    Gtk.Image make_image () {
        if (unused_wallpapers.is_empty ()) {
            return new Gtk.Image ();
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
        var result = scale_to_rect (pixbuf, gpu_limit, gpu_limit);
        result = scale_to_rect (pixbuf, screen_width, screen_height);
        return result;
    }

    Gdk.Pixbuf scale_to_rect (Gdk.Pixbuf pixbuf, int rect_width, int rect_height) {
        int height = pixbuf.height;
        int width = pixbuf.width;

        if (height > rect_height || width > rect_width) {
            float hw = (float)height / width * rect_width;
            float wh = (float)width / height * rect_height;
            if (height < width) {
                return pixbuf.scale_simple (rect_width, (int) (hw), Gdk.InterpType.BILINEAR);
            } else {
                return pixbuf.scale_simple ((int) (wh), rect_height, Gdk.InterpType.BILINEAR);
            }
        }
        return pixbuf;
    }

    void resize (Gtk.Image image) {
        int w, h;

        w = image.width_request;
        h = image.height_request;


        if (width > (w * height) / h) {
            image.width_request = (int) width;
            image.height_request = (int) (h * width / w);

            if (height > image.height_request) {
                image.height_request = (int) height;
                image.width_request = (int) (w * height / h);
            }
        } else {
            image.height_request = (int) height;
            image.width_request = (int) (w * height / h);
        }
    }
}
