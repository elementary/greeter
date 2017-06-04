// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
* Copyright (c) 2011-2017 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

public class Indicators.IndicatorBar : Gtk.MenuBar {
    private EntryList entry_list;
    private PopoverManager popover_manager;

    public IndicatorBar () {
        Object (
            border_width: 0,
            can_focus: true,
            halign: Gtk.Align.END
        );
    }

    construct {
        Wingpanel.IndicatorManager.get_default ().initialize (Wingpanel.IndicatorManager.ServerType.GREETER);

        entry_list = new EntryList ();
        popover_manager = new PopoverManager ();

        if (Wingpanel.IndicatorManager.get_default ().has_indicators ()) {
            load_indicators.begin (() => {
                entry_list.resort.begin (() => {
                    update_bar ();

                    connect_signals ();
                });
            });
        }

        get_style_context ().add_class (StyleClass.PANEL);
    }

    private async void load_indicators () {
        message ("Loading indicators...");

        var indicators = Wingpanel.IndicatorManager.get_default ().get_indicators ();

        foreach (Wingpanel.Indicator indicator in indicators) {
            register_indicator (indicator);
        }
    }

    private bool register_indicator (Wingpanel.Indicator indicator) {
        message ("Loading indicator %s...", indicator.code_name);

        var indicator_entry = new IndicatorEntry (indicator);
        indicator_entry.visibility_changed.connect (update_bar);

        if (!entry_list.add (indicator_entry)) {
            warning ("Registering entry for indicator %s failed.", indicator.code_name);

            return false;
        }

        var indicator_popover = indicator_entry.get_popover ();

        if (!popover_manager.add (indicator_popover)) {
            warning ("Registering popover for indicator %s failed.", indicator.code_name);

            return false;
        }

        return true;
    }

    private void update_bar () {
        clear_bar ();

        foreach (IndicatorEntry entry in entry_list) {
            if (entry.get_is_visible ())
                append (entry);
        }

        show_all ();
    }

    private void connect_signals () {
        entry_list.list_changed.connect (update_bar);

        Wingpanel.IndicatorManager.get_default ().indicator_added.connect ((indicator) => {
            if (!register_indicator (indicator))
                return;

            message ("Requesting resort because indicator %s has been added.", indicator.code_name);

            entry_list.resort.begin ();
        });
    }

    private void clear_bar () {
        var children = get_children ();

        foreach (var child in children)
            remove (child);
    }
}
