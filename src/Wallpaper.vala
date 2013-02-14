// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2012 elementary Developers

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

public class Wallpaper : Clutter.Group {
    public GtkClutter.Texture background;   //both not added to this box but to stage
    public GtkClutter.Texture background_s; //double buffered!

    bool second = false;

    int gpu_limit;

    string[] cache_path = {};
    Gdk.Pixbuf[] cache_pixbuf = {};
    int max_cache = 3;

    string last_loaded = "";

    Cancellable? cancellable = new Cancellable();

    int screen_width;
    int screen_height;

    public Wallpaper (int _screen_width, int _screen_height) {
        screen_width = _screen_width;
        screen_height = _screen_height;
        background = new GtkClutter.Texture ();
        background_s = new GtkClutter.Texture ();
        background.opacity = 230;
        background_s.opacity = 230;

        add_child (background);
        add_child (background_s);

        GL.GLint result = 1;
        GL.glGetIntegerv(GL.GL_MAX_TEXTURE_SIZE, out result);
        gpu_limit = result;
    }

    string get_default () {
        return new GLib.Settings ("org.pantheon.desktop.greeter").get_string ("default-wallpaper");
    }

    public void set_wallpaper (string? path) {
        var file_path = (path == null || path == "") ? get_default () : path;

        var file = File.new_for_path (file_path);

        if (!file.query_exists ()) {
            warning ("File %s does not exist!\n", file_path);
            return;
        }

        //same wallpaper => abort
        if(file_path == last_loaded) 
            return;
        //mark now loading wallpaper as the last one started loading async
        last_loaded = file_path;

        var top = second ? background : background_s;
        var bot = second ? background_s : background;

        if (file_path == top.filename)
            return;

        top.detach_animation ();
        bot.detach_animation ();


        //load the actual wallpaper async
        load_wallpaper(file_path,file,bot,top);

        second = !second;
    }

    public async void load_wallpaper (string path, File file, GtkClutter.Texture bot, 
                                        GtkClutter.Texture top) {

        try {
            Gdk.Pixbuf? buf = try_load_from_cache (path);
            //if we still dont have a wallpaper now, load from file
            if (buf == null) {
                InputStream stream = yield file.read_async (GLib.Priority.DEFAULT);
                buf = yield Gdk.Pixbuf.new_from_stream_async (stream,cancellable);
                buf = validate_pixbuf (buf);
                //add loaded wallpapers and paths to cache
                cache_path += path;
                cache_pixbuf += buf;
            }
            //check if the currently loaded wallpaper is the one we loaded in this method
            if (last_loaded != path)
                return; //if not, abort

            bot.set_from_pixbuf (buf);
            resize (bot);
            bot.visible = true;
            bot.opacity = 230;
            top.animate (Clutter.AnimationMode.LINEAR, 300, opacity:0).completed.connect (() => {
                    top.visible = false;
                    set_child_above_sibling (bot, top);
            });
        } catch (Error e) { warning (e.message); }
    }

    /**
     * resizes the cache if there are more pixbufs cached then max_mache allows
     */
    public void clean_cache () {
        int l = cache_path.length;
        if (l > max_cache) {
            cache_path = cache_path [l - max_cache : l];
            cache_pixbuf = cache_pixbuf [l - max_cache : l];
        }
    }

    /**
     * Looks up the pixbuth of the image-file with the given path in the cache.
     * Returns null if there is no pixbuf for that file in cache
     */
    public Gdk.Pixbuf? try_load_from_cache (string path) {
        for (int i = 0; i < cache_path.length; i++) {
            if (cache_path[i] == path)
                return cache_pixbuf[i];
        }
        return null;
    }

    /**
     * makes the pixbuf fit inside the GPU limit
     */
    public Gdk.Pixbuf validate_pixbuf (Gdk.Pixbuf pixbuf) {
        Gdk.Pixbuf result = scale_to_rect (pixbuf, gpu_limit, gpu_limit);
        result = scale_to_rect (pixbuf, screen_width, screen_height);
        return result;
    }

    /**
     * Scales the Pixbuf down to fit in the given dimensions
     */
    public Gdk.Pixbuf scale_to_rect (Gdk.Pixbuf pixbuf, int rw, int rh) {
        int h = pixbuf.height;
        int w = pixbuf.width;
        
        if (h > rh || w > rw) {
            float hw = (float)h/w*rw;
            float wh = (float)w/h*rh;
            if (h < w) {
                return pixbuf.scale_simple (rw, (int)(hw), Gdk.InterpType.NEAREST);
            } else {
                return pixbuf.scale_simple ((int)(wh), rh, Gdk.InterpType.NEAREST);
            } 
        }
        return pixbuf;
    }

    public void resize (GtkClutter.Texture? tex = null) {
        if (tex == null)
            tex = second ? background : background_s;

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
