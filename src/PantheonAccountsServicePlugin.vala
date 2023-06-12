[DBus (name = "io.elementary.pantheon.AccountsService")]
interface Pantheon.AccountsService : Object {
    public abstract string time_format { owned get; set; }

    public abstract int prefers_accent_color { get; set; }

    [DBus (name = "SleepInactiveACTimeout")]
    public abstract int sleep_inactive_ac_timeout { get; set; }
    [DBus (name = "SleepInactiveACType")]
    public abstract int sleep_inactive_ac_type { get; set; }

    public abstract int sleep_inactive_battery_timeout { get; set; }
    public abstract int sleep_inactive_battery_type { get; set; }
}

[DBus (name = "io.elementary.SettingsDaemon.AccountsService")]
interface Pantheon.SettingsDaemon.AccountsService : Object {
    public struct KeyboardLayout {
        public string backend;
        public string name;
    }

    public abstract KeyboardLayout[] keyboard_layouts { owned get; set; }
    public abstract uint active_keyboard_layout { get; set; }

    public abstract bool left_handed { get; set; }
    public abstract bool mouse_natural_scroll { get; set; }
    public abstract bool touchpad_natural_scroll { get; set; }
    public abstract double mouse_speed { get; set; }
    public abstract double touchpad_speed { get; set; }
    public abstract int accel_profile { owned get; set; }
}
