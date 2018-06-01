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

namespace GreeterCompositor
{
	public class Utils
	{
		// Cache xid:pixbuf and icon:pixbuf pairs to provide a faster way aquiring icons
		static HashTable<string, Gdk.Pixbuf> xid_pixbuf_cache;
		static HashTable<string, Gdk.Pixbuf> icon_pixbuf_cache;
		static uint cache_clear_timeout = 0;

		class construct
		{
			xid_pixbuf_cache = new HashTable<string, Gdk.Pixbuf> (str_hash, str_equal);
			icon_pixbuf_cache = new HashTable<string, Gdk.Pixbuf> (str_hash, str_equal);
		}

		Utils ()
		{
		}

		/**
		 * Clean icon caches
		 */
		static void clean_icon_cache (uint32[] xids)
		{
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
		public static void request_clean_icon_cache (uint32[] xids)
		{
			if (cache_clear_timeout > 0)
				GLib.Source.remove (cache_clear_timeout);

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
		 * Get the next window that should be active on a workspace right now. Based on
		 * stacking order
		 *
		 * @param workspace The workspace on which to find the window
		 * @param backward  Whether to get the previous one instead
		 */
		public static Meta.Window get_next_window (Meta.Workspace workspace, bool backward = false)
		{
			var screen = workspace.get_screen ();
			var display = screen.get_display ();

			var window = display.get_tab_next (Meta.TabList.NORMAL,
				workspace, null, backward);

			if (window == null)
				window = display.get_tab_current (Meta.TabList.NORMAL, workspace);

			return window;
		}

		/**
		 * Get the number of toplevel windows on a workspace excluding those that are
		 * on all workspaces
		 *
		 * @param workspace The workspace on which to count the windows
		 */
		public static uint get_n_windows (Meta.Workspace workspace)
		{
			var n = 0;
			foreach (var window in workspace.list_windows ()) {
				if (window.is_on_all_workspaces ())
					continue;
				if (window.window_type == Meta.WindowType.NORMAL ||
					window.window_type == Meta.WindowType.DIALOG ||
					window.window_type == Meta.WindowType.MODAL_DIALOG)
					n ++;
			}

			return n;
		}

		/**
		 * Creates an actor showing the current contents of the given WindowActor.
		 *
		 * @param actor      The actor from which to create a shnapshot
		 * @param inner_rect The inner (actually visible) rectangle of the window
		 * @param outer_rect The outer (input region) rectangle of the window
		 *
		 * @return           A copy of the actor at that time or %NULL
		 */
		public static Clutter.Actor? get_window_actor_snapshot (Meta.WindowActor actor, Meta.Rectangle inner_rect, Meta.Rectangle outer_rect)
		{
			var texture = actor.get_texture () as Meta.ShapedTexture;

			if (texture == null)
				return null;

			var surface = texture.get_image ({
				inner_rect.x - outer_rect.x,
				inner_rect.y - outer_rect.y,
				inner_rect.width,
				inner_rect.height
			});

			if (surface == null)
				return null;

			var canvas = new Clutter.Canvas ();
			var handler = canvas.draw.connect ((cr) => {
				cr.set_source_surface (surface, 0, 0);
				cr.paint ();
				return false;
			});
			canvas.set_size (inner_rect.width, inner_rect.height);
			SignalHandler.disconnect (canvas, handler);

			var container = new Clutter.Actor ();
			container.set_size (inner_rect.width, inner_rect.height);
			container.content = canvas;

			return container;
		}

		/**
		 * Ring the system bell, will most likely emit a <beep> error sound or, if the
		 * audible bell is disabled, flash the screen
		 *
		 * @param screen The screen to flash, if necessary
		 */
		public static void bell (Meta.Screen screen)
		{
			if (Meta.Prefs.bell_is_audible ())
				Gdk.beep ();
			else
				screen.get_display ().get_compositor ().flash_screen (screen);
		}
	}
}
