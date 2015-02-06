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
    PASSWORD,
    /**
     * Reply with any text to confirm that you want to login.
     */
    CONFIRM_LOGIN
}

public enum MessageType {
    /**
     * Input was wrong (wrong username or password).
     */
    WRONG_INPUT
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
    public abstract void show_prompt (PromptType type);

    public abstract void show_message (MessageType type);

    /**
     * The login-try was aborted because another LoginMask wants to login.
     */
    public abstract void login_aborted ();
}


public interface LoginGateway : GLib.Object {

    public abstract bool hide_users { get; }
    public abstract bool has_guest_account { get; }
    public abstract bool show_manual_login { get; }
    public abstract bool lock { get; }
    public abstract string default_session { get; }

    /**
     * Starts the login-procedure for the passed
     */
    public abstract void login_with_mask (LoginMask mask, bool guest);

    public abstract void respond (string message);

    /**
     * Called when a user successfully logins. It gives the Greeter time
     * to run fade out animations etc.
     * The Gateway shall not accept any request from now on beside
     * the start_session call.
     */
    public signal void login_successful ();

    /**
     * Only to be called after the login_successful was fired.
     * Will start the session and exits this process.
     */
    public abstract void start_session ();

}

/**
 * Passes communication to LightDM.
 */
public class LightDMGateway : LoginGateway, Object {

    /**
     * The last Authenticatable that tried to login via this authenticator.
     * This variable is null in case no one has tried to login so far.
     */
    LoginMask? current_login { get; private set; default = null; }

    /**
     * True if and only if the current login got at least one prompt.
     * This is for example used for the guest login which doesn't need
     * to answer any prompt and can directly login. Here we first have to
     * ask the LoginMask for a confirmation or otherwise you would
     * automatically login as guest if you select the guest login.
     */
    bool had_prompt = false;

    /**
     * True if and only if we first await a extra-response before
     * we actually login. In case another login_with_mask call happens
     * we just set this to false again.
     */
    bool awaiting_confirmation = false;

    bool awaiting_start_session = false;

    LightDM.Greeter lightdm;

    public bool hide_users {
        get {
            return lightdm.hide_users_hint;
        }
    }
    public bool has_guest_account {
        get {
            return lightdm.has_guest_account_hint;
        }
    }
    public bool show_manual_login {
        get {
            return lightdm.show_manual_login_hint;
        }
    }
    public bool lock {
        get {
            return lightdm.lock_hint;
        }
    }
    public string default_session {
        get {
            return lightdm.default_session_hint;
        }
    }

    public LightDMGateway () {
        message ("Connecting to LightDM...");
        lightdm = new LightDM.Greeter ();

        try {
            lightdm.connect_sync ();
        } catch (Error e) {
            warning (@"Couldn't connect to lightdm: $(e.message)");
            Posix.exit (Posix.EXIT_FAILURE);
        }
        message ("Successfully connected to LightDM.");
        lightdm.show_message.connect (this.show_message);
        lightdm.show_prompt.connect (this.show_prompt);
        lightdm.authentication_complete.connect (this.authentication);
    }

    public void login_with_mask (LoginMask login, bool guest) {
        if (awaiting_start_session) {
            warning ("Got login_with_mask while awaiting start_session!");
            return;
        }

        message (@"Starting authentication...");
        if (current_login != null)
            current_login.login_aborted ();

        had_prompt = false;
        awaiting_confirmation = false;

        current_login = login;
        if (guest) {
            lightdm.authenticate_as_guest ();
        } else {
            lightdm.authenticate (current_login.login_name);
        }
    }

    public void respond (string text) {
        if (awaiting_start_session) {
            warning ("Got respond while awaiting start_session!");
            return;
        }

        if (awaiting_confirmation) {
            warning ("Got user-interaction. Starting session");
            awaiting_start_session = true;
            login_successful ();
        } else {
            // We don't log this as it contains passwords etc.
            lightdm.respond (text);
        }
    }

    void show_message (string text, LightDM.MessageType type) {
        message (@"LightDM message: '$text' ($(type.to_string ()))");
        current_login.show_message (string_to_messagetype (text));
    }

    void show_prompt (string text, LightDM.PromptType type) {
        had_prompt = true;
        message (@"LightDM prompt: '$text' ($(type.to_string ()))");
        current_login.show_prompt (string_to_prompttype(text));
    }

    PromptType string_to_prompttype (string text) {
        if (text == "Password: ")
            return PromptType.PASSWORD;
        // TODO better fallback
        return PromptType.PASSWORD;
    }

    MessageType string_to_messagetype (string text) {
        // TODO actually parse the text
        return MessageType.WRONG_INPUT;
    }

    public void start_session () {
        if (!awaiting_start_session) {
            warning ("Got start_session without awaiting it.");
        }
        message (@"Starting session $(current_login.login_session)");
        PantheonGreeter.instance.settings.set_string ("greeter",
                "last-user",
                current_login.login_name);
        try {
            lightdm.start_session_sync (current_login.login_session);
        } catch (Error e) {
            error (e.message);
        }
        Posix.exit (Posix.EXIT_SUCCESS);
    }

    void authentication () {
        if (lightdm.is_authenticated) {
            // Check if the LoginMask actually got userinput that confirms
            // that the user wants to start a session now.
            if (had_prompt) {
                // If yes, start a session
                awaiting_start_session = true;
                login_successful ();
            } else {
                message ("Auth complete, but we await user-interaction before we"
                        + "start a session");
                // If no, send a prompt and await the confirmation via respond.
                // This variables is checked in respond as a special case.
                awaiting_confirmation = true;
                current_login.show_prompt (PromptType.CONFIRM_LOGIN);
            }
        } else {
            current_login.show_message (MessageType.WRONG_INPUT);
        }
    }
}


/**
 * For testing purposes a Gateway which only allows the guest to login.
 */
public class DummyGateway : LoginGateway, Object {

    public bool hide_users { get { return false; } }
    public bool has_guest_account { get { return true; } }
    public bool show_manual_login { get { return true; } }
    public bool lock { get {return false; } }
    public string default_session { get { return ""; } }

    LoginMask last_login_mask;

    bool last_was_guest = true;

    public void login_with_mask (LoginMask mask, bool guest) {
        if (last_login_mask != null)
            mask.login_aborted ();

        last_was_guest = guest;
        last_login_mask = mask;
        Idle.add (() => {
            mask.show_prompt (guest ? PromptType.CONFIRM_LOGIN : PromptType.PASSWORD);
            return false;
        });
    }

    public void respond (string message) {
        if (last_was_guest) {
            Idle.add (() => {
                login_successful ();
                return false;
            });
        } else {
            Idle.add (() => {
                last_login_mask.show_message (MessageType.WRONG_INPUT);
                return false;
            });
        }
    }

    public void start_session () {
        message ("Started session");
        Posix.exit (Posix.EXIT_SUCCESS);
    }

}
