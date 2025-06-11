[CCode (cheader_filename = "gdk/gdkwayland.h")]
namespace Gdk.Wayland {
    [CCode (type_id = "GDK_TYPE_WAYLAND_WINDOW", type_check_function = "GDK_IS_WAYLAND_WINDOW")]
    public class Window : Gdk.Window {
        protected Window ();

        public unowned Wl.Surface get_wl_surface ();
    }

    [CCode (type_id = "GDK_TYPE_WAYLAND_DISPLAY", type_check_function = "GDK_IS_WAYLAND_DISPLAY")]
    public class Display : Gdk.Display {
        protected Display ();

        public unowned Wl.Display get_wl_display ();
    }
}
