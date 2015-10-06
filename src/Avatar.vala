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
            image = Gtk.IconTheme.get_default ().load_icon ("selection-checked", 24, 0);
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
    const int MARGIN = 12;

    public Avatar (LoginOption user) {
        image = user.avatar;

        opacity = 0;
        box.valign = Gtk.Align.START;
        box.visible_window = false;

        if (image != null)
            box.set_size_request (image.width + 2 * MARGIN, image.height + 2 * MARGIN);

        box.get_style_context ().add_class ("avatar");

        box.draw.connect ((ctx) => {
            int width = box.get_allocated_width () - MARGIN * 2;
            int height = box.get_allocated_height () - MARGIN * 2;

            var style_context = box.get_style_context ();
            var border_radius = style_context.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS,
                                                            Gtk.StateFlags.NORMAL);
            Granite.Drawing.Utilities.cairo_rounded_rectangle (ctx, MARGIN, MARGIN, width,
                                                               height, (int) border_radius);
            Gdk.cairo_set_source_pixbuf (ctx, image, MARGIN, MARGIN);
            ctx.fill_preserve ();
            style_context.render_background (ctx, MARGIN, MARGIN, width, height);
            style_context.render_frame (ctx, MARGIN, MARGIN, width, height);

            return false;
        });

        this.contents = box;
    }

    public void fade_in () {
        save_easing_state ();
        set_easing_mode (Clutter.AnimationMode.EASE_IN_OUT_QUAD);
        set_easing_duration (400);
        set_opacity (255);
        restore_easing_state ();

    }

    public void fade_out () {
        save_easing_state ();
        set_easing_mode (Clutter.AnimationMode.EASE_IN_OUT_QUAD);
        set_easing_duration (400);
        set_opacity (0);
        restore_easing_state ();
    }

    public void dismiss () {
        fade_out ();
        ulong sid = 0;
        sid = transitions_completed.connect (() => {
            get_parent ().remove_child (this);
            disconnect (sid);
        });
    }

}
