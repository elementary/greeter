
public class PantheonGreeter : Gtk.Window
{
	LightDM.Greeter greeter;
	GtkClutter.Embed clutter;
	LoginBox loginbox;
	Clutter.Rectangle fadein;
	Clutter.Actor greeterbox;
	LightDM.UserList users;
	Clutter.Actor name_container;
	TimeLabel time;
	Indicators indicators;
	
	Settings settings;
	
	int _current_user = 0;
	int current_user {
		get {
			return _current_user;
		}
		set {
			_current_user = value;
			name_container.animate (Clutter.AnimationMode.EASE_OUT_QUAD, 400, y:loginbox.y - _current_user * 200.0f);
			loginbox.set_user (users.users.nth_data (_current_user));
		}
	}
	
	public PantheonGreeter ()
	{
		settings = new Settings ("org.pantheon.desktop.greeter");
		
		greeter = new LightDM.Greeter ();
		clutter = new GtkClutter.Embed ();
		loginbox = new LoginBox (greeter);
		fadein = new Clutter.Rectangle.with_color ({0, 0, 0, 255});
		greeterbox = new Clutter.Actor ();
		users = LightDM.UserList.get_instance ();
		name_container = new Clutter.Actor ();
		time = new TimeLabel ();
		indicators = new Indicators (loginbox, settings);
		
		greeter.show_message.connect (wrong_pw);
		greeter.show_prompt.connect (send_pw);
		greeter.authentication_complete.connect (authenticated);
		
		loginbox.login.clicked.connect (authenticate);
		
		/*build up UI*/
		clutter.add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);
		
		var stage = clutter.get_stage () as Clutter.Stage;
		stage.background_color = {0, 0, 0, 255};
		
		greeterbox.add_child (loginbox.background);
		greeterbox.add_child (loginbox.background_s);
		greeterbox.add_child (time);
		greeterbox.add_child (indicators);
		greeterbox.add_child (name_container);
		greeterbox.add_child (loginbox);
		greeterbox.add_effect_with_name ("mirror", new MirrorEffect ());
		greeterbox.depth = -1500;
		
		stage.add_child (greeterbox);
		
		greeterbox.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
		greeterbox.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.HEIGHT, 0));
		loginbox.background.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
		loginbox.background.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.HEIGHT, 0));
		loginbox.background_s.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
		loginbox.background_s.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.HEIGHT, 0));
		indicators.add_constraint (new Clutter.BindConstraint (greeterbox, Clutter.BindCoordinate.WIDTH, 0));
		
		reposition ();
		get_screen ().monitors_changed.connect (reposition);
		
		loginbox.width = 500;
		loginbox.height = 250;
		loginbox.x = 100;
		name_container.x = loginbox.x;
		name_container.y = loginbox.y - current_user * 130.0f;
		
		clutter.key_release_event.connect (keyboard_navigation);
		
		add (clutter);
		show_all ();
		
		/*get the names together*/
		for (var i = 0; i < users.users.length () + 1; i++) {
			if (i == users.users.length () && !greeter.has_guest_account_hint)
				continue;
			
			ShadowedLabel label = new ShadowedLabel ("");
			if (i == users.users.length ())
				label.label =  ("<span face='Open Sans Light' font='24'>"+_("Guest session")+"</span>");
			else
				label.label = (LoginBox.get_user_markup (users.users.nth_data (i)));
			
			label.height = 75;
			label.width = loginbox.width - 100;
			label.x = 135;
			label.y = i * 200 + label.height;
			label.reactive = true;
			label.button_release_event.connect ( (e) => {
				var idx = name_container.get_children ().index (e.source);
				if (idx == -1)
					return false;
				current_user = idx;
				
				return true;
			});
			
			name_container.add_child (label);
		}
		
		/*opening animation*/
		var d_left  = new Clutter.Rectangle.with_color ({0, 0, 0, 255});
		var d_right = new Clutter.Rectangle.with_color ({0, 0, 0, 255});
		
		stage.add_child (d_left);
		stage.add_child (d_right);
		
		d_left.width = d_right.width = stage.width / 2;
		d_left.height = d_right.height = stage.height;
		d_right.x = stage.width / 2;
		
		d_left.animate  (Clutter.AnimationMode.EASE_IN_CUBIC, 750, x:-d_left.width);
		d_right.animate (Clutter.AnimationMode.EASE_IN_CUBIC, 750, x:stage.width);
		
		greeterbox.animate (Clutter.AnimationMode.EASE_OUT_CUBIC, 1000, depth:0.0f).completed.connect ( () => {
			greeterbox.remove_effect_by_name ("mirror");
		});
		
		/*start*/
		try {
			greeter.connect_sync ();
		} catch (Error e) {
			warning ("Couldn't connect: %s", e.message);
			Posix.exit (Posix.EXIT_FAILURE);
		}
		
		var last_user = settings.get_string ("last-user");
		if (last_user == "")
			current_user = 0;
		else {
			for (var i = 0; i < users.users.length (); i++) {
				if (users.users.nth_data (i).name == last_user)
					current_user = i;
			}
		}
		
		indicators.bar.grab_focus ();
		loginbox.password.grab_focus ();
	}
	
	void reposition ()
	{
		Gdk.Rectangle geometry;
		get_screen ().get_monitor_geometry (get_screen ().get_primary_monitor (), out geometry);
		
		resize (geometry.width, geometry.height);
		move (geometry.x, geometry.y);
		
		loginbox.y = Math.floorf (geometry.height / 2 - loginbox.height / 2);
		name_container.y = loginbox.y;
		
		time.x = geometry.width - time.width - (geometry.width > 1500 ? 100 : 10);
		time.y = geometry.height / 2 - time.height / 2;
	}
	
	bool keyboard_navigation (Gdk.EventKey e)
	{
		int new_user = current_user;
		switch (e.keyval) {
			case Gdk.Key.Up:
				new_user --;
				if (new_user - 1 < 0)
					new_user = 0;
				break;
			case Gdk.Key.Down:
				var n_user = users.users.length ();
				new_user ++;
				
				var sum = (int)(greeter.has_guest_account_hint ? n_user + 1 : n_user);
				if (new_user >= sum)
					new_user = sum - 1;
				break;
			default:
				return false;
		}
		
		if (new_user != current_user)
			current_user = new_user;
		
		return true;
	}
	
	void authenticate ()
	{
		loginbox.working = true;
		if (loginbox.current_user == null)
			greeter.authenticate_as_guest ();
		else
			greeter.authenticate (loginbox.current_user.name);
	}
	
	void wrong_pw (string text, LightDM.MessageType type)
	{
		loginbox.wrong_pw ();
	}
	
	void send_pw (string text, LightDM.PromptType type) {
		greeter.respond (loginbox.password.text);
	}
	
	void authenticated ()
	{
		loginbox.working = false;
		
		settings.set_string ("last-user", loginbox.current_user.name);
		
		if (greeter.is_authenticated) {
			fadein.show ();
			fadein.animate (Clutter.AnimationMode.EASE_OUT_QUAD, 200, opacity:255);
			try {
				greeter.start_session_sync (loginbox.current_session);
			} catch (Error e) { warning (e.message); }
			Gtk.main_quit ();
		} else {
			loginbox.wrong_pw ();
		}
	}
}

public static int main (string [] args) {
	
	var init = GtkClutter.init (ref args);
	if (init != Clutter.InitError.SUCCESS)
		error ("Clutter could not be intiailized");
	
	/*some settings*/
	Intl.setlocale (LocaleCategory.ALL, "");
	Intl.bind_textdomain_codeset ("pantheon-greeter", "UTF-8");
	Intl.textdomain ("pantheon-greeter");
	
	Gdk.get_default_root_window ().set_cursor (new Gdk.Cursor (Gdk.CursorType.LEFT_PTR));
	
	var settings = Gtk.Settings.get_default ();
	settings.gtk_theme_name = "elementary";
	settings.gtk_icon_theme_name = "elementary";
	settings.gtk_font_name = "Droid Sans";
	settings.gtk_xft_dpi= (int) (1024 * 96);
	settings.gtk_xft_antialias = 1;
	settings.gtk_xft_hintstyle = "hintslight";
	settings.gtk_xft_rgba = "rgb";
	settings.gtk_cursor_blink = true;
	
	
	new PantheonGreeter ();
	
	Gtk.main ();
	
	return Posix.EXIT_SUCCESS;
}

