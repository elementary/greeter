/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2018-2025 elementary, Inc. (https://elementary.io)
 *
 * Authors: Corentin Noël <corentin@elementary.io>
 */

public abstract class Greeter.BaseCard : Granite.Bin {
    public signal void do_connect (string? credential = null);

    protected const int ERROR_SHAKE_DURATION = 450;

    public bool connecting { get; set; default = false; }
    public bool need_password { get; set; default = false; }
    public bool use_fingerprint { get; set; default = false; }

    construct {
        halign = CENTER;
        valign = CENTER;
        width_request = 350;
    }

    public abstract void wrong_credentials ();
}
