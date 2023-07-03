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

    public struct XkbOption {
        public string option;
    }

    public abstract KeyboardLayout[] keyboard_layouts { owned get; set; }
    public abstract uint active_keyboard_layout { get; set; }
    public abstract XkbOption[] xkb_options { owned get; set; }

    public abstract bool left_handed { get; set; }
    public abstract int accel_profile { get; set; }

    public abstract bool mouse_natural_scroll { get; set; }
    public abstract double mouse_speed { get; set; }

    public abstract int touchpad_click_method { get; set; }
    public abstract bool touchpad_disable_while_typing { get; set; }
    public abstract bool touchpad_edge_scrolling { get; set; }
    public abstract bool touchpad_natural_scroll { get; set; }
    public abstract int touchpad_send_events { get; set; }
    public abstract double touchpad_speed { get; set; }
    public abstract bool touchpad_tap_to_click { get; set; }
    public abstract bool touchpad_two_finger_scrolling { get; set; }

    public abstract bool cursor_blink { get; set; }
    public abstract int cursor_blink_time { get; set; }
    public abstract int cursor_blink_timeout { get; set; }
    public abstract int cursor_size { get; set; }
    public abstract bool locate_pointer { get; set; }
    public abstract double text_scaling_factor { get; set; }
}
