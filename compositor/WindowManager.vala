/*
 * Copyright 2012-2014 Tom Beckmann, Rico Tzschichholz
 * Copyright 2018-2025 elementary, Inc. (https://elementary.io)
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
        public Clutter.Actor ui_group { get; protected set; }
        public Clutter.Stage stage { get; protected set; }
        public Clutter.Actor window_group { get; protected set; }
        public Clutter.Actor top_window_group { get; protected set; }

        /**
         * The background group is a container for the background actors forming the wallpaper
         */
        public Meta.BackgroundGroup background_group { get; protected set; }

        public PointerLocator pointer_locator { get; private set; }

        public GreeterCompositor.SystemBackground system_background { get; private set; }

        private Clutter.Actor fade_in_screen;

#if !HAS_MUTTER48
        private Meta.PluginInfo info;
#endif

        // Used to toggle screenreader
        private GLib.Settings application_settings;
        private int reader_pid = 0;

        private Zoom zoom;

        construct {
#if !HAS_MUTTER48
            info = Meta.PluginInfo () {name = "GreeterCompositor", version = Constants.VERSION, author = "elementary LLC.",
                license = "GPLv3", description = "The greeter compositor"};
#endif
        }

        public override void start () {
            show_stage ();

            disable_tiling_shortcuts ();

            fade_in_screen.save_easing_state ();
            fade_in_screen.set_easing_duration (1000);
            fade_in_screen.set_easing_mode (Clutter.AnimationMode.EASE);
            fade_in_screen.opacity = 0;
            fade_in_screen.restore_easing_state ();

            unowned Meta.Display display = get_display ();
            display.gl_video_memory_purged.connect (() => {
                refresh_background ();
            });
        }

        private void disable_tiling_shortcuts () {
            var mutter_settings = new GLib.Settings ("org.gnome.mutter.keybindings");
            mutter_settings.set_strv ("toggle-tiled-left", {});
            mutter_settings.set_strv ("toggle-tiled-right", {});

            var wm_settings = new GLib.Settings ("org.gnome.desktop.wm.keybindings");
            wm_settings.set_strv ("minimize", {});
            wm_settings.set_strv ("toggle-maximized", {});
        }

        void refresh_background () {
            unowned Meta.Display display = get_display ();

            stage.remove_child (system_background.background_actor);
            system_background = new SystemBackground (display);
            system_background.background_actor.add_constraint (new Clutter.BindConstraint (stage,
                Clutter.BindCoordinate.ALL, 0));
            stage.insert_child_below (system_background.background_actor, null);
        }

        void show_stage () {
            unowned Meta.Display display = get_display ();
            MediaFeedback.init ();
            DBus.init (this);
            DBusAccelerator.init (this);
            DBusWingpanelManager.init (this);
            KeyboardManager.init (display);

#if HAS_MUTTER48
            stage = display.get_compositor ().get_stage () as Clutter.Stage;
#else
            stage = display.get_stage () as Clutter.Stage;
#endif
#if HAS_MUTTER47
            stage.background_color = Cogl.Color.from_string ("black");
#else
            stage.background_color = Clutter.Color.from_rgba (0, 0, 0, 255);
#endif

            system_background = new SystemBackground (display);
            system_background.background_actor.add_constraint (new Clutter.BindConstraint (stage,
                Clutter.BindCoordinate.ALL, 0));
            stage.insert_child_below (system_background.background_actor, null);

            ui_group = new Clutter.Actor ();
            ui_group.reactive = true;
            update_ui_group_size ();
            stage.add_child (ui_group);

            int width, height;
            display.get_size (out width, out height);
            fade_in_screen = new Clutter.Actor () {
                width = width,
                height = height,
#if HAS_MUTTER47
                background_color = Cogl.Color.from_string ("black")
#else
                background_color = Clutter.Color.from_rgba (0, 0, 0, 255),
#endif
            };
            stage.add_child (fade_in_screen);

#if HAS_MUTTER48
            window_group = display.get_compositor ().get_window_group ();
#else
            window_group = display.get_window_group ();
#endif
            stage.remove_child (window_group);
            ui_group.add_child (window_group);

#if HAS_MUTTER48
            top_window_group = display.get_compositor ().get_top_window_group ();
#else
            top_window_group = display.get_top_window_group ();
#endif
            stage.remove_child (top_window_group);
            ui_group.add_child (top_window_group);

            background_group = new BackgroundContainer (this);
            window_group.add_child (background_group);
            window_group.set_child_below_sibling (background_group, null);

            pointer_locator = new PointerLocator (this);
            ui_group.add_child (pointer_locator);

            unowned var monitor_manager = display.get_context ().get_backend ().get_monitor_manager ();
            monitor_manager.monitors_changed.connect (update_ui_group_size);

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

            zoom = new Zoom (this);

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
                ShellClientsManager.init (this);

                if (GLib.Environment.get_variable ("DESKTOP_SESSION") != "installer") {
                    start_command.begin ({ "io.elementary.greeter-session-manager" });
                    start_command.begin ({ "io.elementary.greeter" });
                    start_command.begin ({ "io.elementary.settings-daemon" });
                }

                return GLib.Source.REMOVE;
            });
        }

        private void update_ui_group_size () {
            unowned var display = get_display ();

            int max_width = 0;
            int max_height = 0;

            var num_monitors = display.get_n_monitors ();
            for (int i = 0; i < num_monitors; i++) {
                var geom = display.get_monitor_geometry (i);
                var total_width = geom.x + geom.width;
                var total_height = geom.y + geom.height;

                max_width = (max_width > total_width) ? max_width : total_width;
                max_height = (max_height > total_height) ? max_height : total_height;
            }

            ui_group.set_size (max_width, max_height);
        }

        private async void start_command (string[] command) {
            if (Meta.Util.is_wayland_compositor ()) {
                yield start_wayland (command);
            } else {
                yield start_x (command);
            }
        }

        private async void start_wayland (string[] command) {
            unowned Meta.Display display = get_display ();
            var subprocess_launcher = new GLib.SubprocessLauncher (GLib.SubprocessFlags.INHERIT_FDS);
            try {
                Meta.WaylandClient daemon_client;
                daemon_client = new Meta.WaylandClient (display.get_context (), subprocess_launcher);
                var subprocess = daemon_client.spawnv (display, command);

                yield subprocess.wait_async ();

                //Restart the daemon if it crashes
                Timeout.add_seconds (1, () => {
                    start_wayland.begin (command);
                    return Source.REMOVE;
                });
            } catch (Error e) {
                warning ("Failed to create greeter client: %s", e.message);
                return;
            }
        }

        private async void start_x (string[] command) {
            try {
                var subprocess = new Subprocess.newv (command, GLib.SubprocessFlags.INHERIT_FDS);
                yield subprocess.wait_async ();

                //Restart the daemon if it crashes
                Timeout.add_seconds (1, () => {
                    start_x.begin (command);
                    return Source.REMOVE;
                });
            } catch (Error e) {
                warning ("Failed to create greeter subprocess with x: %s", e.message);
            }
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

        public override void show_window_menu_for_rect (Meta.Window window, Meta.WindowMenuType menu, Mtk.Rectangle rect) {
            show_window_menu (window, menu, rect.x, rect.y);
        }

        public override void size_change (Meta.WindowActor actor, Meta.SizeChange which_change, Mtk.Rectangle old_frame_rect, Mtk.Rectangle old_buffer_rect) {
            size_change_completed (actor);
        }

        public override void minimize (WindowActor actor) {
            actor.hide ();
            minimize_completed (actor);
        }

        public override void unminimize (WindowActor actor) {
            actor.show ();
            unminimize_completed (actor);
        }

        public override void map (WindowActor actor) {
            actor.show ();
            map_completed (actor);
        }

        public override void destroy (WindowActor actor) {
            destroy_completed (actor);
        }

        public override void kill_window_effects (WindowActor actor) {}

        public override void switch_workspace (int from, int to, MotionDirection direction) {
            switch_workspace_completed ();
        }

        public override void locate_pointer () {
            pointer_locator.show_ripple ();
        }

        public override void confirm_display_change () {
            unowned var monitor_manager = get_display ().get_context ().get_backend ().get_monitor_manager ();
            var timeout = monitor_manager.get_display_configuration_timeout ();
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

#if !HAS_MUTTER48
        public override unowned Meta.PluginInfo? plugin_info () {
            return info;
        }
#endif
    }
}
