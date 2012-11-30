using Clutter;

public class ShadowedLabel : Actor
{
	Granite.Drawing.BufferSurface buffer;
	
	string _label = "";
	public string label {
		get {
			return _label;
		}
		set {
			if (value == _label)
				return;
			
			_label = value;
			
			var l = new Pango.Layout (Pango.cairo_font_map_get_default ().create_context ());
			l.set_markup (label, -1);
			Pango.Rectangle ink, log;
			l.get_extents (out ink, out log);
			width = Math.floorf (log.width / Pango.SCALE + 20);
			height = Math.floorf (log.height / Pango.SCALE);
		}
	}
	
	public ShadowedLabel (string _label)
	{
		content = new Canvas ();
		(content as Canvas).draw.connect (draw);
		
		notify["width"].connect  (() => {(content as Canvas).set_size ((int)width, (int)height);buffer = null;});
		notify["height"].connect (() => {(content as Canvas).set_size ((int)width, (int)height);buffer = null;});
		
		label = _label;
	}
	
	bool draw (Cairo.Context cr)
	{
		cr.set_operator (Cairo.Operator.CLEAR);
		cr.paint ();
		cr.set_operator (Cairo.Operator.OVER);
		
		var buffer = new Granite.Drawing.BufferSurface ((int)width, (int)height);
		var layout = Pango.cairo_create_layout (buffer.context);
		layout.set_markup (label, -1);
		
		buffer.context.move_to (0, 1);
		buffer.context.set_source_rgba (0, 0, 0, 1);
		Pango.cairo_show_layout (buffer.context, layout);
		buffer.exponential_blur (3);

		buffer.context.move_to (0, 0);
		buffer.context.set_source_rgba (1, 1, 1, 1);
		Pango.cairo_show_layout (buffer.context, layout);
		
		cr.set_source_surface (buffer.surface, 0, 0);
		cr.paint ();
		
		return true;
	}
}

public class TimeLabel : ShadowedLabel
{
	
	public TimeLabel ()
	{
		base ("");
		
		update_time ();
		Clutter.Threads.Timeout.add (5000, update_time);
	}
	
	bool update_time ()
	{
		var date = new GLib.DateTime.now_local ();
		
		/*Date display, see http://unstable.valadoc.org/#!api=glib-2.0/GLib.DateTime.format for more details. 
		  %v is added here to provide the English date suffixes th, nd and so on*/
		var day_format = _("%A, %B %e%v");
		/*Time display, see http://unstable.valadoc.org/#!api=glib-2.0/GLib.DateTime.format for more details*/
		var time_format = _("%l:%M %p");
		
		//there is no %v, but we need one, so we add one
		var num = date.get_day_of_month ();
		day_format = day_format.replace ("%v", get_english_number_suffix (num));
		
		label = date.format (
			"<span face='Open Sans Light' font='24'>"+
			day_format+
			"</span>\n<span face='Raleway' weight='100' font='72'>"+
			time_format+
			"</span>");
		
		return true;
	}
	
	/**
	 * Utility to get the English number suffix
	 * @param number The number to find the the suffix for
	 * @return The according English suffix
	 **/
	string get_english_number_suffix (int number)
	{
		number %= 100;
		
		if (number > 20)
			number %= 10;
		
		switch (number) {
		case 1:
			return "st";
		case 2:
			return "nd";
		case 3:
			return "rd";
		case 11:
		case 12:
		case 13:
		default:
			return "th";
		}
	}
}
