/*
 * Copyright (c) 2011-2015 Wingpanel Developers (http://launchpad.net/wingpanel)
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
 */

/*
 *   The method for calculating the background information and the classes that are
 *   related to it are copied from Gala.DBus.
 */

 namespace BackgroundUtils {
    private const double SATURATION_WEIGHT = 1.5;
    private const double WEIGHT_THRESHOLD = 1.0;

    private class DummyOffscreenEffect : Clutter.OffscreenEffect {
        public signal void done_painting ();
        public override void post_paint (Clutter.PaintNode node, Clutter.PaintContext context) {
            base.post_paint (node, context);
            Idle.add (() => {
                done_painting ();
                return false;
            });
        }
    }

    public struct ColorInformation {
        double average_red;
        double average_green;
        double average_blue;
        double mean_luminance;
        double luminance_variance;
        double mean_acutance;
    }

    public async ColorInformation get_background_color_information (GreeterCompositor.WindowManager wm,
                                                                    int reference_x, int reference_y, int reference_width, int reference_height) throws DBusError {
        var background = wm.system_background.background_actor;

        var effect = new DummyOffscreenEffect ();
        background.add_effect (effect);

        var bg_actor_width = (int)background.width;
        var bg_actor_height = (int)background.height;

        // A commit in mutter added some padding to offscreen textures, so we
        // need to avoid looking at the edges of the texture as it often has a
        // black border. The commit specifies that up to 1.75px around each side
        // could now be padding, so cut off 2px from left and top if necessary
        // (https://gitlab.gnome.org/GNOME/mutter/commit/8655bc5d8de6a969e0ca83eff8e450f62d28fbee)
        int x_start = reference_x;
        if (x_start < 2) {
            x_start = 2;
        }

        int y_start = reference_y;
        if (y_start < 2) {
            y_start = 2;
        }

        // For the same reason as above, we need to not use the bottom and right
        // 2px of the texture. However, if the caller has specified an area of
        // interest that already misses these parts, use that instead, otherwise
        // chop 2px
        int width = int.min (bg_actor_width - 2 - reference_x, reference_width);
        int height = int.min (bg_actor_height - 2 - reference_y, reference_height);

        if (x_start > bg_actor_width || y_start > bg_actor_height || width <= 0 || height <= 0) {
            throw new DBusError.INVALID_ARGS ("Invalid rectangle specified: %i, %i, %i, %i".printf (x_start, y_start, width, height));
        }

        double mean_acutance = 0, variance = 0, mean = 0, r_total = 0, g_total = 0, b_total = 0;
        ulong paint_signal_handler = 0;

        paint_signal_handler = effect.done_painting.connect (() => {
            SignalHandler.disconnect (effect, paint_signal_handler);
            background.remove_effect (effect);

            var texture = (Cogl.Texture)effect.get_texture ();
            var texture_width = texture.get_width ();
            var texture_height = texture.get_height ();

            var pixels = new uint8[texture_width * texture_height * 4];
            var pixel_lums = new double[texture_width * texture_height];

            texture.get_data (Cogl.PixelFormat.BGRA_8888_PRE, 0, pixels);

            int size = width * height;

            double mean_squares = 0;
            double pixel = 0;

            double max, min, score, delta, score_total = 0, r_total2 = 0, g_total2 = 0, b_total2 = 0;

            /*
             * code to calculate weighted average color is copied from
             * plank's lib/Drawing/DrawingService.vala average_color()
             * http://bazaar.launchpad.net/~docky-core/plank/trunk/view/head:/lib/Drawing/DrawingService.vala
             */
            for (int y = y_start; y < (y_start + height); y++) {
                for (int x = x_start; x < (x_start + width); x++) {
                    int i = (y * (int)texture_width * 4) + (x * 4);

                    uint8 b = pixels[i];
                    uint8 g = pixels[i + 1];
                    uint8 r = pixels[i + 2];

                    pixel = (0.3 * r + 0.59 * g + 0.11 * b) ;

                    pixel_lums[y * width + x] = pixel;

                    min = uint8.min (r, uint8.min (g, b));
                    max = uint8.max (r, uint8.max (g, b));

                    delta = max - min;

                    /* prefer colored pixels over shades of grey */
                    score = SATURATION_WEIGHT * (delta == 0 ? 0.0 : delta / max);

                    r_total += score * r;
                    g_total += score * g;
                    b_total += score * b;
                    score_total += score;

                    r_total += r;
                    g_total += g;
                    b_total += b;

                    mean += pixel;
                    mean_squares += pixel * pixel;
                }
            }

            for (int y = y_start + 1; y < (y_start + height) - 1; y++) {
                for (int x = x_start + 1; x < (x_start + width) - 1; x++) {
                    var acutance =
                        (pixel_lums[y * width + x] * 4) -
                        (
                            pixel_lums[y * width + x - 1] +
                            pixel_lums[y * width + x + 1] +
                            pixel_lums[(y - 1) * width + x] +
                            pixel_lums[(y + 1) * width + x]
                        );

                    mean_acutance += acutance > 0 ? acutance : -acutance;
                }
            }

            score_total /= size;
            b_total /= size;
            g_total /= size;
            r_total /= size;

            if (score_total > 0.0) {
                b_total /= score_total;
                g_total /= score_total;
                r_total /= score_total;
            }

            b_total2 /= size * uint8.MAX;
            g_total2 /= size * uint8.MAX;
            r_total2 /= size * uint8.MAX;

            /*
             * combine weighted and not weighted sum depending on the average "saturation"
             * if saturation isn't reasonable enough
             * s = 0.0 -> f = 0.0 ; s = WEIGHT_THRESHOLD -> f = 1.0
             */
            if (score_total <= WEIGHT_THRESHOLD) {
                var f = 1.0 / WEIGHT_THRESHOLD * score_total;
                var rf = 1.0 - f;

                b_total = b_total * f + b_total2 * rf;
                g_total = g_total * f + g_total2 * rf;
                r_total = r_total * f + r_total2 * rf;
            }

            /* there shouldn't be values larger then 1.0 */
            var max_val = double.max (r_total, double.max (g_total, b_total));

            if (max_val > 1.0) {
                b_total /= max_val;
                g_total /= max_val;
                r_total /= max_val;
            }

            mean /= size;
            mean_squares = mean_squares / size;

            variance = (mean_squares - (mean * mean));

            mean_acutance /= (width - 2) * (height - 2);

            get_background_color_information.callback ();
        });

        background.queue_redraw ();

        yield;

        return { r_total, g_total, b_total, mean, variance, mean_acutance };
    }

}
