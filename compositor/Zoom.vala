/*
 * Copyright 2022 elementary, Inc. (https://elementary.io)
 * Copyright 2013 Tom Beckmann
 * Copyright 2013 Rico Tzschichholz
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class GreeterCompositor.Zoom : Object {
    private const float MIN_ZOOM = 1.0f;
    private const float MAX_ZOOM = 10.0f;
    private const float SHORTCUT_DELTA = 0.5f;
    private const int ANIMATION_DURATION = 300;
    private const uint MOUSE_POLL_TIME = 50;

    public WindowManager wm { get; construct; }

    private uint mouse_poll_timer = 0;
    private float current_zoom = MIN_ZOOM;
    private ulong wins_handler_id = 0UL;

    public Zoom (WindowManager wm) {
        Object (wm: wm);

        unowned var display = wm.get_display ();
        var schema = new GLib.Settings ("io.elementary.greeter-compositor.keybindings");

        display.add_keybinding ("zoom-in", schema, Meta.KeyBindingFlags.NONE, (Meta.KeyHandlerFunc) zoom_in);
        display.add_keybinding ("zoom-out", schema, Meta.KeyBindingFlags.NONE, (Meta.KeyHandlerFunc) zoom_out);
    }

    ~Zoom () {
        if (wm == null) {
            return;
        }

        unowned var display = wm.get_display ();
        display.remove_keybinding ("zoom-in");
        display.remove_keybinding ("zoom-out");

        if (mouse_poll_timer > 0) {
            Source.remove (mouse_poll_timer);
            mouse_poll_timer = 0;
        }
    }

    [CCode (instance_pos = -1)]
    private void zoom_in (Meta.Display display, Meta.Window? window,
        Clutter.KeyEvent event, Meta.KeyBinding binding) {
        zoom (SHORTCUT_DELTA, true, true);
    }

    [CCode (instance_pos = -1)]
    private void zoom_out (Meta.Display display, Meta.Window? window,
        Clutter.KeyEvent event, Meta.KeyBinding binding) {
        zoom (-SHORTCUT_DELTA, true, true);
    }

    private inline Graphene.Point compute_new_pivot_point () {
        unowned var wins = wm.ui_group;
        Graphene.Point coords;
#if HAS_MUTTER48
        unowned var tracker = wm.get_display ().get_compositor ().get_backend ().get_cursor_tracker ();
#else
        unowned var tracker = wm.get_display ().get_cursor_tracker ();
#endif
        tracker.get_pointer (out coords, null);
        var new_pivot = Graphene.Point () {
            x = coords.x / wins.width,
            y = coords.y / wins.height
        };

        return new_pivot;
    }

    private void zoom (float delta, bool play_sound, bool animate) {
        // Nothing to do if zooming out of our bounds is requested
        if ((current_zoom <= MIN_ZOOM && delta < 0) || (current_zoom >= MAX_ZOOM && delta >= 0)) {
            if (play_sound) {
                Gdk.beep ();
            }
            return;
        }

        unowned var wins = wm.ui_group;
        // Add timer to poll current mouse position to reposition window-group
        // to show requested zoomed area
        if (mouse_poll_timer == 0) {
            wins.pivot_point = compute_new_pivot_point ();

            mouse_poll_timer = Timeout.add (MOUSE_POLL_TIME, () => {
                var new_pivot = compute_new_pivot_point ();
                if (wins.pivot_point.equal (new_pivot)) {
                    return true;
                }

                wins.save_easing_state ();
                wins.set_easing_mode (Clutter.AnimationMode.LINEAR);
                wins.set_easing_duration (MOUSE_POLL_TIME);
                wins.pivot_point = new_pivot;
                wins.restore_easing_state ();
                return true;
            });
        }

        current_zoom += delta;
        var animation_duration = animate ? ANIMATION_DURATION : 0;

        if (wins_handler_id > 0) {
            wins.disconnect (wins_handler_id);
            wins_handler_id = 0;
        }

        if (current_zoom <= MIN_ZOOM) {
            current_zoom = MIN_ZOOM;

            if (mouse_poll_timer > 0) {
                Source.remove (mouse_poll_timer);
                mouse_poll_timer = 0;
            }

            wins.save_easing_state ();
            wins.set_easing_mode (Clutter.AnimationMode.EASE_OUT_CUBIC);
            wins.set_easing_duration (animation_duration);
            wins.set_scale (MIN_ZOOM, MIN_ZOOM);
            wins.restore_easing_state ();

            if (animate) {
                wins_handler_id = wins.transitions_completed.connect (() => {
                    wins.disconnect (wins_handler_id);
                    wins_handler_id = 0;
                    wins.set_pivot_point (0.0f, 0.0f);
                });
            } else {
                wins.set_pivot_point (0.0f, 0.0f);
            }

            return;
        }

        wins.save_easing_state ();
        wins.set_easing_mode (Clutter.AnimationMode.EASE_OUT_CUBIC);
        wins.set_easing_duration (animation_duration);
        wins.set_scale (current_zoom, current_zoom);
        wins.restore_easing_state ();
    }
}
