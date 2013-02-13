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

using Clutter;
using Gdk;


public class Wallpaper : Group {
    public GtkClutter.Texture background;   //both not added to this box but to stage
    public GtkClutter.Texture background_s; //double buffered!

    bool second = false;

    string last_loaded = "";

    Cancellable? cancellable = null;

    public Wallpaper () {
        background = new GtkClutter.Texture ();
        background_s = new GtkClutter.Texture ();
        background.opacity = 230;
        background_s.opacity = 230;

        add_child (background);
        add_child (background_s);
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

        

        if(file_path == last_loaded) 
            return;
        last_loaded = file_path;

        if(cancellable != null)
            cancellable.cancel();

        var top = second ? background : background_s;
        var bot = second ? background_s : background;

        if (file_path == top.filename)
            return;

        top.detach_animation ();
        bot.detach_animation ();

        cancellable = new Cancellable();
        load_wallpaper(file_path,file,bot,top);

        second = !second;
    }

    public async void load_wallpaper (string path, File file, GtkClutter.Texture bot, 
                                        GtkClutter.Texture top) {
        try {
            InputStream stream = yield file.read_async(GLib.Priority.DEFAULT);
            Gdk.Pixbuf buf = yield Gdk.Pixbuf.new_from_stream_async(stream,cancellable);
           if(last_loaded != path)
                return;

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

    public void resize (Texture? tex = null) {
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
