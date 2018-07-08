/* 
 * Copyright 2012-2014 Tom Beckmann, Rico Tzschichholz
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

using Meta;

namespace GreeterCompositor {
    [DBus (name = "org.freedesktop.login1.Manager")]
    public interface LoginDRemote : GLib.Object {
        public signal void prepare_for_sleep (bool suspending);
    }

    public class WindowManager : Meta.Plugin {
        const uint GL_VENDOR = 0x1F00;
        const string LOGIND_DBUS_NAME = "org.freedesktop.login1";
        const string LOGIND_DBUS_OBJECT_PATH = "/org/freedesktop/login1";

        delegate unowned string? GlQueryFunc (uint id);

        static bool is_nvidia () {
            var gl_get_string = (GlQueryFunc) Cogl.get_proc_address ("glGetString");
            if (gl_get_string == null)
                return false;

            unowned string? vendor = gl_get_string (GL_VENDOR);
            return (vendor != null && vendor.contains ("NVIDIA Corporation"));
        }

        /**
         * {@inheritDoc}
         */
        public Clutter.Actor ui_group { get; protected set; }

        /**
         * {@inheritDoc}
         */
        public Clutter.Stage stage { get; protected set; }

        /**
         * {@inheritDoc}
         */
        public Clutter.Actor window_group { get; protected set; }

        /**
         * {@inheritDoc}
         */
        public Clutter.Actor top_window_group { get; protected set; }

        /**
         * {@inheritDoc}
         */
        public Meta.BackgroundGroup background_group { get; protected set; }

        Meta.PluginInfo info;

        //WindowSwitcher? winswitcher = null;
        //ActivatableComponent? workspace_view = null;
        //ActivatableComponent? window_overview = null;

        //ScreenSaver? screensaver;

        Window? moving; //place for the window that is being moved over

        LoginDRemote? logind_proxy = null;

        //Gee.LinkedList<ModalProxy> modal_stack = new Gee.LinkedList<ModalProxy> ();

        Gee.HashSet<Meta.WindowActor> minimizing = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> maximizing = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> unmaximizing = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> mapping = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> destroying = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> unminimizing = new Gee.HashSet<Meta.WindowActor> ();
        GLib.HashTable<Meta.Window, int> ws_assoc = new GLib.HashTable<Meta.Window, int> (direct_hash, direct_equal);

        public WindowManager () {
            info = Meta.PluginInfo () {name = "GreeterCompositor", version = Constants.VERSION, author = "elementary LLC.",
                license = "GPLv3", description = "The greeter compositor"};

            Prefs.set_ignore_request_hide_titlebar (true);
        }

        public override void start () {
            Util.later_add (LaterType.BEFORE_REDRAW, show_stage);

            // Handle FBO issue with nvidia blob
            if (logind_proxy == null
                && is_nvidia ()) {
                try {
                    logind_proxy = Bus.get_proxy_sync (BusType.SYSTEM, LOGIND_DBUS_NAME, LOGIND_DBUS_OBJECT_PATH);
                    logind_proxy.prepare_for_sleep.connect (prepare_for_sleep);
                } catch (Error e) {
                    warning ("Failed to get LoginD proxy: %s", e.message);
                }
            }
        }

        void prepare_for_sleep (bool suspending) {
            if (suspending)
                return;

            Meta.Background.refresh_all ();
        }

        bool show_stage () {
            var screen = get_screen ();
            MediaFeedback.init ();
            DBus.init (this);
            DBusAccelerator.init (this);

            stage = Compositor.get_stage_for_screen (screen) as Clutter.Stage;

            var wallpaper = new Wallpaper (screen);
            wallpaper.add_constraint (new Clutter.BindConstraint (stage,
                Clutter.BindCoordinate.ALL, 0));
            stage.insert_child_below (wallpaper, null);

            ui_group = new Clutter.Actor ();
            ui_group.reactive = true;
            stage.add_child (ui_group);

            window_group = Compositor.get_window_group_for_screen (screen);
            stage.remove_child (window_group);
            ui_group.add_child (window_group);

            top_window_group = Compositor.get_top_window_group_for_screen (screen);
            stage.remove_child (top_window_group);
            ui_group.add_child (top_window_group);

            /*keybindings*/

            KeyBinding.set_custom_handler ("switch-to-workspace-first", () => {});
            KeyBinding.set_custom_handler ("switch-to-workspace-last", () => {});
            KeyBinding.set_custom_handler ("move-to-workspace-first", () => {});
            KeyBinding.set_custom_handler ("move-to-workspace-last", () => {});
            KeyBinding.set_custom_handler ("cycle-workspaces-next", () => {});
            KeyBinding.set_custom_handler ("cycle-workspaces-previous", () => {});

            KeyBinding.set_custom_handler ("panel-main-menu", () => {});
            KeyBinding.set_custom_handler ("toggle-recording", () => {});

            KeyBinding.set_custom_handler ("switch-to-workspace-up", () => {});
            KeyBinding.set_custom_handler ("switch-to-workspace-down", () => {});
            KeyBinding.set_custom_handler ("switch-to-workspace-left", () => {});
            KeyBinding.set_custom_handler ("switch-to-workspace-right", () => {});

            KeyBinding.set_custom_handler ("move-to-workspace-up", () => {});
            KeyBinding.set_custom_handler ("move-to-workspace-down", () => {});
            KeyBinding.set_custom_handler ("move-to-workspace-left", () => {});
            KeyBinding.set_custom_handler ("move-to-workspace-right", () => {});

            KeyBinding.set_custom_handler ("switch-group", () => {});
            KeyBinding.set_custom_handler ("switch-group-backward", () => {});

            KeyBinding.set_custom_handler ("show-desktop", () => {});

            stage.show ();

            // let the session manager move to the next phase
            Meta.register_with_session ();

            return false;
        }

        public uint32[] get_all_xids () {
            var list = new Gee.ArrayList<uint32> ();

            foreach (var workspace in get_screen ().get_workspaces ()) {
                foreach (var window in workspace.list_windows ())
                    list.add ((uint32)window.get_xwindow ());
            }

            return list.to_array ();
        }

        /**
         * {@inheritDoc}
         */
        public void move_window (Window? window, MotionDirection direction) {
            if (window == null)
                return;

            var screen = get_screen ();
            var display = screen.get_display ();

            var active = screen.get_active_workspace ();
            var next = active.get_neighbor (direction);

            //dont allow empty workspaces to be created by moving, if we have dynamic workspaces
            if (Prefs.get_dynamic_workspaces () && Utils.get_n_windows (active) == 1 && next.index () ==  screen.n_workspaces - 1) {
                Utils.bell (screen);
                return;
            }

            moving = window;

            if (!window.is_on_all_workspaces ())
                window.change_workspace (next);

            next.activate_with_focus (window, display.get_current_time ());
        }

        public void get_current_cursor_position (out int x, out int y) {
            Gdk.Display.get_default ().get_device_manager ().get_client_pointer ().get_position (null, out x, out y);
        }

        public override void show_window_menu_for_rect (Meta.Window window, Meta.WindowMenuType menu, Meta.Rectangle rect) {
            show_window_menu (window, menu, rect.x, rect.y);
        }

        /*
         * effects
         */

        void handle_fullscreen_window (Meta.Window window, Meta.SizeChange which_change) {
            // Only handle windows which are located on the primary monitor
            if (!window.is_on_primary_monitor ())
                return;

            // Due to how this is implemented, by relying on the functionality
            // offered by the dynamic workspace handler, let's just bail out
            // if that's not available.
            if (!Prefs.get_dynamic_workspaces ())
                return;

            unowned Meta.Screen screen = get_screen ();
            var time = screen.get_display ().get_current_time ();
            unowned Meta.Workspace win_ws = window.get_workspace ();

            if (which_change == Meta.SizeChange.FULLSCREEN) {
                // Do nothing if the current workspace would be empty
                if (Utils.get_n_windows (win_ws) <= 1)
                    return;

                var old_ws_index = win_ws.index ();
                var new_ws_index = old_ws_index + 1;
                //InternalUtils.insert_workspace_with_window (new_ws_index, window);

                var new_ws_obj = screen.get_workspace_by_index (new_ws_index);
                window.change_workspace (new_ws_obj);
                new_ws_obj.activate_with_focus (window, time);

                ws_assoc.insert (window, old_ws_index);
            } else if (ws_assoc.contains (window)) {
                var old_ws_index = ws_assoc.get (window);
                var new_ws_index = win_ws.index ();

                if (new_ws_index != old_ws_index && old_ws_index < screen.get_n_workspaces ()) {
                    var old_ws_obj = screen.get_workspace_by_index (old_ws_index);
                    window.change_workspace (old_ws_obj);
                    old_ws_obj.activate_with_focus (window, time);
                }

                ws_assoc.remove (window);
            }
        }

        public override void size_change (Meta.WindowActor actor, Meta.SizeChange which_change, Meta.Rectangle old_frame_rect, Meta.Rectangle old_buffer_rect) {
            unowned Meta.Window window = actor.get_meta_window ();
            if (window.get_tile_match () != null) {
                size_change_completed (actor);
                return;
            }

            ulong signal_id = 0U;
            signal_id = window.size_changed.connect (() => {
                window.disconnect (signal_id);

                switch (which_change) {
                    case Meta.SizeChange.MAXIMIZE:
                        break;
                    case Meta.SizeChange.FULLSCREEN:
                    case Meta.SizeChange.UNFULLSCREEN:
                        handle_fullscreen_window (actor.get_meta_window (), which_change);
                        break;
                }

                size_change_completed (actor);
            });
        }

        public override void minimize (WindowActor actor) {
        }

        public override void unminimize (WindowActor actor) {
            actor.show ();
            unminimize_completed (actor);
            return;
        }

        public override void map (WindowActor actor) {
            actor.show ();
            map_completed (actor);
            return;
        }

        public override void destroy (WindowActor actor) {
            destroy_completed (actor);
            Utils.request_clean_icon_cache (get_all_xids ());

            return;
        }

        // Cancel attached animation of an actor and reset it
        bool end_animation (ref Gee.HashSet<Meta.WindowActor> list, WindowActor actor) {
            if (!list.contains (actor))
                return false;

            if (actor.is_destroyed ()) {
                list.remove (actor);
                return false;
            }

            actor.remove_all_transitions ();
            actor.opacity = 255U;
            actor.set_scale (1.0f, 1.0f);
            actor.rotation_angle_x = 0.0f;
            actor.set_pivot_point (0.0f, 0.0f);

            list.remove (actor);
            return true;
        }

        public override void kill_window_effects (WindowActor actor) {
            if (end_animation (ref mapping, actor)) {
                map_completed (actor);
            }

            if (end_animation (ref unminimizing, actor)) {
                unminimize_completed (actor);
            }

            if (end_animation (ref minimizing, actor)) {
                minimize_completed (actor);
            }

            if (end_animation (ref destroying, actor)) {
                destroy_completed (actor);
            }

            end_animation (ref unmaximizing, actor);
            end_animation (ref maximizing, actor);
        }

        /*workspace switcher*/
        List<Clutter.Actor>? windows;
        List<Clutter.Actor>? parents;
        List<Clutter.Actor>? tmp_actors;

        public override void switch_workspace (int from, int to, MotionDirection direction) {
            switch_workspace_completed ();
            return;
        }

        void end_switch_workspace () {
            if (windows == null || parents == null)
                return;

            var screen = get_screen ();
            var active_workspace = screen.get_active_workspace ();

            for (var i = 0; i < windows.length (); i++) {
                var actor = windows.nth_data (i);
                actor.set_translation (0.0f, 0.0f, 0.0f);

                if (actor is Meta.BackgroundGroup) {
                    actor.x = 0;
                    // thankfully mutter will take care of stacking it at the right place for us
                    clutter_actor_reparent (actor, window_group);
                    continue;
                }

                var window = actor as WindowActor;

                if (window == null || !window.is_destroyed ())
                    clutter_actor_reparent (actor, parents.nth_data (i));

                if (window == null || window.is_destroyed ())
                    continue;

                kill_window_effects (window);

                var meta_window = window.get_meta_window ();
                if (meta_window.get_workspace () != active_workspace
                    && !meta_window.is_on_all_workspaces ())
                    window.hide ();

                // some static windows may have been faded out
                if (actor.opacity < 255U) {
                    actor.save_easing_state ();
                    actor.set_easing_duration (300);
                    actor.opacity = 255U;
                    actor.restore_easing_state ();
                }
            }

            if (tmp_actors != null) {
                foreach (var actor in tmp_actors) {
                    actor.destroy ();
                }

                tmp_actors = null;
            }

            windows = null;
            parents = null;
            moving = null;

            switch_workspace_completed ();
        }

        public override void kill_switch_workspace () {
            end_switch_workspace ();
        }

        public override void confirm_display_change () {
            var pid = Util.show_dialog ("--question",
                _("Does the display look OK?"),
                "30",
                null,
                _("Keep This Configuration"),
                _("Restore Previous Configuration"),
                "preferences-desktop-display",
                0,
                null, null);

            ChildWatch.add (pid, (pid, status) => {
                var ok = false;
                try {
                    ok = Process.check_exit_status (status);
                } catch (Error e) {}

                complete_display_change (ok);
            });
        }

        public override unowned Meta.PluginInfo? plugin_info () {
            return info;
        }

        static void clutter_actor_reparent (Clutter.Actor actor, Clutter.Actor new_parent) {
            if (actor == new_parent)
                return;

            actor.ref ();
            actor.get_parent ().remove_child (actor);
            new_parent.add_child (actor);
            actor.unref ();
        }
    }

    [CCode (cname="clutter_x11_get_stage_window")]
    public extern X.Window x_get_stage_window (Clutter.Actor stage);
}
