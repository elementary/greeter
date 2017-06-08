/*
* Copyright (c) 2011-2017 elementary LLC. (http://launchpad.net/pantheon-greeter)
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
        var path = user.avatar_path;
        Granite.Widgets.Avatar avatar;
        if (path != null) {
            avatar = new Granite.Widgets.Avatar.from_file (path, 96);
        } else {
            avatar = new Granite.Widgets.Avatar.with_default_icon (96);
        }

        var container_widget = (Gtk.Container)this.get_widget ();
        container_widget.add (avatar);

        if (user.logged_in) {
            var logged_in = new Gtk.Image.from_icon_name ("selection-checked", Gtk.IconSize.LARGE_TOOLBAR);

            var logged_in_actor = new GtkClutter.Actor ();
            logged_in_actor.x = logged_in_actor.y = 80;

            ((Gtk.Container) logged_in_actor.get_widget ()).add (logged_in);

            add_child (logged_in_actor);
        }
    }
}
