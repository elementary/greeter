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

public class SelectableAvatar : GtkClutter.Actor {
    Avatar normal_avatar;
    Avatar desaturated_avatar;

    public SelectableAvatar (LoginOption user) {
        normal_avatar = new Avatar (user);
        desaturated_avatar = new Avatar (user);
        desaturated_avatar.add_effect (new Clutter.DesaturateEffect (1.0f));
        add_child (normal_avatar);
        add_child (desaturated_avatar);
        deselect ();

        if (user.logged_in) {
            var logged_in = new LoggedInIcon ();
            logged_in.x = logged_in.y = 80;
            add_child (logged_in);
        }
    }

    public void select () {
        normal_avatar.fade_in ();
        desaturated_avatar.fade_out ();
    }

    public void deselect () {
        normal_avatar.fade_out ();
        desaturated_avatar.fade_in ();
    }

    public void dismiss () {
        normal_avatar.dismiss ();
        desaturated_avatar.dismiss ();
    }
}

public class LoggedInIcon : GtkClutter.Texture {
    static Gdk.Pixbuf image = null;

    public LoggedInIcon () {
        if (image == null) {
            try {
            image = Gtk.IconTheme.get_default ().load_icon ("account-logged-in", 16, 0);
            } catch (Error e) {
                image = null;
                warning (e.message);
                return;
            }
        }

        try {
            set_from_pixbuf (image);
        } catch (Error e) {
            warning (e.message);
        }
    }
}

public class Avatar : GtkClutter.Actor {

    Gdk.Pixbuf image;

    Gtk.EventBox box = new Gtk.EventBox ();

    public Avatar (LoginOption user) {

        opacity = 0;
        box.set_size_request (96, 96);
        box.valign = Gtk.Align.START;
        box.visible_window = false;

        image = user.avatar;

        box.draw.connect ((ctx) => {
            ctx.set_operator (Cairo.Operator.CLEAR);
            ctx.paint ();

            ctx.set_operator (Cairo.Operator.OVER);
            // 48 = min (width / 2, height / 2)
            Granite.Drawing.Utilities.cairo_rounded_rectangle (ctx, 0, 0,
                box.get_allocated_width (), box.get_allocated_height (), 48);
            Gdk.cairo_set_source_pixbuf (ctx, image, 0, 0);
            ctx.fill_preserve ();
            ctx.set_line_width (0);
            ctx.set_source_rgba (0, 0, 0, 0.3);
            ctx.stroke ();
            return false;
        });
        this.contents = box;
    }

    public unowned Clutter.Animation fade_in () {
        return animate (Clutter.AnimationMode.EASE_IN_OUT_QUAD, 400, "opacity", 255);
    }

    public unowned Clutter.Animation fade_out () {
        return animate (Clutter.AnimationMode.EASE_IN_OUT_QUAD, 400, "opacity", 0);
    }

    public void dismiss () {
        fade_out ().completed.connect (() => {
            get_parent ().remove_child (this);
        });
    }

}