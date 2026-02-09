namespace NovaDock {
    public class HotkeyCaptureButton : Gtk.Button {
        public string hotkey { get; set; default = ""; }
        private bool listening = false;
        
        public signal void hotkey_changed(string new_hotkey);
        
        public HotkeyCaptureButton(string initial_hotkey = "") {
            this.hotkey = initial_hotkey;
            update_label();
            
            this.clicked.connect(on_clicked);
            this.key_press_event.connect(on_key_press);
            this.focus_out_event.connect(on_focus_out);
        }
        
        private void on_clicked() {
            if (!listening) {
                listening = true;
                update_label();
                grab_focus();
            }
        }
        
        private bool on_key_press(Gdk.EventKey event) {
            if (!listening) {
                return false;
            }
            
            // Ignore modifier-only presses
            if (event.keyval == Gdk.Key.Control_L || event.keyval == Gdk.Key.Control_R ||
                event.keyval == Gdk.Key.Alt_L || event.keyval == Gdk.Key.Alt_R ||
                event.keyval == Gdk.Key.Shift_L || event.keyval == Gdk.Key.Shift_R ||
                event.keyval == Gdk.Key.Super_L || event.keyval == Gdk.Key.Super_R ||
                event.keyval == Gdk.Key.Meta_L || event.keyval == Gdk.Key.Meta_R) {
                return true;
            }
            
            // Allow Escape to cancel
            if (event.keyval == Gdk.Key.Escape) {
                listening = false;
                update_label();
                return true;
            }
            
            // Capture the hotkey
            string new_hotkey = format_hotkey_string(event);
            hotkey = new_hotkey;
            listening = false;
            update_label();
            hotkey_changed(new_hotkey);
            
            return true;
        }
        
        private bool on_focus_out(Gdk.EventFocus event) {
            if (listening) {
                listening = false;
                update_label();
            }
            return false;
        }
        
        private void update_label() {
            if (listening) {
                set_label("Press keys...");
            } else if (hotkey == "") {
                set_label("(Not set)");
            } else {
                set_label(hotkey);
            }
        }
        
        private string format_hotkey_string(Gdk.EventKey event) {
            var parts = new List<string>();
            
            // Extract modifiers in consistent order: Super, Ctrl, Alt, Shift
            if ((event.state & Gdk.ModifierType.SUPER_MASK) != 0 ||
                (event.state & Gdk.ModifierType.MOD4_MASK) != 0) {
                parts.append("Super");
            }
            
            if ((event.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                parts.append("Ctrl");
            }
            
            if ((event.state & Gdk.ModifierType.MOD1_MASK) != 0) {
                parts.append("Alt");
            }
            
            if ((event.state & Gdk.ModifierType.SHIFT_MASK) != 0) {
                parts.append("Shift");
            }
            
            // Get the key name
            string key_name = get_key_name(event.keyval);
            parts.append(key_name);
            
            // Join with "+"
            string result = "";
            foreach (var part in parts) {
                if (result != "") {
                    result += "+";
                }
                result += part;
            }
            
            return result;
        }
        
        private string get_key_name(uint keyval) {
            // Handle special keys
            switch (keyval) {
                case Gdk.Key.space:
                    return "Space";
                case Gdk.Key.Return:
                    return "Return";
                case Gdk.Key.Tab:
                    return "Tab";
                case Gdk.Key.BackSpace:
                    return "BackSpace";
                case Gdk.Key.Delete:
                    return "Delete";
                case Gdk.Key.Insert:
                    return "Insert";
                case Gdk.Key.Home:
                    return "Home";
                case Gdk.Key.End:
                    return "End";
                case Gdk.Key.Page_Up:
                    return "Page_Up";
                case Gdk.Key.Page_Down:
                    return "Page_Down";
                case Gdk.Key.Up:
                    return "Up";
                case Gdk.Key.Down:
                    return "Down";
                case Gdk.Key.Left:
                    return "Left";
                case Gdk.Key.Right:
                    return "Right";
                case Gdk.Key.F1:
                    return "F1";
                case Gdk.Key.F2:
                    return "F2";
                case Gdk.Key.F3:
                    return "F3";
                case Gdk.Key.F4:
                    return "F4";
                case Gdk.Key.F5:
                    return "F5";
                case Gdk.Key.F6:
                    return "F6";
                case Gdk.Key.F7:
                    return "F7";
                case Gdk.Key.F8:
                    return "F8";
                case Gdk.Key.F9:
                    return "F9";
                case Gdk.Key.F10:
                    return "F10";
                case Gdk.Key.F11:
                    return "F11";
                case Gdk.Key.F12:
                    return "F12";
                default:
                    // For regular keys, get the name and convert to uppercase
                    string name = Gdk.keyval_name(keyval);
                    if (name != null && name.length > 0) {
                        return name.up();
                    }
                    return "Unknown";
            }
        }
        
        public void clear() {
            hotkey = "";
            update_label();
            hotkey_changed("");
        }
        
        public void revert_hotkey(string previous_hotkey) {
            hotkey = previous_hotkey;
            update_label();
        }
    }
}
