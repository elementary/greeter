/*
 * Copyright 2012 Tom Beckmann, Rico Tzschichholz
 * Copyright 2018 elementary LLC. (https://elementary.io)
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

namespace GreeterCompositor {
    public class Utils {
        static HashTable<string, Gdk.Pixbuf> icon_pixbuf_cache;

        class construct {
            icon_pixbuf_cache = new HashTable<string, Gdk.Pixbuf> (str_hash, str_equal);
        }

        /**
         * Get the number of toplevel windows on a workspace excluding those that are
         * on all workspaces
         *
         * @param workspace The workspace on which to count the windows
         */
        public static uint get_n_windows (Meta.Workspace workspace) {
            var n = 0;
            foreach (var window in workspace.list_windows ()) {
                if (window.is_on_all_workspaces ()) {
                    continue;
                }
                if (window.window_type == Meta.WindowType.NORMAL ||
                  window.window_type == Meta.WindowType.DIALOG ||
                  window.window_type == Meta.WindowType.MODAL_DIALOG) {
                      n ++;
                  }
            }
            return n;
        }

        /**
         * Multiplies an integer by a floating scaling factor, and then
         * returns the result rounded to the nearest integer
         */
        public static int scale_to_int (int value, float scale_factor) {
            return (int) (Math.round ((float)value * scale_factor));
        }

        private static Gtk.StyleContext selection_style_context = null;
        public static Gdk.RGBA get_theme_accent_color () {
            if (selection_style_context == null) {
                var label_widget_path = new Gtk.WidgetPath ();
                label_widget_path.append_type (GLib.Type.from_name ("label"));
                label_widget_path.iter_set_object_name (-1, "selection");

                selection_style_context = new Gtk.StyleContext ();
                selection_style_context.set_path (label_widget_path);
            }

            return (Gdk.RGBA) selection_style_context.get_property (
                Gtk.STYLE_PROPERTY_BACKGROUND_COLOR,
                Gtk.StateFlags.NORMAL
            );
        }
    }
}
