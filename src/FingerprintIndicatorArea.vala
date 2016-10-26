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

public enum MessageText {
    FPRINT_SWIPE,
    FPRINT_SWIPE_AGAIN,
    FPRINT_SWIPE_TOO_SHORT,
    FPRINT_NOT_CENTERED,
    FPRINT_REMOVE,
    FPRINT_PLACE,
    FPRINT_PLACE_AGAIN,
    FPRINT_NO_MATCH,
    FPRINT_TIMEOUT,
    FPRINT_ERROR,
    FAILED,
    OTHER
}

public class FingerprintIndicatorArea : CredentialsArea {
    Gtk.Label label;

    const string STYLE_CSS = """
        .fingerprint {
            background-image:
                linear-gradient(
                    to bottom,
                    shade (#666, 1.30),
                    #666
                );
            border-radius: 50%;
            box-shadow:
                inset 0 0 0 1px alpha (#999, 0.05),
                inset 0 1px 0 0 alpha (#999, 0.45),
                inset 0 -1px 0 0 alpha (#999, 0.15),
                0 1px 2px alpha (#000, 0.15),
                0 2px 6px alpha (#000, 0.10);
        }

        .fingerprint-label {
            text-shadow: 0 0 3px alpha (#000, 0.4);
        }

        .fingerprint-label.info {
            color: alpha (#fff, 0.8);
        }

        .fingerprint-label.error {
            color: lighter (@error_color);
        }
    """;

    public FingerprintIndicatorArea () {
        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_data (STYLE_CSS, STYLE_CSS.length);
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning (e.message);
        } 

        var image = new Gtk.Image.from_file (Constants.PKGDATADIR + "/fingerprint.svg");
        image.margin = 3;

        var box = new Gtk.Grid ();
        box.get_style_context ().add_class ("fingerprint");
        box.add (image);

        label = new Gtk.Label ("");
        label.valign = Gtk.Align.CENTER;
        
        var label_style_context = label.get_style_context ();
        label_style_context.add_class ("h3");
        label_style_context.add_class ("fingerprint-label");

        attach (box, 0, 0, 1, 1);   
        attach (label, 1, 0, 1, 1);
        column_spacing = 6;
        margin_top = 24;
        margin_left = 12;
    }

    public override void pass_focus () {
    }

    public override void show_message (LightDM.MessageType type, MessageText messagetext = MessageText.OTHER, string text = "") {
        var label_style_context = label.get_style_context ();
        
        if (type == LightDM.MessageType.INFO) {
            label_style_context.remove_class (Gtk.STYLE_CLASS_ERROR);
            label_style_context.add_class (Gtk.STYLE_CLASS_INFO);
        } else {
            label_style_context.remove_class (Gtk.STYLE_CLASS_INFO);
            label_style_context.add_class (Gtk.STYLE_CLASS_ERROR);
        }

        switch (messagetext) {
            case MessageText.FPRINT_SWIPE:
                label.label = _("Swipe your finger");
                break;
            case MessageText.FPRINT_PLACE:
                label.label = _("Place your finger");
                break;
            case MessageText.FPRINT_REMOVE:
                label.label = _("Remove your finger and try again.");
                break;
            case MessageText.FPRINT_NOT_CENTERED:
                label.label = _("Center your finger and try again.");
                break;
            default:
                label.label = text;
                break;
        }
    }
}
