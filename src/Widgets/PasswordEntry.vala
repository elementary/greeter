/*
 * Copyright 2018–2019 elementary, Inc. (https://elementary.io)
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

public class Greeter.PasswordEntry : Gtk.Entry {
    construct {
        halign = Gtk.Align.CENTER;
        hexpand = true;
        input_purpose = Gtk.InputPurpose.PASSWORD;
        max_width_chars = 48;
        primary_icon_name = "dialog-password-symbolic";
        secondary_icon_name = "go-jump-symbolic";
        secondary_icon_tooltip_text = _("Log In");
        tooltip_text = _("Password");
        visibility = false;

        icon_press.connect ((pos, event) => {
            if (pos == Gtk.EntryIconPosition.SECONDARY) {
                activate ();
            }
        });
    }
}
