/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 *                         2013 Tom Beckmann
 *                         2013 Rico Tzschichholz
 */

namespace GreeterCompositor {
    public class BackgroundContainer : Meta.BackgroundGroup {
        public signal void changed ();
        public WindowManager wm { get; construct; }

        public BackgroundContainer (WindowManager wm) {
            Object (wm: wm);
        }

        construct {
            unowned var monitor_manager = wm.get_display ().get_context ().get_backend ().get_monitor_manager ();
            monitor_manager.monitors_changed.connect (update);

            set_black_background (true);
            update ();
        }

        ~BackgroundContainer () {
            unowned var monitor_manager = wm.get_display ().get_context ().get_backend ().get_monitor_manager ();
            monitor_manager.monitors_changed.disconnect (update);
        }

        public void set_black_background (bool black) {
#if HAS_MUTTER47
            set_background_color (black ? Cogl.Color.from_string ("Black") : null);
#else
            set_background_color (black ? Clutter.Color.from_string ("Black") : null);
#endif
        }

        private void update () {
            var reference_child = (get_child_at_index (0) as BackgroundManager);
            if (reference_child != null)
                reference_child.changed.disconnect (background_changed);

            destroy_all_children ();

            for (var i = 0; i < wm.get_display ().get_n_monitors (); i++) {
                var background = new BackgroundManager (wm, i);
                background.add_effect (new BlurEffect (background, 18));

                add_child (background);

                if (i == 0) {
                    background.changed.connect (background_changed);
                }
            }
        }

        private void background_changed () {
            changed ();
        }
    }
}
