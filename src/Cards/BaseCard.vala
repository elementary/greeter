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

public abstract class Greeter.BaseCard : Gtk.Box {
    public signal void do_connect (string? credential = null);

    public bool connecting { get; set; default = false; }
    public bool need_password { get; set; default = false; }
    public bool use_fingerprint { get; set; default = false; }

    protected const int ERROR_SHAKE_DURATION = 450;

    public new Gtk.Widget child {
        set {
            revealer.child = value;
        }
    }

    protected Gtk.Revealer revealer;

    construct {
        revealer = new Gtk.Revealer () {
            halign = CENTER,
            valign = CENTER,
            reveal_child = true,
            transition_type = CROSSFADE,
            width_request = 350
        };

        append (revealer);

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
