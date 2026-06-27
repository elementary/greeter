/*
 * Copyright 2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authored by: Leonhard Kargl <leo.kargl@proton.me>
 */

public class GreeterCompositor.ExtendedBehaviorWindow : ShellWindow {
    public bool modal { get; private set; default = false; }
    public bool dim { get; private set; default = false; }

    public ExtendedBehaviorWindow (Meta.Window window) {
        Object (window: window);
    }

    public void make_modal (bool dim) {
        modal = true;
        this.dim = dim;
    }

    protected override void get_window_position (Mtk.Rectangle window_rect, out int x, out int y) {
        var monitor_rect = window.display.get_monitor_geometry (window.get_monitor ());

        x = monitor_rect.x + (monitor_rect.width - window_rect.width) / 2;
        y = monitor_rect.y + (monitor_rect.height - window_rect.height) / 2;
    }
}
