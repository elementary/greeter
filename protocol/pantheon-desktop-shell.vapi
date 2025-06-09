/*
 * Copyright 2023-2025 elementary, Inc. <https://elementary.io>
 * Copyright 2023 Corentin Noël <tintou@noel.tf>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Pantheon.Desktop {
    [CCode (cheader_filename = "pantheon-desktop-shell-client-protocol.h", cname = "struct io_elementary_pantheon_shell_v1", cprefix = "io_elementary_pantheon_shell_v1_")]
    public class Shell : Wl.Proxy {
        [CCode (cheader_filename = "pantheon-desktop-shell-client-protocol.h", cname = "io_elementary_pantheon_shell_v1_interface")]
        public static Wl.Interface iface;
        public void set_user_data (void* user_data);
        public void* get_user_data ();
        public uint32 get_version ();
        public void destroy ();
        public Pantheon.Desktop.Panel get_panel (Wl.Surface surface);
        public Pantheon.Desktop.Widget get_widget (Wl.Surface surface);
        public Pantheon.Desktop.Greeter get_greeter (Wl.Surface surface);
        public Pantheon.Desktop.ExtendedBehavior get_extended_behavior (Wl.Surface surface);

    }
    [CCode (cheader_filename = "pantheon-desktop-shell-client-protocol.h", cname = "enum io_elementary_pantheon_panel_v1_anchor", cprefix="IO_ELEMENTARY_PANTHEON_PANEL_V1_ANCHOR_", has_type_id = false)]
    public enum Anchor {
        TOP,
        BOTTOM,
        LEFT,
        RIGHT,
    }

    [CCode (cheader_filename = "pantheon-desktop-shell-client-protocol.h", cname = "enum io_elementary_pantheon_panel_v1_hide_mode", cprefix="IO_ELEMENTARY_PANTHEON_PANEL_V1_HIDE_MODE_", has_type_id = false)]
    public enum HideMode {
        NEVER,
        MAXIMIZED_FOCUS_WINDOW,
        OVERLAPPING_FOCUS_WINDOW,
        OVERLAPPING_WINDOW,
        ALWAYS
    }

    [CCode (cheader_filename = "pantheon-desktop-shell-client-protocol.h", cname = "struct io_elementary_pantheon_panel_v1", cprefix = "io_elementary_pantheon_panel_v1_")]
    public class Panel : Wl.Proxy {
        [CCode (cheader_filename = "pantheon-desktop-shell-client-protocol.h", cname = "io_elementary_pantheon_panel_v1_interface")]
        public static Wl.Interface iface;
        public void set_user_data (void* user_data);
        public void* get_user_data ();
        public uint32 get_version ();
        public void destroy ();
        public void set_anchor (Pantheon.Desktop.Anchor anchor);
        public void focus ();
        public void set_size (int width, int height);
        public void set_hide_mode (Pantheon.Desktop.HideMode hide_mode);
    }

    [CCode (cheader_filename = "pantheon-desktop-shell-client-protocol.h", cname = "struct io_elementary_pantheon_widget_v1", cprefix = "io_elementary_pantheon_widget_v1_")]
    public class Widget : Wl.Proxy {
        [CCode (cheader_filename = "pantheon-desktop-shell-client-protocol.h", cname = "io_elementary_pantheon_widget_v1_interface")]
        public static Wl.Interface iface;
        public void set_user_data (void* user_data);
        public void* get_user_data ();
        public uint32 get_version ();
        public void destroy ();
    }

    [CCode (cheader_filename = "pantheon-desktop-shell-client-protocol.h", cname = "struct io_elementary_pantheon_greeter_v1", cprefix = "io_elementary_pantheon_greeter_v1_")]
    public class Greeter : Wl.Proxy {
        [CCode (cheader_filename = "pantheon-desktop-shell-client-protocol.h", cname = "io_elementary_pantheon_greeter_v1_interface")]
        public static Wl.Interface iface;
        public void set_user_data (void* user_data);
        public void* get_user_data ();
        public uint32 get_version ();
        public void destroy ();
        public void init ();
    }

    [CCode (cheader_filename = "pantheon-desktop-shell-client-protocol.h", cname = "struct io_elementary_pantheon_extended_behavior_v1", cprefix = "io_elementary_pantheon_extended_behavior_v1_")]
    public class ExtendedBehavior : Wl.Proxy {
        [CCode (cheader_filename = "pantheon-desktop-shell-client-protocol.h", cname = "io_elementary_pantheon_extended_behavior_v1_interface")]
        public static Wl.Interface iface;
        public void set_user_data (void* user_data);
        public void* get_user_data ();
        public uint32 get_version ();
        public void destroy ();
        public void set_keep_above ();
    }
}
