/*
 * Copyright 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authored by: Leonhard Kargl <leo.kargl@proton.me>
 */

/**
 * Used as a key for Object.set_data<bool> on Meta.Windows that should be
 * treated as notifications. Has to be set before the window is mapped.
 */
public const string NOTIFICATION_DATA_KEY = "elementary-notification";

public class GreeterCompositor.NotificationsClient : Object {
    public Meta.Display display { get; construct; }

    private ManagedClient client;

    public NotificationsClient (Meta.Display display) {
        Object (display: display);
    }

    construct {
        client = new ManagedClient (display, { "io.elementary.notifications" });

        client.window_created.connect ((window) => {
            window.set_data (NOTIFICATION_DATA_KEY, true);
            window.make_above ();

            if (Meta.Util.is_wayland_compositor ()) {
#if HAS_MUTTER46
            client.wayland_client.make_dock (window);
#endif
            } else {
                ShellClientsManager.get_instance ().make_dock (window);
            }
        });
    }
}
