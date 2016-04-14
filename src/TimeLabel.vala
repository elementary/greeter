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

public class TimeLabel : ShadowedLabel {

    public TimeLabel () {
        base ("");

        update_time ();
        Clutter.Threads.Timeout.add (5000, update_time);
    }

    bool update_time () {
        var date = new GLib.DateTime.now_local ();

        /// Date display, see http://valadoc.org/#!api=glib-2.0/GLib.DateTime.format for more details
        var day_format = _("%A, %B %e");
        /// Time display, see http://valadoc.org/#!api=glib-2.0/GLib.DateTime.format for more details
        var time_format = _("%l:%M");
        /// AM/PM display, see http://valadoc.org/#!api=glib-2.0/GLib.DateTime.format for more details. If you translate in a language that has no equivalent for AM/PM, keep the original english string.
        var meridiem_format = _(" %p");

        label = date.format (
            "<span face='Open Sans Light' font='24'>"+
            day_format+
            "</span>\n<span face='Raleway' weight='100' font='72'>"+
            time_format+
            "</span><span face='Raleway' weight='100' font='50'>"+
            meridiem_format+
            "</span>");
        return true;
    }
}
