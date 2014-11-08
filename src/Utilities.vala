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

[CCode (cname="cogl_get_modelview_matrix")]
public extern void get_modelview_matrix (out Cogl.Matrix modelview);
[CCode (cname="cogl_get_projection_matrix")]
public extern void get_projection_matrix (out Cogl.Matrix modelview);

public class MirrorEffect : Clutter.OffscreenEffect {

    public uint8 opacity = 220;
    public float length = 0.3f;

    public MirrorEffect () {

    }

    public override bool pre_paint () {
        if (!base.pre_paint ())
            return false;
        if (this.get_actor () == null)
            return false;

        return true;
    }
    public override void post_paint () {
        Cogl.pop_matrix ();
        Cogl.pop_framebuffer ();

        this.paint_target ();
    }

    public override void paint_target () {
        if (this.get_actor () == null)
            return;

        var material = this.get_target ();
        Cogl.set_source (material);

        var col_original = Cogl.Color.from_4ub (255, 255, 255, 255);
        var col_refl_top = Cogl.Color.from_4ub (opacity, opacity, opacity, opacity);
        var col_refl_bot = Cogl.Color.from_4ub (0, 0, 0, 0);

        Cogl.TextureVertex polygon[4];
        polygon[0].x = 0; polygon[0].y = 0; polygon[0].z = 0;
        polygon[0].tx = 0; polygon[0].ty = 0;
        polygon[0].color = col_original;

        polygon[1].x = this.get_actor ().width; polygon[1].y = 0; polygon[1].z = 0;
        polygon[1].tx = 1; polygon[1].ty = 0;
        polygon[1].color = col_original;

        polygon[2].x = this.get_actor ().width; polygon[2].y = this.get_actor ().height; polygon[2].z = 0;
        polygon[2].tx = 1; polygon[2].ty = 1;
        polygon[2].color = col_original;

        polygon[3].x = 0; polygon[3].y = this.get_actor ().height; polygon[3].z = 0;
        polygon[3].tx = 0; polygon[3].ty = 1;
        polygon[3].color = col_original;

        Cogl.polygon (polygon, true);

        polygon[0].x = 0; polygon[0].y = this.get_actor ().height; polygon[0].z = this.get_actor ().z_position;
        polygon[0].tx = 0; polygon[0].ty = 1;
        polygon[0].color = col_refl_top;
        polygon[1].x = this.get_actor ().width; polygon[1].y = this.get_actor ().height; polygon[1].z = this.get_actor ().z_position;
        polygon[1].tx = 1; polygon[1].ty = 1;
        polygon[1].color = col_refl_top;
        polygon[2].x = this.get_actor ().width; polygon[2].y = (1+this.length)*this.get_actor ().height; polygon[2].z = this.get_actor ().z_position;
        polygon[2].tx = 1; polygon[2].ty = (1.0f - this.length);
        polygon[2].color = col_refl_bot;
        polygon[3].x = 0; polygon[3].y = (1+this.length)*this.get_actor ().height; polygon[3].z = this.get_actor ().z_position;
        polygon[3].tx = 0; polygon[3].ty = (1.0f - this.length);
        polygon[3].color = col_refl_bot;

        Cogl.polygon (polygon, true);
    }

}

public class TextShadowEffect : Clutter.Effect {
    int _offset_y;
    public int offset_y {
        get { return _offset_y; }
        set { _offset_y = value; this.update (); }
    }

    int _offset_x;
    public int offset_x {
        get { return _offset_x; }
        set { _offset_x = value; this.update (); }
    }

    uint8 _opacity;
    public uint8 opacity {
        get { return _opacity; }
        set { _opacity = value; this.update (); }
    }

    public TextShadowEffect (int offset_x, int offset_y, uint8 opacity) {
        this._offset_x = offset_x;
        this._offset_y = offset_y;
        this._opacity  = opacity;
    }

    public override bool pre_paint () {
        var layout = ((Clutter.Text) this.get_actor ()).get_layout ();
        Cogl.pango_render_layout (layout, this.offset_x, this.offset_y,
                                  Cogl.Color.from_4ub (0, 0, 0, opacity), 0);
        return true;
    }

    public void update () {
        if (this.get_actor () != null)
            this.get_actor ().queue_redraw ();
    }
}

public class PopOver : GtkClutter.Actor {

    Granite.Drawing.BufferSurface buffer;
    Gtk.EventBox container;

    public PopOver () {
        this.container = new Gtk.EventBox ();
        this.container.visible_window = false;
        this.container.margin = 30;
        this.container.margin_top = 40;
        this.container.margin_bottom = 25;
        this.container.get_style_context ().add_class ("content-view");
        (this.get_widget () as Gtk.Container).add (this.container);

        this.reactive = true;

        var w = -1; var h = -1; var ARROW_HEIGHT = 10; var ARROW_WIDTH = 20;
        this.get_widget ().size_allocate.connect (() => {
            if (this.contents.get_allocated_width () == -1 &&
                this.contents.get_allocated_height () == -1)
                return;

            w = this.contents.get_allocated_width ();
            h = this.contents.get_allocated_height ();

            var x = 20;
            var y = 20;

            this.buffer = new Granite.Drawing.BufferSurface ((int) width, (int) height);
            Granite.Drawing.Utilities.cairo_rounded_rectangle (buffer.context, x, y+ARROW_HEIGHT,
                                                               (int) width - x * 2, (int)height - y * 2, 5);
            buffer.context.move_to ((int) (width - 45), y + ARROW_HEIGHT);
            buffer.context.rel_line_to (ARROW_WIDTH / 2.0, -ARROW_HEIGHT);
            buffer.context.rel_line_to (ARROW_WIDTH / 2.0, ARROW_HEIGHT);
            buffer.context.close_path ();

            buffer.context.set_source_rgba (0, 0, 0, 0.8);
            buffer.context.fill_preserve ();
            buffer.exponential_blur (10);

            buffer.context.set_source_rgb (1, 1, 1);
            buffer.context.fill ();
        });

        this.get_widget ().draw.connect ((ctx) => {
            ctx.rectangle (0, 0, w, h);
            ctx.set_operator (Cairo.Operator.SOURCE);
            ctx.set_source_rgba (0, 0, 0, 0);
            ctx.fill ();

            ctx.set_source_surface (buffer.surface, 0, 0);
            ctx.paint ();

            return false;
        });

        this.leave_event.connect (() => {
            this.animate (Clutter.AnimationMode.EASE_OUT_QUAD, 200, opacity:0).

            completed.connect (() => {
                this.get_stage ().remove_child (this);
                this.destroy ();
            });

            return true;
        });

        this.opacity = 0;
        this.animate (Clutter.AnimationMode.EASE_OUT_QUAD, 200, opacity:255);
    }

    public Gtk.Widget get_content_area () {
        return this.container;
    }
}