/*
 * Copyright (c) 2011-2015 Wingpanel Developers (http://launchpad.net/wingpanel)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

public enum BackgroundState {
    LIGHT,
    DARK,
    MAXIMIZED,
    TRANSLUCENT_DARK,
    TRANSLUCENT_LIGHT
}

public class GreeterCompositor.BackgroundManager : Object {
    private const int MINIMIZE_DURATION = 200;
    private const int SNAP_DURATION = 250;
    private const int WALLPAPER_TRANSITION_DURATION = 150;
    private const int WORKSPACE_SWITCH_DURATION = 300;
    private const double ACUTANCE_THRESHOLD = 8;
    private const double STD_THRESHOLD = 45;
    private const double LUMINANCE_THRESHOLD = 180;

    public signal void state_changed (BackgroundState state, uint animation_duration);

    public int panel_height { private get; construct; }
    private static WindowManager wm;

    private Meta.Workspace? current_workspace = null;

    private BackgroundState current_state = BackgroundState.LIGHT;

    private BackgroundUtils.ColorInformation? bk_color_info = null;

    public BackgroundManager (WindowManager _wm, int panel_height) {
        wm = _wm;

        Object (panel_height: panel_height);

        connect_signals ();
        update_bk_color_info.begin ((obj, res) => {
            update_bk_color_info.end (res);
            update_current_workspace ();
        });
    }

    private void connect_signals () {
        unowned Meta.WorkspaceManager manager = wm.get_display ().get_workspace_manager ();
        manager.workspace_switched.connect (() => {
            update_current_workspace ();
        });

        wm.notify["system-background"].connect (() => {
            update_bk_color_info.begin ((obj, res) => {
                update_bk_color_info.end (res);
                check_for_state_change (WALLPAPER_TRANSITION_DURATION);
            });
        });
    }

    private void update_current_workspace () {
        unowned Meta.WorkspaceManager manager = wm.get_display ().get_workspace_manager ();
        var workspace = manager.get_active_workspace ();

        if (workspace == null) {
            warning ("Cannot get active workspace");

            return;
        }

        if (current_workspace != null) {
            current_workspace.window_added.disconnect (on_window_added);
            current_workspace.window_removed.disconnect (on_window_removed);
        }

        current_workspace = workspace;

        foreach (Meta.Window window in current_workspace.list_windows ()) {
            if (window.is_on_primary_monitor ()) {
                register_window (window);
            }
        }

        current_workspace.window_added.connect (on_window_added);
        current_workspace.window_removed.connect (on_window_removed);

        check_for_state_change (WORKSPACE_SWITCH_DURATION);
    }

    private void register_window (Meta.Window window) {
        window.notify["maximized-vertically"].connect (() => {
            check_for_state_change (SNAP_DURATION);
        });

        window.notify["minimized"].connect (() => {
            check_for_state_change (MINIMIZE_DURATION);
        });

        window.workspace_changed.connect (() => {
            check_for_state_change (WORKSPACE_SWITCH_DURATION);
        });
    }

    private void on_window_added (Meta.Window window) {
        register_window (window);

        check_for_state_change (SNAP_DURATION);
    }

    private void on_window_removed (Meta.Window window) {
        check_for_state_change (SNAP_DURATION);
    }

    public async void update_bk_color_info () {
        SourceFunc callback = update_bk_color_info.callback;

        var monitor = wm.get_display ().get_primary_monitor ();
        var monitor_geometry = wm.get_display ().get_monitor_geometry (monitor);

        BackgroundUtils.get_background_color_information.begin (wm, 0, 0, monitor_geometry.width, panel_height, (obj, res) => {
            try {
                bk_color_info = BackgroundUtils.get_background_color_information.end (res);
            } catch (Error e) {
                warning (e.message);
            } finally {
                callback ();
            }
        });

        yield;
    }

    /**
     * Check if Wingpanel's background state should change.
     *
     * The state is defined as follows:
     *  - If there's a maximized window, the state should be MAXIMIZED;
     *  - If no information about the background could be gathered, it should be TRANSLUCENT;
     *  - If there's too much contrast or sharpness, it should be TRANSLUCENT;
     *  - If the background is too bright, it should be DARK;
     *  - Else it should be LIGHT.
     */
    private void check_for_state_change (uint animation_duration) {
        bool has_maximized_window = false;

        foreach (Meta.Window window in current_workspace.list_windows ()) {
            if (window.is_on_primary_monitor ()) {
                if (!window.minimized && window.maximized_vertically) {
                    has_maximized_window = true;
                    break;
                }
            }
        }

        BackgroundState new_state;

        if (has_maximized_window) {
            new_state = BackgroundState.MAXIMIZED;
        } else if (bk_color_info == null) {
            new_state = BackgroundState.TRANSLUCENT_LIGHT;
        } else {
            var luminance_std = Math.sqrt (bk_color_info.luminance_variance);

            bool bg_is_busy = luminance_std > STD_THRESHOLD ||
                (bk_color_info.mean_luminance < LUMINANCE_THRESHOLD &&
                bk_color_info.mean_luminance + 1.645 * luminance_std > LUMINANCE_THRESHOLD ) ||
                bk_color_info.mean_acutance > ACUTANCE_THRESHOLD;

            bool bg_is_dark = bk_color_info.mean_luminance > LUMINANCE_THRESHOLD;
            bool bg_is_busy_dark = bk_color_info.mean_luminance * 1.25 > LUMINANCE_THRESHOLD;

            if (bg_is_busy && bg_is_busy_dark) {
                new_state = BackgroundState.TRANSLUCENT_DARK;
            } else if (bg_is_busy) {
                new_state = BackgroundState.TRANSLUCENT_LIGHT;
            } else if (bg_is_dark) {
                new_state = BackgroundState.DARK;
            } else {
                new_state = BackgroundState.LIGHT;
            }
        }

        if (new_state != current_state) {
            state_changed (current_state = new_state, animation_duration);
        }
    }
}
