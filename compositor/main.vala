/*
 * Copyright 2012 Tom Beckmann, Rico Tzschichholz
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
    const OptionEntry[] OPTIONS = {
        { "version", 0, OptionFlags.NO_ARG, OptionArg.CALLBACK, (void*) print_version, "Print version", null },
        { null }
    };

    void print_version () {
        stdout.printf ("GreeterCompositor %s\n", Constants.VERSION);
        Meta.exit (Meta.ExitCode.SUCCESS);
    }

    public static int main (string[] args) {
        if (GLib.Environment.get_variable ("DESKTOP_SESSION") != "installer") {
            // Ensure we present ourselves as Pantheon so we pick up the right GSettings
            // overrides
            GLib.Environment.set_variable ("XDG_CURRENT_DESKTOP", "Pantheon", true);
        }

        var ctx = new Meta.Context ("Mutter(GreeterCompositor)");
        ctx.add_option_entries (GreeterCompositor.OPTIONS, Constants.GETTEXT_PACKAGE);
        try {
            ctx.configure (ref args);
        } catch (Error e) {
            stderr.printf ("Error initializing: %s\n", e.message);
            return Posix.EXIT_FAILURE;
        }

        ctx.set_plugin_gtype (typeof (GreeterCompositor.WindowManager));

        try {
            ctx.setup ();
        } catch (Error e) {
            stderr.printf ("Failed to setup: %s\n", e.message);
            return Posix.EXIT_FAILURE;
        }

        typeof (GreeterCompositor.Utils).class_ref ();
        try {
            ctx.start ();
        } catch (Error e) {
            stderr.printf ("Failed to start: %s\n", e.message);
            return Posix.EXIT_FAILURE;
        }

        try {
            ctx.run_main_loop ();
        } catch (Error e) {
            stderr.printf ("Greeter Compositor terminated with a failure: %s\n", e.message);
            return Posix.EXIT_FAILURE;
        }

        return Posix.EXIT_SUCCESS;
    }
}
