/*
* Copyright (c) 2016-2017 elementary LLC. (https://github.com/elementary/greeter)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA.
*
*/

public class UserLogin : LoginOption {

    public LightDM.User lightdm_user { get; private set; }

    private const string ENV_VAR_NAME = "XDG_CONFIG_HOME";
    private const string ENV_VAR_SUFFIX = ".config";

    public UserLogin (int index, LightDM.User user) {
        base (index);
        this.lightdm_user = user;

        string? xdg_config_home_real = Environment.get_variable (UserLogin.ENV_VAR_NAME);
        string xdg_config_home_spoof = Path.build_path (Path.DIR_SEPARATOR_S,
                                        user.home_directory, UserLogin.ENV_VAR_SUFFIX);

        Environment.set_variable (UserLogin.ENV_VAR_NAME, xdg_config_home_spoof, true);

        try {
            string gsettings_result;

            Process.spawn_command_line_sync ("gsettings get org.gnome.desktop.interface clock-format",
                                                out gsettings_result);

            clock_format = gsettings_result;
        } catch (SpawnError e) {
            debug ("Could not spawn gsettings: %s", e.message);
        }

        if (xdg_config_home_real == null) {
            Environment.unset_variable (UserLogin.ENV_VAR_NAME);
        } else {
            Environment.set_variable (UserLogin.ENV_VAR_NAME, xdg_config_home_real, true);
        }
    }

    public override string? avatar_path {
        get {
            return lightdm_user.image;
        }
    }

    public override string background {
        get {
            return lightdm_user.background;
        }
    }

    public override string display_name {
        get {
            return lightdm_user.display_name;
        }
    }

    public override string name {
        get {
            return lightdm_user.name;
        }
    }

    public override bool logged_in {
        get {
            return lightdm_user.logged_in;
        }
    }

    public override string session {
        get {
            return lightdm_user.session;
        }
    }
}
