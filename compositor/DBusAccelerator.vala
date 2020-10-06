/*
 * Copyright 2015 Nicolas Bruguier, Corentin Noël
 * Copyright 2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace GreeterCompositor {
    /**
     * ActionMode:
     * @NONE: block action
     * @NORMAL: allow action when in window mode, e.g. when the focus is in an application window
     * @OVERVIEW: allow action while the overview is active
     * @LOCK_SCREEN: allow action when the screen is locked, e.g. when the screen shield is shown
     * @UNLOCK_SCREEN: allow action in the unlock dialog
     * @LOGIN_SCREEN: allow action in the login screen
     * @SYSTEM_MODAL: allow action when a system modal dialog (e.g. authentification or session dialogs) is open
     * @LOOKING_GLASS: allow action in looking glass
     * @POPUP: allow action while a shell menu is open
     */
    [Flags]
    public enum ActionMode {
        NONE = 0,
        NORMAL = 1 << 0,
        OVERVIEW = 1 << 1,
        LOCK_SCREEN = 1 << 2,
        UNLOCK_SCREEN = 1 << 3,
        LOGIN_SCREEN = 1 << 4,
        SYSTEM_MODAL = 1 << 5,
        LOOKING_GLASS = 1 << 6,
        POPUP = 1 << 7,
    }

    public struct Accelerator {
        public string name;
        public ActionMode flags;
#if HAS_MUTTER332
        public Meta.KeyBindingFlags grab_flags;
#endif
    }

    [Compact]
    private class GrabbedAccelerator {
        public Accelerator accelerator;
        public uint action;
    }

    [DBus (name="org.gnome.Shell")]
    public class DBusAccelerator {
        static DBusAccelerator? instance;

        [DBus (visible = false)]
        public static unowned DBusAccelerator init (WindowManager wm) {
            if (instance == null)
                instance = new DBusAccelerator (wm);

            return instance;
        }

        public signal void accelerator_activated (uint action, GLib.HashTable<string, Variant> parameters);

        WindowManager wm;
        GLib.List<GrabbedAccelerator> grabbed_accelerators;

        DBusAccelerator (WindowManager _wm) {
            wm = _wm;
            grabbed_accelerators = new GLib.List<GrabbedAccelerator> ();

#if HAS_MUTTER330
            wm.get_display ().accelerator_activated.connect (on_accelerator_activated);
#else
            wm.get_screen ().get_display ().accelerator_activated.connect (on_accelerator_activated);
#endif
        }

#if HAS_MUTTER334
        private void on_accelerator_activated (uint action, Clutter.InputDevice device, uint timestamp) {
#else
        private void on_accelerator_activated (uint action, uint device_id, uint timestamp) {
#endif
            foreach (unowned GrabbedAccelerator accel in grabbed_accelerators) {
                if (accel.action == action) {
                    if (ActionMode.LOGIN_SCREEN in accel.accelerator.flags) {
                        var parameters = new GLib.HashTable<string, Variant> (null, null);
#if HAS_MUTTER334
                        parameters.set ("device-id", new Variant.uint32 (device.id));
#else
                        parameters.set ("device-id", new Variant.uint32 (device_id));
#endif
                        parameters.set ("timestamp", new Variant.uint32 (timestamp));

                        accelerator_activated (action, parameters);
                    }

                    return;
                }
            }
        }

        private uint grab_accelerator (Accelerator accelerator) {
            foreach (unowned GrabbedAccelerator accel in grabbed_accelerators) {
                if (accel.accelerator.name == accelerator.name) {
                    return accel.action;
                }
            }

#if HAS_MUTTER332
            uint action = wm.get_display ().grab_accelerator (accelerator.name, accelerator.grab_flags);
#elif HAS_MUTTER330
            uint action = wm.get_display ().grab_accelerator (accelerator.name);
#else
            uint action = wm.get_screen ().get_display ().grab_accelerator (accelerator.name);
#endif

            if (action > 0) {
                var accel = new GrabbedAccelerator ();
                accel.action = action;
                accel.accelerator = accelerator;
                grabbed_accelerators.append ((owned)accel);
            }

            return action;
        }

        public uint[] grab_accelerators (Accelerator[] accelerators) throws GLib.Error {
            uint[] actions = {};

            foreach (unowned Accelerator accelerator in accelerators) {
                actions += grab_accelerator (accelerator);
            }

            return actions;
        }

        public bool ungrab_accelerator (uint action) throws GLib.Error {
            foreach (unowned GrabbedAccelerator accel in grabbed_accelerators) {
                if (accel.action == action) {
#if HAS_MUTTER330
                    bool ret = wm.get_display ().ungrab_accelerator (action);
#else
                    bool ret = wm.get_screen ().get_display ().ungrab_accelerator (action);
#endif
                    grabbed_accelerators.remove (accel);
                    return ret;
                }
            }

            return false;
        }

#if HAS_MUTTER334
        public bool ungrab_accelerators (uint[] actions) throws GLib.Error {
            foreach (uint action in actions) {
                ungrab_accelerator (action);
            }

            return true;
        }
#endif

        [DBus (name = "ShowOSD")]
        public void show_osd (GLib.HashTable<string, Variant> parameters) throws GLib.Error {
            int32 monitor_index = -1;
            if (parameters.contains ("monitor"))
                monitor_index = parameters["monitor"].get_int32 ();
            string icon = "";
            if (parameters.contains ("icon"))
                icon = parameters["icon"].get_string ();
            string label = "";
            if (parameters.contains ("label"))
                label = parameters["label"].get_string ();
            int32 level = 0;
#if HAS_MUTTER334
            if (parameters.contains ("level")) {
                var double_level = parameters["level"].get_double ();
                level = (int)(double_level * 100);
            }
#else
            if (parameters.contains ("level"))
                level = parameters["level"].get_int32 ();
#endif

            MediaFeedback.send (icon, level);
        }
    }
}
