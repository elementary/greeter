

namespace GreeterCompositor
{
    public class BackgroundContainer : Meta.BackgroundGroup
    {
        const string DEFAULT_BACKGROUND_PATH = "default";
        const Clutter.Color DEFAULT_BACKGROUND_COLOR = { 0x2e, 0x34, 0x36, 0xff };
        public Meta.Screen screen { get; construct; }

        string? current_actor_path = null;
        ulong completed_id = 0U;
        signal void destroy_background_finished ();

        static Gee.HashMap<string, Meta.BackgroundActor> actors;

        static construct
        {
            actors = new Gee.HashMap<string, Meta.BackgroundActor> ((v) => {
                return v.hash ();
            });
        }

        public static void refresh ()
        {
            var actor = actors[DEFAULT_BACKGROUND_PATH];
            if (actor != null) {
                actor.background.set_color (DEFAULT_BACKGROUND_COLOR);
            }
        }

        public BackgroundContainer (Meta.Screen screen)
        {
            Object (screen: screen);
        }

        public async void set_wallpaper (string? path)
        {
            yield wait_for_previous_transition ();

            path = path ?? DEFAULT_BACKGROUND_PATH;

            Meta.BackgroundActor? new_background_actor;
            if (path == current_actor_path) {
                return;
            }
            
            if (actors.has_key (path)) {
                new_background_actor = actors[path];
            } else {
                var new_background = new Meta.Background (screen);

                if (path == null) {
                    new_background.set_color (DEFAULT_BACKGROUND_COLOR);
                } else {
                    var texture_file = File.new_for_path (path);
                    new_background.set_file (texture_file, GDesktop.BackgroundStyle.ZOOM);
                    yield wait_for_load (texture_file);
                }

                new_background_actor = new Meta.BackgroundActor (screen, 0);
                new_background_actor.background = new_background;
            }
                
            var current_actor = actors[current_actor_path];
            if (current_actor == null) {
                add_child (new_background_actor);
            } else {
                insert_child_below (new_background_actor, current_actor);
            }

            if (current_actor != null) {
                destroy_animate_background (current_actor);
            }

            actors[path] = new_background_actor;
            current_actor_path = path;
        }

        async void wait_for_load (File file)
        {
            var cache = Meta.BackgroundImageCache.get_default ();
            var image = cache.load (file);
            if (!image.is_loaded ()) {
				ulong loaded_id = 0U;
				loaded_id = image.loaded.connect (() => {
                    image.disconnect (loaded_id);
                    Idle.add (wait_for_load.callback);
                });
                
                yield;
			}
        }

        async void wait_for_previous_transition ()
        {
            if (completed_id > 0U) {
                ulong destroy_finished_id = 0U;
                destroy_finished_id = destroy_background_finished.connect (() => {
                    disconnect (destroy_finished_id);
                    Idle.add (wait_for_previous_transition.callback);
                });

                yield;
            }
        }

        void destroy_animate_background (Clutter.Actor actor)
        {
            BlurActor.thaw_redraws ();
            completed_id = actor.transitions_completed.connect (() => {
                actor.disconnect (completed_id);
                remove_child (actor);
                actor.opacity = 255U;
                completed_id = 0U;
                destroy_background_finished ();
                BlurActor.freeze_redraws ();
            });

            actor.save_easing_state ();
            actor.set_easing_duration (300);
            actor.set_easing_mode (Clutter.AnimationMode.EASE_IN_OUT_CUBIC);
            actor.opacity = 0;
            actor.restore_easing_state ();
        }
    }
}
