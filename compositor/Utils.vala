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
        // Cache xid:pixbuf and icon:pixbuf pairs to provide a faster way aquiring icons
        static HashTable<string, Gdk.Pixbuf> xid_pixbuf_cache;
        static HashTable<string, Gdk.Pixbuf> icon_pixbuf_cache;
        static uint cache_clear_timeout = 0;

        class construct {
            xid_pixbuf_cache = new HashTable<string, Gdk.Pixbuf> (str_hash, str_equal);
            icon_pixbuf_cache = new HashTable<string, Gdk.Pixbuf> (str_hash, str_equal);
        }

        Utils () {}

        /**
         * Clean icon caches
         */
        static void clean_icon_cache (uint32[] xids) {
            var list = xid_pixbuf_cache.get_keys ();
            var pixbuf_list = icon_pixbuf_cache.get_values ();
            var icon_list = icon_pixbuf_cache.get_keys ();

            foreach (var xid_key in list) {
                var xid = (uint32)uint64.parse (xid_key.split ("::")[0]);
                if (!(xid in xids)) {
                    var pixbuf = xid_pixbuf_cache.get (xid_key);
                    for (var j = 0; j < pixbuf_list.length (); j++) {
                        if (pixbuf_list.nth_data (j) == pixbuf) {
                            xid_pixbuf_cache.remove (icon_list.nth_data (j));
                        }
                    }

                    xid_pixbuf_cache.remove (xid_key);
                }
            }
        }

        /**
         * Marks the given xids as no longer needed, the corresponding icons
         * may be freed now. Mainly for internal purposes.
         *
         * @param xids The xids of the window that no longer need icons
         */
        public static void request_clean_icon_cache (uint32[] xids) {
            if (cache_clear_timeout > 0) {
                GLib.Source.remove (cache_clear_timeout);
            }

            cache_clear_timeout = Timeout.add_seconds (30, () => {
                cache_clear_timeout = 0;
                Idle.add (() => {
                    clean_icon_cache (xids);
                    return false;
                });
                return false;
            });
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
    }
}
