/* 
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

public class GreeterCompositor.Wallpaper : Meta.BackgroundActor {
    const Clutter.Color BLACK_COLOR = { 0, 0, 0, uint8.MAX };
    Meta.Background? wallpaper_background = null;

    public Wallpaper (Meta.Screen screen) {
        Object (meta_screen: screen, monitor: 0);
    }

    construct {
        if (wallpaper_background == null) {
            wallpaper_background = new Meta.Background (meta_screen);
            wallpaper_background.set_color (BLACK_COLOR);

            GreeterCompositor.DBus.instance.change_wallpaper.connect ((path) => {
                wallpaper_background.set_file (File.new_for_path (path), GDesktop.BackgroundStyle.WALLPAPER);
            });
        }

        background = wallpaper_background;
    }
}


