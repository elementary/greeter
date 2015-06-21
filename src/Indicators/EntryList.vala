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

public class Indicators.EntryList : Gee.ArrayList<IndicatorEntry> {
    public signal void list_changed ();

    public EntryList () {
        connect_signals ();
    }

    public override bool add (IndicatorEntry entry) {
        bool added = base.add (entry);

        if (added)
            resort.begin ();

        return added;
    }

    private async void resort () {
        this.sort ((a, b) => {
            if (a == null)
                return (b == null) ? 0 : -1;

            if (b == null)
                return 1;

            string a_name = a.get_code_name ().down ();
            string b_name = b.get_code_name ().down ();

            int order = get_item_index (a_name) - get_item_index (b_name);

            if (order == 0)
                order = strcmp (a_name, b_name);

            return order.clamp (-1, 1);
        });

        list_changed ();
    }

    private void connect_signals () {
        WingpanelSettings.get_default ().notify["order"].connect (() => {
            resort ();
        });
    }

    private int get_item_index (string item) {
        var items = WingpanelSettings.get_default ().order;

        for (int i = 0; i < items.length; i++) {
            if (items[i].down () == item)
                return i;
        }

        return 0;
    }
}
