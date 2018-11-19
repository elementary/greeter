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

public class Greeter.SystemBackground : Meta.BackgroundActor {
    const Clutter.Color DEFAULT_BACKGROUND_COLOR = { 0x2e, 0x34, 0x36, 0xff };

    static Meta.Background? system_background = null;

    public SystemBackground (Meta.Screen screen) {
        Object (meta_screen: screen, monitor: 0);

        background = system_background;
    }

    construct {
        if (system_background == null) {
            system_background = new Meta.Background (meta_screen);
        }

        refresh();
    }

    public static void refresh() {
        var texture_file = GLib.File.new_for_uri ("resource:///io/elementary/greeter/texture.png");
        system_background.set_color (DEFAULT_BACKGROUND_COLOR);
        system_background.set_file (texture_file, GDesktop.BackgroundStyle.WALLPAPER);
    }
}

