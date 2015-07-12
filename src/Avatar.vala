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

    const int PADDING = 10;

    public Avatar (LoginOption user) {
        image = user.avatar;

        opacity = 0;
        box.valign = Gtk.Align.START;
        box.visible_window = false;

        if (image != null)
            box.set_size_request (image.width + PADDING, image.height + PADDING);

        string CSS = """
        .avatar {
            border-radius: 50%;
            border: 1px solid rgba(0, 0, 0, 0.25);
            box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.05),
                        inset 0 1px 0 0 rgba(255, 255, 255, 0.45),
                        inset 0 -1px 0 0 rgba(255, 255, 255, 0.15),
                        0 1px 3px rgba(0, 0, 0, 0.12),
                        0 1px 2px rgba(0,0, 0, 0.24);
        }
        """;

        Granite.Widgets.Utils.set_theming (box, CSS, "avatar", Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        box.draw.connect ((ctx) => {
/*
            ctx.set_operator (Cairo.Operator.CLEAR);
            ctx.paint ();
            ctx.set_operator (Cairo.Operator.OVER);
*/          

            int width = box.get_allocated_width ();
            int height = box.get_allocated_height ();
            
            //var val = Value (typeof (int));
            var style_context = box.get_style_context ();
            //style_context.get_style_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, val);

            int offset = PADDING / 2;

            style_context.render_background (ctx, offset - 1, offset - 1, width - PADDING + 2, height - PADDING + 2);
            style_context.render_frame (ctx, offset - 1, offset - 1, width - PADDING + 2, height - PADDING + 2);
            style_context.render_icon (ctx, image, offset, offset);

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
