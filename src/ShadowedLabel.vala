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
			if (value == _label && buffer != null)
				return;
			
			_label = value;
			
			buffer = new Granite.Drawing.BufferSurface ((int)width, (int)height);
			var layout = Pango.cairo_create_layout (buffer.context);
			layout.set_markup (label, -1);
			
			buffer.context.move_to (10, 0);
			buffer.context.set_source_rgba (0, 0, 0, 1);
			Pango.cairo_show_layout (buffer.context, layout);
			Pango.cairo_show_layout (buffer.context, layout);
			buffer.exponential_blur (10);
			Pango.cairo_show_layout (buffer.context, layout);
			Pango.cairo_show_layout (buffer.context, layout);
			buffer.exponential_blur (5);
			buffer.context.set_source_rgba (1, 1, 1, 1);
			Pango.cairo_show_layout (buffer.context, layout);
			
			content.invalidate ();
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
		
		if (buffer == null)
			label = label;
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
		width = 500;
		height = 150;
		
		update_time ();
		Clutter.Threads.Timeout.add (5000, update_time);
	}
	
	bool update_time ()
	{
		var date = new GLib.DateTime.now_local ();
		label = date.format (
			"<span face='Open Sans Light' font='24'>"+
			/*Date display, see http://unstable.valadoc.org/#!api=glib-2.0/GLib.DateTime.format for more details*/
			_("%A, %B %eth")+
			"</span>\n<span face='Raleway' font='72'>"+
			/*Time display, see http://unstable.valadoc.org/#!api=glib-2.0/GLib.DateTime.format for more details*/
			_("%l:%M %p")+
			"</span>");
		
		return true;
	}
}
