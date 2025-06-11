/*
 * Copyright 2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authored by: Leonhard Kargl <leo.kargl@proton.me>
 */

public class GreeterCompositor.ShellWindow : PositionedWindow {
    public Clutter.Actor? actor { get { return window_actor; } }

    private Meta.WindowActor window_actor;

    public ShellWindow (Meta.Window window, Position position, Variant? position_data = null) {
        base (window, position, position_data);
    }

    construct {
        window_actor = (Meta.WindowActor) window.get_compositor_private ();

        window_actor.notify["width"].connect (update_clip);
        window_actor.notify["height"].connect (update_clip);
        window_actor.notify["translation-y"].connect (update_clip);
        notify["position"].connect (update_clip);
    }

    private void update_clip () {
        if (position != TOP && position != BOTTOM) {
            window_actor.remove_clip ();
            return;
        }

        var monitor_geom = window.display.get_monitor_geometry (window.get_monitor ());

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
