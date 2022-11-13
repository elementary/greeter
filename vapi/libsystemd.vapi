[CCode (cheader_filename = "systemd/sd-bus.h")]
namespace Systemd {
    [CCode (cname="sd_bus_set_allow_interactive_authorization")]
    public int set_allow_interactive_authorization(Bus bus, int interactive);

    [CCode (cname = "sd_bus_new")]
	public int newv (out Bus bus);

    [CCode (cname = "sd_bus_default_system")]
	public int default_system (out Bus bus);

    [CCode (cname = "sd_bus_default_user")]
	public int default_user (out Bus bus);

    [Compact]
    [CCode (cname = "sd_bus", cprefix = "sd_", free_function = "sd_bus_unref")]
	public class Bus {
        [CCode (cname = "sd_bus_new")]
        public Bus ();

        [CCode (cname="sd_bus_set_allow_interactive_authorization")]
        public int set_allow_interactive_authorization(int interactive);
	}
}

