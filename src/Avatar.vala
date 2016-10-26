/*
* Copyright (c) 2011-2016 elementary LLC. (http://launchpad.net/pantheon-greeter)
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

public class Avatar : GtkClutter.Actor {
    public LoginOption user { get; construct; }

    public Avatar (LoginOption user) {
        Object (user: user);
    }

    construct {
        var container_widget = (Gtk.Container)this.get_widget ();

        var avatar = new Granite.Widgets.Avatar ();
        avatar.pixbuf = user.avatar;

        container_widget.add (avatar);

        if (user.logged_in) {
            var logged_in = new LoggedInIcon ();
            logged_in.x = logged_in.y = 80;
            add_child (logged_in);
        }
    }
}

public class LoggedInIcon : GtkClutter.Actor {
    public LoggedInIcon () {
        var container_widget = (Gtk.Container)this.get_widget ();

        var image = new Gtk.Image.from_icon_name ("selection-checked", Gtk.IconSize.LARGE_TOOLBAR);

        container_widget.add (image);
    }
}
