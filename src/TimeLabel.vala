/*
* Copyright (c) 2011-2016 elementary LLC (http://launchpad.net/pantheon-greeter)
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
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
*/

public class TimeLabel : GtkClutter.Actor {
    private Gtk.Label date_label;
    private Gtk.Label time_label;
    private Gtk.Label pm_label;

    public TimeLabel () {
        update_time ();
        Clutter.Threads.Timeout.add (5000, update_time);
    }

    construct {
        var container_widget = (Gtk.Container)this.get_widget ();

        var layout = new Gtk.Grid ();
        layout.margin = 16;

        date_label = new Gtk.Label ("");
        date_label.get_style_context ().add_class ("h2");
        date_label.hexpand = true;

        time_label = new Gtk.Label ("");
        time_label.get_style_context ().add_class ("time");

        pm_label = new Gtk.Label ("");
        pm_label.get_style_context ().add_class ("time");
        pm_label.get_style_context ().add_class ("pm");

        layout.attach (date_label, 0, 0, 2, 1);
        layout.attach (time_label, 0, 1, 1, 1);
        layout.attach (pm_label, 1, 1, 1, 1);
        layout.show_all ();

        container_widget.add (layout);
    }

    bool update_time () {
        var date = new GLib.DateTime.now_local ();

        /// Date display, see http://valadoc.org/#!api=glib-2.0/GLib.DateTime.format for more details
        var day_format = _("%A, %B %e");
        /// Time display, see http://valadoc.org/#!api=glib-2.0/GLib.DateTime.format for more details
        var time_format = _("%l:%M");
        /// AM/PM display, see http://valadoc.org/#!api=glib-2.0/GLib.DateTime.format for more details. If you translate in a language that has no equivalent for AM/PM, keep the original english string.
        var meridiem_format = _(" %p");

        date_label.label = date.format (day_format);
        time_label.label = date.format (time_format);
        pm_label.label = date.format (meridiem_format);
        return true;
    }
}
