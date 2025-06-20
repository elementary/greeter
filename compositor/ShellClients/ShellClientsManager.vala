/*
 * Copyright 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Authored by: Leonhard Kargl <leo.kargl@proton.me>
 */

public class GreeterCompositor.ShellClientsManager : Object {
    private static ShellClientsManager instance;

    public static void init (WindowManager wm) {
        if (instance != null) {
            return;
        }

        instance = new ShellClientsManager (wm);
    }

    public static unowned ShellClientsManager? get_instance () {
        return instance;
    }

    public Clutter.Actor? actor { get { return wm.stage; } }

    public WindowManager wm { get; construct; }

    private NotificationsClient notifications_client;
    private ManagedClient[] protocol_clients = {};

    private GLib.HashTable<Meta.Window, PanelWindow> panel_windows = new GLib.HashTable<Meta.Window, PanelWindow> (null, null);
    private GLib.HashTable<Meta.Window, ShellWindow> positioned_windows = new GLib.HashTable<Meta.Window, ShellWindow> (null, null);

    private ShellClientsManager (WindowManager wm) {
        Object (wm: wm);
    }

    construct {
        notifications_client = new NotificationsClient (wm.get_display ());

        start_clients.begin ();

        if (!Meta.Util.is_wayland_compositor ()) {
            wm.get_display ().window_created.connect ((window) => {
                window.notify["mutter-hints"].connect ((obj, pspec) => parse_mutter_hints ((Meta.Window) obj));
                parse_mutter_hints (window);
            });
        }
    }

    private async void start_clients () {
        protocol_clients += new ManagedClient (wm.get_display (), { "io.elementary.wingpanel", "-g" });
    }

    public void make_dock (Meta.Window window) {
        if (Meta.Util.is_wayland_compositor ()) {
            make_dock_wayland (window);
        } else {
            make_dock_x11 (window);
        }
    }

    private void make_dock_wayland (Meta.Window window) requires (Meta.Util.is_wayland_compositor ()) {
        foreach (var client in protocol_clients) {
            if (client.wayland_client.owns_window (window)) {
#if HAS_MUTTER46
                client.wayland_client.make_dock (window);
#endif
                break;
            }
        }
    }

    private void make_dock_x11 (Meta.Window window) requires (!Meta.Util.is_wayland_compositor ()) {
        unowned var x11_display = wm.get_display ().get_x11_display ();

#if HAS_MUTTER46
        var x_window = x11_display.lookup_xwindow (window);
#else
        var x_window = window.get_xwindow ();
#endif
        // gtk3's gdk_x11_window_set_type_hint() is used as a reference
        unowned var xdisplay = x11_display.get_xdisplay ();
        var atom = xdisplay.intern_atom ("_NET_WM_WINDOW_TYPE", false);
        var dock_atom = xdisplay.intern_atom ("_NET_WM_WINDOW_TYPE_DOCK", false);

        // (X.Atom) 4 is XA_ATOM
        // 32 is format
        // 0 means replace
        xdisplay.change_property (x_window, atom, (X.Atom) 4, 32, 0, (uchar[]) dock_atom, 1);
    }


    public void make_desktop (Meta.Window window) {
        if (Meta.Util.is_wayland_compositor ()) {
            make_desktop_wayland (window);
        } else {
            make_desktop_x11 (window);
        }
    }

    private void make_desktop_wayland (Meta.Window window) requires (Meta.Util.is_wayland_compositor ()) {
        foreach (var client in protocol_clients) {
            if (client.wayland_client.owns_window (window)) {
                client.wayland_client.make_desktop (window);
                break;
            }
        }
    }

    private void make_desktop_x11 (Meta.Window window) requires (!Meta.Util.is_wayland_compositor ()) {
        unowned var x11_display = wm.get_display ().get_x11_display ();

#if HAS_MUTTER46
        var x_window = x11_display.lookup_xwindow (window);
#else
        var x_window = window.get_xwindow ();
#endif
        // gtk3's gdk_x11_window_set_type_hint() is used as a reference
        unowned var xdisplay = x11_display.get_xdisplay ();
        var atom = xdisplay.intern_atom ("_NET_WM_WINDOW_TYPE", false);
        var dock_atom = xdisplay.intern_atom ("_NET_WM_WINDOW_TYPE_DESKTOP", false);

        // (X.Atom) 4 is XA_ATOM
        // 32 is format
        // 0 means replace
        xdisplay.change_property (x_window, atom, (X.Atom) 4, 32, 0, (uchar[]) dock_atom, 1);
    }

    public void set_anchor (Meta.Window window, Pantheon.Desktop.Anchor anchor) {
        if (window in panel_windows) {
            panel_windows[window].anchor = anchor;
            return;
        }

        make_dock (window);
        // TODO: Return if requested by window that's not a trusted client?

        panel_windows[window] = new PanelWindow (wm, window, anchor);

        // connect_after so we make sure the PanelWindow can destroy its barriers and struts
        window.unmanaging.connect_after ((_window) => panel_windows.remove (_window));
    }

    /**
     * The size given here is only used for the hide mode. I.e. struts
     * and collision detection with other windows use this size. By default
     * or if set to -1 the size of the window is used.
     *
     * TODO: Maybe use for strut only?
     */
    public void set_size (Meta.Window window, int width, int height) {
        if (!(window in panel_windows)) {
            warning ("Set anchor for window before size.");
            return;
        }

        panel_windows[window].set_size (width, height);
    }

    public void set_hide_mode (Meta.Window window, Pantheon.Desktop.HideMode hide_mode) {
        debug ("Hide mode is unsupported in greeter-compositor");
    }

    public void init_greeter (Meta.Window window) {
        make_desktop (window);

        positioned_windows[window] = new ShellWindow (window, FULLSCREEN);

        // connect_after so we make sure that any queued move is unqueued
        window.unmanaging.connect_after ((_window) => positioned_windows.remove (_window));
    }

    public void make_centered (Meta.Window window) requires (!is_itself_positioned (window)) {
        positioned_windows[window] = new ShellWindow (window, CENTER);

        // connect_after so we make sure that any queued move is unqueued
        window.unmanaging.connect_after ((_window) => positioned_windows.remove (_window));
    }

    public bool is_itself_positioned (Meta.Window window) {
        return (window in positioned_windows) || (window in panel_windows) || window.get_data (NOTIFICATION_DATA_KEY);
    }

    //X11 only
    private void parse_mutter_hints (Meta.Window window) requires (!Meta.Util.is_wayland_compositor ()) {
        if (window.mutter_hints == null) {
            return;
        }

        var mutter_hints = window.mutter_hints.split (":");
        foreach (var mutter_hint in mutter_hints) {
            var split = mutter_hint.split ("=");

            if (split.length != 2) {
                continue;
            }

            var key = split[0];
            var val = split[1];

            switch (key) {
                case "anchor":
                    int meta_side_parsed; // Will be used as Meta.Side which is a 4 value bitfield so check bounds for that
                    if (int.try_parse (val, out meta_side_parsed) && 0 <= meta_side_parsed && meta_side_parsed <= 15) {
                        //FIXME: Next major release change dock and wingpanel calls to get rid of this
                        Pantheon.Desktop.Anchor parsed = TOP;
                        switch ((Meta.Side) meta_side_parsed) {
                            case BOTTOM:
                                parsed = BOTTOM;
                                break;

                            case LEFT:
                                parsed = LEFT;
                                break;

                            case RIGHT:
                                parsed = RIGHT;
                                break;

                            default:
                                break;
                        }

                        set_anchor (window, parsed);
                        // We need to set a second time because the intention is to call this before the window is shown which it is on wayland
                        // but on X the window was already shown when we get here so we have to call again to instantly apply it.
                        set_anchor (window, parsed);
                    } else {
                        warning ("Failed to parse %s as anchor", val);
                    }
                    break;

                case "hide-mode":
                    int parsed; // Will be used as Pantheon.Desktop.HideMode which is a 5 value enum so check bounds for that
                    if (int.try_parse (val, out parsed) && 0 <= parsed && parsed <= 4) {
                        set_hide_mode (window, parsed);
                    } else {
                        warning ("Failed to parse %s as hide mode", val);
                    }
                    break;

                case "size":
                    var split_val = val.split (",");
                    if (split_val.length != 2) {
                        break;
                    }
                    int parsed_width, parsed_height = 0; //set to 0 because vala doesn't realize height will be set too
                    if (int.try_parse (split_val[0], out parsed_width) && int.try_parse (split_val[1], out parsed_height)) {
                        set_size (window, parsed_width, parsed_height);
                    } else {
                        warning ("Failed to parse %s as width and height", val);
                    }
                    break;

                case "greeter":
                    init_greeter (window);
                    break;

                case "centered":
                    make_centered (window);
                    break;

                case "restore-previous-region":
                    set_restore_previous_x11_region (window);
                    break;

                default:
                    break;
            }
        }
    }

    private void set_restore_previous_x11_region (Meta.Window window)
    requires (!Meta.Util.is_wayland_compositor ())
    requires (window in panel_windows) {
        debug ("restore-previous-region is unsupported in greeter-compositor");
    }
}
