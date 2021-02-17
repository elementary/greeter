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

public abstract class Greeter.BaseCard : Gtk.Revealer {
    public signal void do_connect (string? credential = null);

    protected static Gtk.CssProvider css_provider;

    public bool connecting { get; set; default = false; }
    public bool need_password { get; set; default = false; }
    public bool use_fingerprint { get; set; default = false; }

    static construct {
        css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/greeter/Card.css");
    }

    construct {
        int x, y;
        var display = Gdk.Display.get_default ();
        display.get_pointer (null, out x, out y, null);
        var monitor = display.get_monitor_at_point (x, y);
        var rect = monitor.get_geometry ();
        var scale = get_scale_factor ();

        // NOTE: Display width divided by 4
        width_request = rect.width / scale / 4;

        // NOTE: Display height divided by 8
        margin_bottom = rect.height / scale / 8;

        reveal_child = true;
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;

        notify["child-revealed"].connect (() => {
            if (!child_revealed) {
                visible = false;
            }
        });

        notify["reveal-child"].connect (() => {
            if (reveal_child) {
                visible = true;
            }
        });
    }

    public virtual void wrong_credentials () {
    }
}
