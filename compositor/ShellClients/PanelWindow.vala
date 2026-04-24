/*
 * Copyright 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authored by: Leonhard Kargl <leo.kargl@proton.me>
 */

public class GreeterCompositor.PanelWindow : ShellWindow {
    private static HashTable<Meta.Window, Meta.Strut?> window_struts = new HashTable<Meta.Window, Meta.Strut?> (null, null);

    public WindowManager wm { get; construct; }
    public Pantheon.Desktop.Anchor anchor { get; construct set; }

    private int width = -1;
    private int height = -1;

    public PanelWindow (WindowManager wm, Meta.Window window, Pantheon.Desktop.Anchor anchor) {
        Object (wm: wm, window: window, anchor: anchor);
    }

    construct {
        window.unmanaging.connect (() => {
            if (window_struts.remove (window)) {
                update_struts ();
            }
        });

        notify["anchor"].connect (position_window);

        unowned var workspace_manager = window.display.get_workspace_manager ();
        workspace_manager.workspace_added.connect (update_strut);
        workspace_manager.workspace_removed.connect (update_strut);

        window.size_changed.connect (update_strut);
        window.position_changed.connect (update_strut);
        notify["width"].connect (update_strut);
        notify["height"].connect (update_strut);

        var window_actor = (Meta.WindowActor) window.get_compositor_private ();

        window_actor.notify["width"].connect (update_clip);
        window_actor.notify["height"].connect (update_clip);
        window_actor.notify["translation-y"].connect (update_clip);
        notify["anchor"].connect (update_clip);
    }

    public Mtk.Rectangle get_custom_window_rect () {
        var window_rect = window.get_frame_rect ();

        if (width > 0) {
            window_rect.width = width;
        }

        if (height > 0) {
            window_rect.height = height;

            if (anchor == BOTTOM) {
                var geom = wm.get_display ().get_monitor_geometry (window.get_monitor ());
                window_rect.y = geom.y + geom.height - height;
            }
        }

        return window_rect;
    }

    public void set_size (int width, int height) {
        this.width = width;
        this.height = height;

        update_strut ();
    }

    private void update_strut () {
        var rect = get_custom_window_rect ();

        Meta.Strut strut = {
            rect,
            side_from_anchor (anchor)
        };

        window_struts[window] = strut;

        update_struts ();
    }

    private void update_struts () {
        var list = new SList<Meta.Strut?> ();

        foreach (var window_strut in window_struts.get_values ()) {
            list.append (window_strut);
        }

        foreach (var workspace in wm.get_display ().get_workspace_manager ().get_workspaces ()) {
            workspace.set_builtin_struts (list);
        }
    }

    private Meta.Side side_from_anchor (Pantheon.Desktop.Anchor anchor) {
        switch (anchor) {
            case BOTTOM:
                return BOTTOM;

            case LEFT:
                return LEFT;

            case RIGHT:
                return RIGHT;

            default:
                return TOP;
        }
    }

    protected override void get_window_position (Mtk.Rectangle window_rect, out int x, out int y) {
        var monitor_rect = window.display.get_monitor_geometry (window.display.get_primary_monitor ());
        switch (anchor) {
            case TOP:
                x = monitor_rect.x + (monitor_rect.width - window_rect.width) / 2;
                y = monitor_rect.y;
                break;

            case BOTTOM:
                x = monitor_rect.x + (monitor_rect.width - window_rect.width) / 2;
                y = monitor_rect.y + monitor_rect.height - window_rect.height;
                break;

            default:
                warning ("Unsupported anchor %s for PanelWindow", anchor.to_string ());
                x = 0;
                y = 0;
                break;
        }
    }

    private void update_clip () {
        var monitor_geom = window.display.get_monitor_geometry (window.get_monitor ());
        var window_actor = (Meta.WindowActor) window.get_compositor_private ();

        var y = window_actor.y + window_actor.translation_y;

        if (y + window_actor.height > monitor_geom.y + monitor_geom.height) {
            window_actor.set_clip (0, 0, window_actor.width, monitor_geom.y + monitor_geom.height - y);
        } else if (y < monitor_geom.y) {
            window_actor.set_clip (0, monitor_geom.y - y, window_actor.width, window_actor.height);
        } else {
            window_actor.remove_clip ();
        }
    }
}
