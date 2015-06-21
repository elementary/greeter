// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2015 elementary Developers

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/


public class Indicators.IndicatorEntry : Gtk.MenuItem {
    private Gtk.Widget display_widget;
    private Gtk.Widget? indicator_widget = null;

    private Gtk.Revealer revealer;

    private IndicatorPopover popover;
    private Wingpanel.Indicator base_indicator;

    public signal void visibility_changed ();

    public IndicatorEntry (Wingpanel.Indicator base_indicator) {
        this.base_indicator = base_indicator;
        this.add_events (Gdk.EventMask.SCROLL_MASK);
        this.get_style_context ().add_class (StyleClass.COMPOSITED_INDICATOR);

        display_widget = base_indicator.get_display_widget ();
        display_widget.margin_start = 4;
        display_widget.margin_end = 4;

        if (display_widget == null)
            return;

        revealer = new Gtk.Revealer ();
        revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;

        revealer.add (display_widget);

        indicator_widget = base_indicator.get_widget ();

        if (indicator_widget != null) {
            popover = new IndicatorPopover (indicator_widget);
            popover.relative_to = this;
        }

        this.add (revealer);

        set_reveal (base_indicator.visible);

        connect_signals ();
    }

    public string get_code_name () {
        return base_indicator.code_name;
    }

    public bool get_is_visible () {
        return base_indicator.visible;
    }

    private void connect_signals () {
        base_indicator.notify["visible"].connect (() => {
            request_resort ();

            set_reveal (base_indicator.visible);
        });

        base_indicator.close.connect (() => {
            if (indicator_widget != null)
                popover.hide ();
        });

        this.scroll_event.connect ((e) => {
            display_widget.scroll_event (e);

            return Gdk.EVENT_STOP;
        });

        this.button_press_event.connect ((e) => {
            if (indicator_widget != null) {
                if ((e.button == Gdk.BUTTON_PRIMARY || e.button == Gdk.BUTTON_SECONDARY) && e.type == Gdk.EventType.BUTTON_PRESS) {
                    if (popover.get_visible ())
                        popover.hide ();
                    else
                        popover.show_all ();

                    return Gdk.EVENT_STOP;
                }
            }

            display_widget.button_press_event (e);

            return Gdk.EVENT_PROPAGATE;
        });
    }

    private void set_reveal (bool reveal) {
        if (!reveal && popover.get_visible ())
            popover.hide ();

        revealer.set_reveal_child (reveal);
    }

    private void request_resort () {
        if (base_indicator.visible) {
            visibility_changed ();
        } else {
            Timeout.add (revealer.transition_duration, () => {
                visibility_changed ();

                return false;
            });
        }
    }
}
