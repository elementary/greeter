/*
 * Copyright 2021-2023 elementary, Inc (https://elementary.io)
 *           2015 Rory J Sanderson
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class GreeterCompositor.MaskCorners : GLib.Object {
    private const int DEFAULT_CORNER_RADIUS = 6;

    private static MaskCorners instance;

    public WindowManager wm { get; construct set; }
    private int[] corner_radii;
    private List<Clutter.Actor>[] cornermasks;
    private Meta.Display display;

    public static void init (WindowManager wm) {
        if (instance == null) {
            instance = new MaskCorners (wm);
        }
    }

    private MaskCorners (WindowManager wm) {
        Object (wm: wm);
    }

    construct {
        display = wm.get_display ();
        setup_cornermasks ();
    }

    private void setup_cornermasks () {
        int n_monitors = display.get_n_monitors ();
        corner_radii = new int[n_monitors];
        cornermasks = new List<Clutter.Actor>[n_monitors];

        for (int m = 0; m < n_monitors; m++) {
            corner_radii[m] = Gala.Utils.scale_to_int (DEFAULT_CORNER_RADIUS, display.get_monitor_scale (m));
        }

        for (int m = 0; m < n_monitors; m++) {
            add_cornermasks (m);
        }

        unowned Meta.MonitorManager monitor_manager = display.get_context ().get_backend ().get_monitor_manager ();
        monitor_manager.monitors_changed.connect (resetup_cornermasks);

        display.gl_video_memory_purged.connect (resetup_cornermasks);
    }

    private void destroy_cornermasks () {
        display.gl_video_memory_purged.disconnect (resetup_cornermasks);

        unowned Meta.MonitorManager monitor_manager = display.get_context ().get_backend ().get_monitor_manager ();
        monitor_manager.monitors_changed.disconnect (resetup_cornermasks);

        foreach (unowned List<Clutter.Actor> list in cornermasks) {
            foreach (Clutter.Actor actor in list) {
                actor.destroy ();
            }
        }
    }

    private void resetup_cornermasks () {
        destroy_cornermasks ();
        setup_cornermasks ();
    }

    private void add_cornermasks (int monitor_no) {
        var monitor_geometry = display.get_monitor_geometry (monitor_no);

        var canvas = new Clutter.Canvas ();
        canvas.set_size (corner_radii[monitor_no], corner_radii[monitor_no]);
        canvas.draw.connect ((context) => draw_cornermask (context, monitor_no));
        canvas.invalidate ();

        var actor = new Clutter.Actor ();
        actor.set_content (canvas);
        actor.set_size (corner_radii[monitor_no], corner_radii[monitor_no]);
        actor.set_position (monitor_geometry.x, monitor_geometry.y);
        actor.set_pivot_point ((float) 0.5, (float) 0.5);

        cornermasks[monitor_no].append (actor);
        wm.stage.add_child (actor);

        for (int p = 1; p < 4; p++) {
            var clone = new Clutter.Clone (actor);
            clone.rotation_angle_z = p * 90;

            switch (p) {
                case 1:
                    clone.set_position (monitor_geometry.x + monitor_geometry.width, monitor_geometry.y);
                    break;
                case 2:
                    clone.set_position (monitor_geometry.x + monitor_geometry.width, monitor_geometry.y + monitor_geometry.height);
                    break;
                case 3:
                    clone.set_position (monitor_geometry.x, monitor_geometry.y + monitor_geometry.height);
                    break;
            }

            cornermasks[monitor_no].append (clone);
            wm.stage.add_child (clone);
        }
    }

    private bool draw_cornermask (Cairo.Context context, int monitor_no) requires (corner_radii.length > monitor_no) {
        var buffer = new Gala.Drawing.BufferSurface (corner_radii[monitor_no], corner_radii[monitor_no]);
        var buffer_context = buffer.context;

        buffer_context.arc (corner_radii[monitor_no], corner_radii[monitor_no], corner_radii[monitor_no], Math.PI, 1.5 * Math.PI);
        buffer_context.line_to (0, 0);
        buffer_context.line_to (0, corner_radii[monitor_no]);
        buffer_context.set_source_rgb (0, 0, 0);
        buffer_context.fill ();

        context.set_operator (Cairo.Operator.CLEAR);
        context.paint ();
        context.set_operator (Cairo.Operator.OVER);
        context.set_source_surface (buffer.surface, 0, 0);
        context.paint ();

        return true;
    }
}
