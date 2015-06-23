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

public class Indicators.IndicatorBar : GtkClutter.Actor {
    private EntryList entry_list;

    private PopoverManager popover_manager;

    private Gtk.MenuBar menu_bar;

    public IndicatorBar () {
        Wingpanel.IndicatorManager.get_default ().initialize (Wingpanel.IndicatorManager.ServerType.GREETER);

        entry_list = new EntryList ();
        popover_manager = new PopoverManager ();

        build_ui ();

        if (Wingpanel.IndicatorManager.get_default ().has_indicators ()) {
            load_indicators.begin (() => {
                entry_list.resort.begin (() => {
                    update_bar ();

                    connect_signals ();
                });
            });
        }
    }

    private void build_ui () {
        var container_widget = (Gtk.Container)this.get_widget ();

        menu_bar = new Gtk.MenuBar ();
        menu_bar.can_focus = true;
        menu_bar.border_width = 0;
        menu_bar.override_background_color (Gtk.StateFlags.NORMAL, {0, 0, 0, 0});
        menu_bar.get_style_context ().add_class (StyleClass.PANEL);
        menu_bar.halign = Gtk.Align.END;

        container_widget.add (menu_bar);
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
                menu_bar.append (entry);
        }

        menu_bar.show_all ();
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
        var children = menu_bar.get_children ();

        foreach (var child in children)
            menu_bar.remove (child);
    }
}
