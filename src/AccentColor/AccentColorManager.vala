/*
 * Copyright 2021-2023 elementary, Inc. <https://elementary.io>
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Authored by: Marius Meisenzahl <mariusmeisenzahl@gmail.com>
 */

public class Greeter.AccentColorManager : Object {
    private const string INTERFACE_SCHEMA = "org.gnome.desktop.interface";
    private const string STYLESHEET_KEY = "gtk-theme";
    private const string TAG_ACCENT_COLOR = "Xmp.xmp.io.elementary.AccentColor";

    private const string THEME_BLUE = "io.elementary.stylesheet.blueberry";
    private const string THEME_MINT = "io.elementary.stylesheet.mint";
    private const string THEME_GREEN = "io.elementary.stylesheet.lime";
    private const string THEME_YELLOW = "io.elementary.stylesheet.banana";
    private const string THEME_ORANGE = "io.elementary.stylesheet.orange";
    private const string THEME_RED = "io.elementary.stylesheet.strawberry";
    private const string THEME_PINK = "io.elementary.stylesheet.bubblegum";
    private const string THEME_PURPLE = "io.elementary.stylesheet.grape";
    private const string THEME_BROWN = "io.elementary.stylesheet.cocoa";
    private const string THEME_GRAY = "io.elementary.stylesheet.slate";

    private static GLib.Settings background_settings;
    private static GLib.Settings interface_settings;
    private static NamedColor[] theme_colors;

    private static void init () {
        background_settings = new GLib.Settings ("org.gnome.desktop.background");
        interface_settings = new GLib.Settings (INTERFACE_SCHEMA);
        theme_colors = {
            new NamedColor ("Blue", THEME_BLUE, new Greeter.Color.from_int (0x3689e6)),
            new NamedColor ("Mint", THEME_MINT, new Greeter.Color.from_int (0x28bca3)),
            new NamedColor ("Green", THEME_GREEN, new Greeter.Color.from_int (0x68b723)),
            new NamedColor ("Yellow", THEME_YELLOW, new Greeter.Color.from_int (0xf9c440)),
            new NamedColor ("Orange", THEME_ORANGE, new Greeter.Color.from_int (0xffa154)),
            new NamedColor ("Red", THEME_RED, new Greeter.Color.from_int (0xed5353)),
            new NamedColor ("Pink", THEME_PINK, new Greeter.Color.from_int (0xde3e80)),
            new NamedColor ("Purple", THEME_PURPLE, new Greeter.Color.from_int (0xa56de2)),
            new NamedColor ("Brown", THEME_BROWN, new Greeter.Color.from_int (0x8a715e)),
            new NamedColor ("Gray", THEME_GRAY, new Greeter.Color.from_int (0x667885))
        };
    }

    public static void update_accent_color () {
        if (background_settings == null || interface_settings == null || theme_colors == null) {
            init ();
        }

        bool set_accent_color_based_on_primary_color = background_settings.get_enum ("picture-options") == 0;

        var current_stylesheet = interface_settings.get_string (STYLESHEET_KEY);

        debug ("Current stylesheet: %s", current_stylesheet);

        NamedColor? new_color = null;
        if (set_accent_color_based_on_primary_color) {
            var primary_color = background_settings.get_string ("primary-color");
            debug ("Current primary color: %s", primary_color);

            new_color = get_accent_color_based_on_primary_color (primary_color);
        } else {
            var picture_uri = background_settings.get_string ("picture-uri");
            debug ("Current wallpaper: %s", picture_uri);

            var accent_color_name = read_accent_color_name_from_exif (picture_uri);
            warning (picture_uri);
            if (accent_color_name != null) {
                warning ("Color from exif");
                for (int i = 0; i < theme_colors.length; i++) {
                    warning ("Color %s", theme_colors[i].name);
                    if (theme_colors[i].name == accent_color_name) {
                        warning ("Got color");
                        new_color = theme_colors[i];
                        break;
                    }
                }
            } else {
                new_color = get_accent_color_of_picture_simple (picture_uri);
            }
        }

        if (new_color != null && new_color.theme != current_stylesheet) {
            debug ("New stylesheet: %s", new_color.theme);

            interface_settings.set_string (
                STYLESHEET_KEY,
                new_color.theme
            );
        }
    }

    private static string? read_accent_color_name_from_exif (string picture_uri) {
        string path = "";
        GExiv2.Metadata metadata;
        try {
            path = Filename.from_uri (picture_uri);
            metadata = new GExiv2.Metadata ();
            metadata.open_path (path);

            return metadata.try_get_tag_string (TAG_ACCENT_COLOR);
        } catch (Error e) {
            warning ("Error parsing exif metadata of \"%s\": %s", path, e.message);
            return null;
        }
    }

    private static NamedColor? get_accent_color (ColorExtractor color_extractor) {
        var palette = new Gee.ArrayList<Greeter.Color> ();
        for (int i = 0; i < theme_colors.length; i++) {
            palette.add (theme_colors[i].color);
        }

        var index = color_extractor.get_dominant_color_index (palette);
        return theme_colors[index];
    }

    private static NamedColor? get_accent_color_of_picture_simple (string picture_uri) {
        var file = File.new_for_uri (picture_uri);

        try {
            var pixbuf = new Gdk.Pixbuf.from_file (file.get_path ());
            var color_extractor = new ColorExtractor.from_pixbuf (pixbuf);

            return get_accent_color (color_extractor);
        } catch (Error e) {
            warning (e.message);
        }

        return null;
    }

    private static NamedColor? get_accent_color_based_on_primary_color (string primary_color) {
        var granite_primary_color = new Greeter.Color.from_string (primary_color);
        var color_extractor = new ColorExtractor.from_primary_color (granite_primary_color);

        return get_accent_color (color_extractor);
    }
}
