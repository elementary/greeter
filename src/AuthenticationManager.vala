/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 elementary, Inc. (https://elementary.io)
 *
 * Authors: Leo "lenemter" <lenemter@gmail.com>
 */

private class Greeter.AuthenticationManager : Object {
    public LightDM.Greeter lightdm_greeter { private get; construct; }

    private bool waiting_for_authentication_to_complete = false;
    private string queued_credential = "";

    public AuthenticationManager (LightDM.Greeter lightdm_greeter) {
        Object (lightdm_greeter: lightdm_greeter);
    }

    construct {
        lightdm_greeter.show_prompt.connect (on_show_prompt);
    }

    private void on_show_prompt (string text, LightDM.PromptType type) {
        if (type != SECRET ||
            !waiting_for_authentication_to_complete
        ) {
            return;
        }

        waiting_for_authentication_to_complete = false;

        try {
            lightdm_greeter.respond (queued_credential);
        } catch (Error e) {
            critical (e.message);
        }

        queued_credential = "";
    }

    public void cancel_authentication () {
        if (!lightdm_greeter.in_authentication) {
            return;
        }

        try {
            lightdm_greeter.cancel_authentication ();
        } catch (Error e) {
            critical (e.message);
        }
    }

    public void authenticate (string username, string credential) {
        cancel_authentication ();

        try {
            lightdm_greeter.authenticate (username);
            waiting_for_authentication_to_complete = true;
            queued_credential = credential;
        } catch (Error e) {
            critical (e.message);
        }
    }
}
