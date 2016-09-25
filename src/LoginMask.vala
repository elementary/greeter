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

public enum PromptType {
    /**
     * Reply with the password.
     */
    SECRET,
    /**
     * Reply with the password.
     */
    QUESTION,
    /**
     * Reply with any text to confirm that you want to login.
     */
    CONFIRM_LOGIN,
    /**
     * Show fingerprint prompt
     */
    FPRINT
}

public enum PromptText {
    /**
     * A message asking for username entry
     */
    USERNAME,
    /**
     * A message asking for password entry
     */
    PASSWORD,
    /**
     * The message was not in the expected list
     */
    OTHER
}

public enum MessageText {
    /**
     * fprintd message to swipe finger
     */
    FPRINT_SWIPE,
    /**
     * fprintd message to swipe again
     */
    FPRINT_SWIPE_AGAIN,
    /**
     * fprintd message to swipe longer
     */
    FPRINT_SWIPE_TOO_SHORT,
    /**
     * fprintd message to center finger
     */
    FPRINT_NOT_CENTERED,
    /**
     * fprintd message to remove finger
     */
    FPRINT_REMOVE,
    /**
     * fprintd message to place finger on device again
     */
    FPRINT_PLACE,
    /**
     * fprintd message to place finger on device again
     */
    FPRINT_PLACE_AGAIN,
    /**
     * fprintd failure message
     */
    FPRINT_NO_MATCH,
    /**
     * fprintd timeout message
     */
    FPRINT_TIMEOUT,
    /**
     * Unknown fprintd error
     */ 
    FPRINT_ERROR,
    /**
     * Login failed
     */ 
    FAILED,
    /**
     * The message was not in the expected list
     */
    OTHER
}

/**
 * A LoginMask is for example a UI such as the LoginBox that communicates with
 * the user.
 * It forms with the LoginGateway a protocol for logging in users. The steps
 * are roughly:
 * 1. gateway.login_with_mask - Call this as soon as you know the username
 *           The gateway will get the login_name via the property of your
 *           mask.
 * 2. mask.show_prompt or mask.show_message - one of both is called and the
 *           mask has to display that to the user.
 *           show_prompt also demands that you answer
 *           via gateway.respond.
 * 3. Repeat Step 2 until the gateway fires login_successful
 * 4. Call gateway.start_session after login_successful is called
 *
 *
 */
public interface LoginMask : GLib.Object {

    public abstract string login_name { get; }
    public abstract string login_session { get; }

    /**
     * Present a prompt to the user. The interface can answer via the
     * respond method of the LoginGateway.
     */
     public abstract void show_prompt (PromptType type, PromptText prompttext = PromptText.OTHER, string text = "");
     
     public abstract void show_message (LightDM.MessageType type, MessageText messagetext = MessageText.OTHER, string text = "");

     public abstract void not_authenticated ();

    /**
     * The login-try was aborted because another LoginMask wants to login.
     */
    public abstract void login_aborted ();
}
