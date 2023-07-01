/*
 * Copyright 2019-2023 elementary, Inc. (https://elementary.io)
 * Copyright 2011–2013 Robert Dyer
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

/**
* A class containing an RGBA color and methods for more powerful color manipulation.
*/
public class Greeter.Color : GLib.Object {
    /**
    * The value of the red channel, with 0 being the lowest value and 1.0 being the greatest value.
    */
    public double R; // vala-lint=naming-convention

    /**
    * The value of the green channel, with 0 being the lowest value and 1.0 being the greatest value.
    */
    public double G; // vala-lint=naming-convention

    /**
    * The value of the blue channel, with 0 being the lowest value and 1.0 being the greatest value.
    */
    public double B; // vala-lint=naming-convention

    /**
    * The value of the alpha channel, with 0 being the lowest value and 1.0 being the greatest value.
    */
    public double A; // vala-lint=naming-convention

    /**
    * Extracts the alpha value from the integer value
    * serialized by {@link Gala.Greeter.Color.to_int}.
    *
    * @return the alpha channel value as a uint8 ranging from 0 - 255.
    */
    public static uint8 alpha_from_int (int color) {
        return (uint8)((color >> 24) & 0xFF);
    }

    /**
    * Extracts the red value from the integer value
    * serialized by {@link Gala.Greeter.Color.to_int}.
    *
    * @return the red channel value as a uint8 ranging from 0 - 255.
    */
    public static uint8 red_from_int (int color) {
        return (uint8)((color >> 16) & 0xFF);
    }

    /**
    * Extracts the green value from the integer value
    * serialized by {@link Gala.Greeter.Color.to_int}.
    *
    * @return the green channel value as a uint8 ranging from 0 - 255.
    */
    public static uint8 green_from_int (int color) {
        return (uint8)((color >> 8) & 0xFF);
    }

    /**
    * Extracts the blue value from the integer value
    * serialized by {@link Gala.Greeter.Color.to_int}.
    *
    * @return the blue channel value as a uint8 ranging from 0 - 255.
    */
    public static uint8 blue_from_int (int color) {
        return (uint8)(color & 0xFF);
    }

    /**
    * Constructs a new {@link Gala.Greeter.Color} with the supplied values.
    *
    * @param R the value of the red channel as a double
    * @param G the value of the green channel as a double
    * @param B the value of the blue channel as a double
    * @param A the value of the alpha channel as a double
    */
    public Color (double R, double G, double B, double A) { // vala-lint=naming-convention
        this.R = R;
        this.G = G;
        this.B = B;
        this.A = A;
    }

    /**
    * Constructs a new {@link Gala.Greeter.Color} from a {@link Gdk.RGBA}.
    *
    * @param color the {@link Gdk.RGBA}
    */
    public Color.from_rgba (Gdk.RGBA color) {
        set_from_rgba (color);
    }

    /**
    * Constructs a new {@link Gala.Greeter.Color} from a string.
    *
    * The string can be either one of:
    *
    * * A standard name (Taken from the X11 rgb.txt file).
    * * A hexadecimal value in the form “#rgb”, “#rrggbb”, “#rrrgggbbb” or ”#rrrrggggbbbb”
    * * A RGB color in the form “rgb(r,g,b)” (In this case the color will have full opacity)
    * * A RGBA color in the form “rgba(r,g,b,a)”
    *
    * For more details on formatting and how this function works see {@link Gdk.RGBA.parse}
    *
    * @param color the string specifying the color
    */
    public Color.from_string (string color) {
        Gdk.RGBA rgba = Gdk.RGBA ();
        rgba.parse (color);
        set_from_rgba (rgba);
    }

    /**
    * Constructs a new {@link Gala.Greeter.Color} from an integer.
    *
    * This constructor should be used when deserializing the previously serialized
    * color by {@link Gala.Greeter.Color.to_int}.
    *
    * For more details on what format the color integer representation has, see {@link Gala.Greeter.Color.to_int}.
    *
    * If you would like to deserialize the A, R, G and B values from the integer without
    * creating a new instance of {@link Gala.Greeter.Color}, you can use the available
    * //*_from_int// static method collection such as {@link Gala.Greeter.Color.alpha_from_int}.
    *
    * @param color the integer specyfying the color
    */
    public Color.from_int (int color) {
        R = (double)red_from_int (color) / (double)uint8.MAX;
        G = (double)green_from_int (color) / (double)uint8.MAX;
        B = (double)blue_from_int (color) / (double)uint8.MAX;
        A = (double)alpha_from_int (color) / (double)uint8.MAX;
    }

    private void set_from_rgba (Gdk.RGBA color) {
        R = color.red;
        G = color.green;
        B = color.blue;
        A = color.alpha;
    }
}
