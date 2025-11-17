/*
 * Copyright 2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class SessionWorker.Application : GLib.Application {
    public Application () {
        Object (
            application_id: "io.elementary.greeter-session-worker",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        Bus.own_name (
            SESSION, "io.elementary.GreeterSessionWorker", NONE, null,
            (connection, name) => {
                try {
                    connection.register_object ("/io/elementary/greeter-session-worker", new SessionWorker ());
                } catch (Error e) {
                    critical (e.message);
                }
            },
            (connection, name) => critical ("Lost %s ownership", name)
        );
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}
