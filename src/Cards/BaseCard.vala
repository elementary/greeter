/*
 * Copyright 2018–2021 elementary, Inc. (https://elementary.io)
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

public abstract class Greeter.BaseCard : Gtk.Widget {
    public signal void do_connect (string? credential = null);

    public Gtk.Widget child {
        set {
            revealer.child = value;
        }
    }

    protected static Gtk.CssProvider css_provider;

    public bool connecting { get; set; default = false; }
    public bool need_password { get; set; default = false; }
    public bool use_fingerprint { get; set; default = false; }

    protected const int ERROR_SHAKE_DURATION = 450;

    protected Gtk.Revealer revealer;

    static construct {
        css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/greeter/Card.css");
    }

    construct {
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        // events |= Gdk.EventMask.BUTTON_RELEASE_MASK;

        revealer = new Gtk.Revealer () {
            width_request = 350,
            reveal_child = true,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };
        revealer.set_parent (this);

        revealer.notify["child-revealed"].connect (() => {
            if (!revealer.child_revealed) {
                visible = false;
            }
        });

        revealer.notify["reveal-child"].connect (() => {
            if (revealer.reveal_child) {
                visible = true;
            }
        });
    }

    public virtual void wrong_credentials () {
    }
}
