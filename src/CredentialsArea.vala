// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2014 elementary Developers

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/

public abstract class CredentialsArea : Gtk.Grid {
    public signal void replied (string answer);
    public abstract void pass_focus ();
    
    public abstract void show_message (LightDM.MessageType type, MessageText messagetext = MessageText.OTHER, string text = "");
}

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

public class LoginButtonArea : CredentialsArea {

    Gtk.Button login_btn;

    public LoginButtonArea () {
        login_btn = new Gtk.Button.with_label (_("Log In"));
        login_btn.clicked.connect (() => {
            // It doesn't matter what we answer, the confirmation
            // is that we reply at all.
            replied ("");
        });

        login_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        attach (login_btn, 0, 1, 1, 1);
    }

    public override void pass_focus () {
        login_btn.grab_focus ();
    }
    
    public override void show_message (LightDM.MessageType type, MessageText messagetext = MessageText.OTHER, string text = "") {
        // there are no messages to display
    }
}


public class FingerprintIndicatorArea : CredentialsArea {
    Gtk.EventBox box = new Gtk.EventBox ();
    Gtk.Label label = new Gtk.Label (null);
    
    public FingerprintIndicatorArea () {
        this.margin_top = 15;
        
        Gdk.Pixbuf image = null;
        var margin = 2;

        try {
            image = new Gdk.Pixbuf.from_file_at_size (Constants.PKGDATADIR+"/fingerprint.png", 26, 26);
        } catch (Error e) {
           warning (@"Can't load fingerprint icon due to $(e.message)");
        }
        
        box.valign = Gtk.Align.START;
        box.visible_window = false;
        box.margin_top = 5;
        box.margin_left = 10;
        
        if (image != null) {
            box.set_size_request (image.width + 4*margin, image.height + 4*margin);
        }
        
        var box_style_context = box.get_style_context ();

        box_style_context.add_class ("fingerprint");
        
        box.draw.connect ((ctx) => {
            int width = box.get_allocated_width () - 2*margin;
            int height = box.get_allocated_height () - 2*margin;

            if (image != null) {
                Gdk.cairo_set_source_pixbuf (ctx, image, 2*margin, 2*margin);
            }
           
            box_style_context.render_background (ctx, margin, margin, width, height);
            box_style_context.render_frame (ctx, margin, margin, width, height);
            
            ctx.paint ();
            
            return false;
        });
            
        attach(box, 0, 0,1,1);
        
        label.margin_left = 7;
        label.margin_top = 2;
        
        var label_style_context = label.get_style_context ();

        label_style_context.add_class ("h3");
        label_style_context.add_class ("fingerprint-label");
                
        attach(label, 1, 0 ,1,1);
    }
    
    public override void pass_focus () {
    }
    
    public override void show_message (LightDM.MessageType type, MessageText messagetext = MessageText.OTHER, string text = "") {
        var label_style_context = label.get_style_context ();
        
        if (type == LightDM.MessageType.INFO) {
            label_style_context. remove_class("error");
            label_style_context. add_class ("info");
        } else {
            label_style_context. remove_class("info");
            label_style_context. add_class ("error");
        }
        
        // some fprint messages are too long, so we override them
        if (messagetext == MessageText.FPRINT_SWIPE) {
            text = _("Swipe your finger");
        } else if (messagetext == MessageText.FPRINT_PLACE) {
            text = _("Place your finger");
        } else if (messagetext == MessageText.FPRINT_REMOVE) {
            text = _("Remove your finger and try again.");
        } else if (messagetext == MessageText.FPRINT_NOT_CENTERED) {
            text = _("Center your finger and try again.");
        }
                
        label.set_text(text);
    }
}