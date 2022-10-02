/*
 * Copyright 2018 elementary, Inc. (https://elementary.io)
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
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public class Greeter.SystemBackground : GLib.Object {
    const Clutter.Color DEFAULT_BACKGROUND_COLOR = { 0x2e, 0x34, 0x36, 0xff };

    static Meta.Background? system_background = null;

    public Meta.BackgroundActor background_actor { get; construct; }

    public signal void loaded ();

    public SystemBackground (Meta.Display display) {
        Object (background_actor: new Meta.BackgroundActor (display, 0));
    }

    construct {
        if (system_background == null) {
            system_background = new Meta.Background (background_actor.meta_display);
            var texture_file = GLib.File.new_for_uri ("resource:///io/elementary/desktop/gala/texture.png");
            system_background.set_color (DEFAULT_BACKGROUND_COLOR);
            system_background.set_file (texture_file, GDesktop.BackgroundStyle.WALLPAPER);
        }

#if HAS_MUTTER338
        ((Meta.BackgroundContent)background_actor.content).background = system_background;
#else
        background_actor.background = system_background;
#endif
    }

    public void refresh () {
        // Meta.Background.refresh_all does not refresh backgrounds with the WALLPAPER style.
        // (Last tested with mutter 3.28)
        // As a workaround, re-apply the current color again to force the wallpaper texture
        // to be rendered from scratch.
        if (system_background != null)
            system_background.set_color (DEFAULT_BACKGROUND_COLOR);
    }
}
