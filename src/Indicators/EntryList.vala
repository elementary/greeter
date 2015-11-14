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
    // The order in which the indicators are shown from left to right.
    private const string[] INDICATOR_ORDER = {
        Wingpanel.Indicator.KEYBOARD,
        Wingpanel.Indicator.SOUND,
        Wingpanel.Indicator.NETWORK,
        Wingpanel.Indicator.BLUETOOTH,
        Wingpanel.Indicator.PRINTER,
        Wingpanel.Indicator.SYNC,
        Wingpanel.Indicator.POWER,
        Wingpanel.Indicator.MESSAGES,
        Wingpanel.Indicator.SESSION
    };

    public signal void list_changed ();

    public async void resort () {
        message ("Resorting indicators...");

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

    private int get_item_index (string item) {
        for (int i = 0; i < INDICATOR_ORDER.length; i++) {
            if (INDICATOR_ORDER[i].down () == item)
                return i;
        }

        return 0;
    }
}
