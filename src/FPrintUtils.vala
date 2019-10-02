/*
 * Copyright 2018 elementary, Inc. (https://elementary.io)
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

namespace Greeter.FPrintUtils {
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

    private inline string fprintd_message (string message) {
        //return GLib.dgettext ("fprintd", message);
        return message;
    }

    public MessageText string_to_messagetext (string text) {
        // Ideally this would query PAM and ask which module is currently active,
        // but since we're running through LightDM we don't have that ability.
        // There should at be a state machine to transition to and from the 
        // active module depending on the messages recieved. But, this is can go
        // wrong quickly. 
        // The reason why this is needed is, for example, we can get the "An
        // unknown error occured" message from pam_fprintd, but we can get it 
        // from some other random module as well. You never know.
        // Maybe it's worth adding some LightDM/PAM functionality for this? 
        // The PAM "feature" which makes it all tricky is that modules can send 
        // arbitrary messages to the stream and it's hard to analyze or keep track
        // of them programmatically. 
        // Also, there doesn't seem to be a way to give the user a choice over
        // which module he wants to use to authenticate (ie. maybe today I have
        // a bandaid over my finger and I can't scan it so I have to wait for it
        // time out, if I didn't disable that in the settings)
        // 
        // These messages are taken from here: 
        //  - https://gitlab.freedesktop.org/libfprint/fprintd/blob/master/pam/fingerprint-strings.h
        //  - https://gitlab.freedesktop.org/libfprint/fprintd/blob/master/pam/pam_fprintd.c

        if (text == fprintd_message ("An unknown error occured")) {
            return MessageText.FPRINT_ERROR;
        } else if (text == fprintd_message ("An unknown error occurred")) {
            return MessageText.FPRINT_ERROR;
        } else if (check_fprintd_string (text, "Swipe", "across")) {
            return MessageText.FPRINT_SWIPE;
        } else if (text == fprintd_message ("Swipe your finger again")) {
            return MessageText.FPRINT_SWIPE_AGAIN;
        } else if (text == fprintd_message ("Swipe was too short, try again")) {
            return MessageText.FPRINT_SWIPE_TOO_SHORT;
        } else if (text == fprintd_message ("Your finger was not centered, try swiping your finger again")) {
            return MessageText.FPRINT_NOT_CENTERED;
        } else if (text == fprintd_message ("Remove your finger, and try swiping your finger again")) {
            return MessageText.FPRINT_REMOVE;
        } else if (check_fprintd_string (text, "Place", "on")) {
            return MessageText.FPRINT_PLACE;
        } else if (text == fprintd_message ("Place your finger on the reader again")) {
            return MessageText.FPRINT_PLACE_AGAIN;
        } else if (text == fprintd_message ("Failed to match fingerprint")) {
            return MessageText.FPRINT_NO_MATCH;
        } else if (text == fprintd_message ("Verification timed out")) {
            return MessageText.FPRINT_TIMEOUT;
        } else if (text == "Login failed") {
            return MessageText.FAILED;
        }

        return MessageText.OTHER;
    }

    private bool check_fprintd_string (string text, string action, string position) {
        const string[] FINGERS = {
            "finger",
            "left thumb", "left index finger", "left middle finger", "left ring finger", "left little finger",
            "right thumb", "right index finger", "right middle finger", "right ring finger", "right little finger"
        };

        foreach (unowned string finger in FINGERS) {
            // Place your finger on %s
            var english_string = action.concat (" your ", finger, " ", position, " %s");

            if (text.has_prefix (fprintd_message (english_string)) ||
                text.has_prefix (fprintd_message (english_string.printf ("the fingerprint reader")))) {
                return true;
            }

        }

        return false;
    }
}
