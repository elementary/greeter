# Greeter

[![Translation status](https://l10n.elementary.io/widgets/desktop/-/greeter/svg-badge.svg)](https://l10n.elementary.io/engage/desktop/?utm_source=widget)

![Screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* gnome-settings-daemon >= 3.27
* libaccountsservice-dev
* libgdk-pixbuf2.0-dev
* libgranite-dev
* libgtk-3-dev
* liblightdm-gobject-1-dev
* libmutter
* libwingpanel-2.0-dev
* libx11-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install

## Testing & Debugging

Run LightDM in test mode with Xephyr:

    lightdm --test-mode --debug

You can then find the debug log in `~/.cache/lightdm/log`
