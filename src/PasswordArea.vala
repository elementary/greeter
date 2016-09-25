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

public class PasswordArea : CredentialsArea {

    Gtk.Entry password;

    public PasswordArea () {
        create_password_field ();
    }

    void create_password_field () {
        password = new Gtk.Entry ();

        password.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "dialog-password-symbolic");
        password.caps_lock_warning = true;
        password.visibility = false;
        password.hexpand = true;
        password.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "go-jump-symbolic");
        password.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Log In"));
        password.icon_press.connect ((pos, event) => {
            if (pos == Gtk.EntryIconPosition.SECONDARY) {
                replied (password.text);
            }
        });
        password.key_release_event.connect ((e) => {
            if (e.keyval == Gdk.Key.Return || e.keyval == Gdk.Key.KP_Enter) {
                replied (password.text);
                return true;
            } else {
                return false;
            }
        });

        attach (password, 0, 0, 1, 1);
    }

    public override void pass_focus () {
        password.grab_focus ();
    }
    
    public override void show_message (LightDM.MessageType type, MessageText messagetext = MessageText.OTHER, string text = "") {
        // there are no messages to display
    }
}
