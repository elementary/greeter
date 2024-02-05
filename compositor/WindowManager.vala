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

    public class WindowManager : Meta.Plugin {

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

        public PointerLocator pointer_locator { get; private set; }

        public Greeter.SystemBackground system_background { get; private set; }

        Meta.PluginInfo info;

        // Used to toggle screenreader
        private GLib.Settings application_settings;
        private int reader_pid = 0;

        //WindowSwitcher? winswitcher = null;
        //ActivatableComponent? workspace_view = null;
        //ActivatableComponent? window_overview = null;

        //ScreenSaver? screensaver;

        //Gee.LinkedList<ModalProxy> modal_stack = new Gee.LinkedList<ModalProxy> ();

        Gee.HashSet<Meta.WindowActor> minimizing = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> maximizing = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> unmaximizing = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> mapping = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> destroying = new Gee.HashSet<Meta.WindowActor> ();
        Gee.HashSet<Meta.WindowActor> unminimizing = new Gee.HashSet<Meta.WindowActor> ();
        GLib.HashTable<Meta.Window, int> ws_assoc = new GLib.HashTable<Meta.Window, int> (direct_hash, direct_equal);

        construct {
            info = Meta.PluginInfo () {name = "GreeterCompositor", version = Constants.VERSION, author = "elementary LLC.",
                license = "GPLv3", description = "The greeter compositor"};
        }

        public override void start () {
            show_stage ();

            unowned var background_actor = system_background.background_actor;
            background_actor.opacity = 0;
            background_actor.save_easing_state ();
            background_actor.set_easing_duration (1000);
            background_actor.set_easing_mode (Clutter.AnimationMode.EASE);
            background_actor.opacity = 255;
            background_actor.restore_easing_state ();

            ui_group.opacity = 0;
            ui_group.save_easing_state ();
            ui_group.set_easing_duration (1000);
            ui_group.set_easing_mode (Clutter.AnimationMode.EASE);
            ui_group.opacity = 255;
            ui_group.restore_easing_state ();

            unowned Meta.Display display = get_display ();
            display.gl_video_memory_purged.connect (() => {
                refresh_background ();
            });
        }

        void refresh_background () {
            unowned Meta.Display display = get_display ();

            stage.remove_child (system_background.background_actor);
            system_background = new Greeter.SystemBackground (display);
            system_background.background_actor.add_constraint (new Clutter.BindConstraint (stage,
                Clutter.BindCoordinate.ALL, 0));
            stage.insert_child_below (system_background.background_actor, null);

            system_background.refresh ();
        }

        void show_stage () {
            unowned Meta.Display display = get_display ();
            MediaFeedback.init ();
            DBus.init (this);
            DBusAccelerator.init (this);
            DBusBackgroundManager.init (this);
            KeyboardManager.init (display);

            stage = display.get_stage () as Clutter.Stage;

            system_background = new Greeter.SystemBackground (display);
            system_background.background_actor.add_constraint (new Clutter.BindConstraint (stage,
                Clutter.BindCoordinate.ALL, 0));
            stage.insert_child_below (system_background.background_actor, null);

            ui_group = new Clutter.Actor ();
            ui_group.reactive = true;
            stage.add_child (ui_group);

            window_group = display.get_window_group ();
            stage.remove_child (window_group);
            ui_group.add_child (window_group);

            top_window_group = display.get_top_window_group ();
            stage.remove_child (top_window_group);
            ui_group.add_child (top_window_group);

            pointer_locator = new PointerLocator (this);
            ui_group.add_child (pointer_locator);

            MaskCorners.init (this);

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

            /* orca (screenreader) doesn't listen to it's
               org.gnome.desktop.a11y.applications screen-reader-enabled key
               so we handle it ourselves
               (the same thing is done in a11y indicator as well)
             */
            application_settings = new GLib.Settings ("org.gnome.desktop.a11y.applications");
            toggle_screen_reader (); // sync screen reader with gsettings key
            application_settings.changed["screen-reader-enabled"].connect (toggle_screen_reader);

            stage.show ();

            Idle.add (() => {
                // let the session manager move to the next phase
                display.get_context ().notify_ready ();
                return GLib.Source.REMOVE;
            });
        }

        public uint32[] get_all_xids () {
            var list = new Gee.ArrayList<uint32> ();

            unowned Meta.Display display = get_display ();
            unowned Meta.WorkspaceManager manager = display.get_workspace_manager ();
            for (int i = 0; i < manager.get_n_workspaces (); i++) {
                foreach (var window in manager.get_workspace_by_index (i).list_windows ()) {
                    list.add ((uint32)window.get_xwindow ());
                }
            }

            return list.to_array ();
        }

        private void toggle_screen_reader () {
            if (reader_pid == 0 && application_settings.get_boolean ("screen-reader-enabled")) {
                try {
                    string[] argv;
                    Shell.parse_argv ("orca --replace", out argv);
                    Process.spawn_async (null, argv, null, SpawnFlags.SEARCH_PATH, null, out reader_pid);
                } catch (Error e) {
                    warning (e.message);
                }
            } else if (reader_pid != 0 && !application_settings.get_boolean ("screen-reader-enabled")) {
                Posix.kill (reader_pid, Posix.Signal.QUIT);
                Posix.waitpid (reader_pid, null, 0);
                reader_pid = 0;
            }
        }

#if HAS_MUTTER45
        public override void show_window_menu_for_rect (Meta.Window window, Meta.WindowMenuType menu, Mtk.Rectangle rect) {
#else
        public override void show_window_menu_for_rect (Meta.Window window, Meta.WindowMenuType menu, Meta.Rectangle rect) {
#endif
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

            unowned Meta.Display display = get_display ();
            var time = display.get_current_time ();
            unowned Meta.Workspace win_ws = window.get_workspace ();
            unowned Meta.WorkspaceManager manager = display.get_workspace_manager ();

            if (which_change == Meta.SizeChange.FULLSCREEN) {
                // Do nothing if the current workspace would be empty
                if (Utils.get_n_windows (win_ws) <= 1)
                    return;

                var old_ws_index = win_ws.index ();
                var new_ws_index = old_ws_index + 1;
                //InternalUtils.insert_workspace_with_window (new_ws_index, window);

                var new_ws_obj = manager.get_workspace_by_index (new_ws_index);
                window.change_workspace (new_ws_obj);
                new_ws_obj.activate_with_focus (window, time);

                ws_assoc.insert (window, old_ws_index);
            } else if (ws_assoc.contains (window)) {
                var old_ws_index = ws_assoc.get (window);
                var new_ws_index = win_ws.index ();

                if (new_ws_index != old_ws_index && old_ws_index < manager.get_n_workspaces ()) {
                    var old_ws_obj = manager.get_workspace_by_index (old_ws_index);
                    window.change_workspace (old_ws_obj);
                    old_ws_obj.activate_with_focus (window, time);
                }

                ws_assoc.remove (window);
            }
        }

#if HAS_MUTTER45
        public override void size_change (Meta.WindowActor actor, Meta.SizeChange which_change, Mtk.Rectangle old_frame_rect, Mtk.Rectangle old_buffer_rect) {
#else
        public override void size_change (Meta.WindowActor actor, Meta.SizeChange which_change, Meta.Rectangle old_frame_rect, Meta.Rectangle old_buffer_rect) {
#endif
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
                    case Meta.SizeChange.UNMAXIMIZE:
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

        public override void switch_workspace (int from, int to, MotionDirection direction) {
            switch_workspace_completed ();
            return;
        }

        public override void locate_pointer () {
            pointer_locator.show_ripple ();
        }

        public override void confirm_display_change () {
#if HAS_MUTTER44
            unowned var monitor_manager = get_display ().get_context ().get_backend ().get_monitor_manager ();
            var timeout = monitor_manager.get_display_configuration_timeout ();
#else
            var timeout = Meta.MonitorManager.get_display_configuration_timeout ();
#endif
            var summary = ngettext (
                "Changes will automatically revert after %i second.",
                "Changes will automatically revert after %i seconds.",
                timeout
            );
            uint dialog_timeout_id = 0;

            var dialog = new AccessDialog (
                _("Keep new display settings?"),
                summary.printf (timeout),
                "preferences-desktop-display"
            ) {
                accept_label = _("Keep Settings"),
                deny_label = _("Use Previous Settings")
            };

            dialog.show.connect (() => {
                dialog_timeout_id = Timeout.add_seconds (timeout, () => {
                    dialog_timeout_id = 0;

                    return Source.REMOVE;
                });
            });

            dialog.response.connect ((res) => {
                if (dialog_timeout_id != 0) {
                    Source.remove (dialog_timeout_id);
                    dialog_timeout_id = 0;
                }

                complete_display_change (res == 0);
            });

            dialog.show ();
        }

        public override unowned Meta.PluginInfo? plugin_info () {
            return info;
        }
    }
}
