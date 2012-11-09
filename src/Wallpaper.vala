using Clutter;

public class Wallpaper : Group
{
	public Clutter.Texture background;   //both not added to this box but to stage
	public Clutter.Texture background_s; //double buffered!
	
	public Wallpaper ()
	{
		background = new Clutter.Texture ();
		background_s = new Clutter.Texture ();
		background.opacity = 230;
		background_s.opacity = 230;
		background.load_async = true;
		background_s.load_async = true;
		try {
			background.set_from_file (get_default ());
		} catch (Error e) { warning (e.message); }
	}
	
	string get_default ()
	{
		return new GLib.Settings ("org.pantheon.desktop.greeter").get_string ("default-wallpaper");
	}

	bool second = false;
	public void set_wallpaper (string? path) {
		var file = (path == null || path == "") ? 
			get_default () : path;
		if (!File.new_for_path (file).query_exists ()) {
			warning ("File %s does not exist!\n", file);
			return;
		}
		
		var top = second ? background : background_s;
		var bot = second ? background_s : background;
		
		if (file == top.filename)
			return;
		
		top.detach_animation ();
		bot.detach_animation ();
		
		try {
			bot.set_from_file (file);
		} catch (Error e) { warning (e.message); }
		
		ulong lambda = 0;
		lambda = bot.load_finished.connect (() => {
			bot.visible = true;
			bot.opacity = 230;
			top.animate (Clutter.AnimationMode.LINEAR, 300, opacity:0).completed.connect (() => {
				top.visible = false;
				top.get_parent ().set_child_above_sibling (bot, top);
			});
			
			bot.disconnect (lambda);
		});
		
		second = !second;
	}
	
}
