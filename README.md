# Greeter

[![Translation status](https://l10n.elementary.io/widgets/desktop/-/greeter/svg-badge.svg)](https://l10n.elementary.io/engage/desktop/?utm_source=widget)

![Screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* gnome-settings-daemon >= 3.27
* libgdk-pixbuf2.0-dev
* libgranite-dev >= 5.5.0
* libgtk-3-dev
* libhandy-1-dev >= 0.90.0
* liblightdm-gobject-1-dev >= 1.30.0
* libmutter-13-dev
* libx11-dev
* meson
* valac
* gettext (provides `msgfmt`)
* libgnome-desktop-3-dev

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
