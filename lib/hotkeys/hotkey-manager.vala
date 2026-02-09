namespace NovaDock {
    public class HotkeyManager : Object {
        private ConfigManager config;
        private LauncherWindow launcher;
        private AppManager app_manager;
        private Wnck.Screen screen;
        private HashTable<string, string> registered_hotkeys;  // hotkey -> action_id
        
        public signal void hotkey_error(string message);
        
        public HotkeyManager(ConfigManager config, LauncherWindow launcher, AppManager app_manager) {
            this.config = config;
            this.launcher = launcher;
            this.app_manager = app_manager;
            this.registered_hotkeys = new HashTable<string, string>(str_hash, str_equal);
        }
        
        public bool initialize() {
            // Check if keybinder is supported on this system
            if (!Keybinder.supported()) {
                warning("Keybinder not supported on this system");
                hotkey_error("Global hotkeys are not available on this system");
                return false;
            }
            
            // Initialize keybinder library
            Keybinder.init();
            
            // Initialize Wnck.Screen for window management
            screen = Wnck.Screen.get_default();
            
            return true;
        }
        
        public bool register_hotkey(string keystring, string action_id) {
            // Attempt to bind the hotkey using Keybinder
            // Note: We need to create a closure that captures the keystring
            if (!Keybinder.bind_full(keystring, (ks) => {
                on_hotkey_pressed(ks);
            })) {
                warning("Failed to register hotkey: %s", keystring);
                hotkey_error("Failed to register hotkey: %s (may be in use by another application)".printf(keystring));
                return false;
            }
            
            // Store the mapping in our HashTable
            registered_hotkeys.set(keystring, action_id);
            return true;
        }
        
        public void unregister_hotkey(string keystring) {
            // Unbind the hotkey using Keybinder
            Keybinder.unbind_all(keystring);
            
            // Remove from our HashTable
            registered_hotkeys.remove(keystring);
        }
        
        public void unregister_all() {
            // Iterate through all registered hotkeys and unregister them
            var keys = registered_hotkeys.get_keys();
            foreach (var keystring in keys) {
                Keybinder.unbind_all(keystring);
            }
            
            // Clear the HashTable
            registered_hotkeys.remove_all();
        }
        
        public void reload_hotkeys() {
            // Clear all existing hotkeys
            unregister_all();
            
            // Load and register launcher hotkey
            string launcher_hotkey = config.get_launcher_hotkey();
            if (launcher_hotkey != "") {
                if (!register_hotkey(launcher_hotkey, "launcher")) {
                    warning("Failed to register launcher hotkey: %s", launcher_hotkey);
                }
            }
            
            // Load and register all 4 app hotkey slots
            for (int slot = 1; slot <= 4; slot++) {
                string app_hotkey = config.get_app_hotkey(slot);
                string app_id = config.get_app_hotkey_id(slot);
                
                // Only register if both hotkey and app_id are configured
                if (app_hotkey != "" && app_id != "") {
                    string action_id = "app_%d".printf(slot);
                    if (!register_hotkey(app_hotkey, action_id)) {
                        warning("Failed to register app hotkey for slot %d: %s", slot, app_hotkey);
                    }
                }
            }
        }
        
        private void on_hotkey_pressed(string keystring) {
            // Callback invoked by keybinder when a registered hotkey is pressed
            string? action_id = registered_hotkeys.get(keystring);
            if (action_id == null) {
                warning("Hotkey pressed but no action found: %s", keystring);
                return;
            }
            
            // Handle the action based on action_id
            if (action_id == "launcher") {
                handle_launcher_hotkey();
            } else if (action_id.has_prefix("app_")) {
                // Extract slot number from action_id (e.g., "app_1" -> 1)
                int slot = int.parse(action_id.substring(4));
                handle_app_hotkey(slot);
            }
        }
        
        private void handle_launcher_hotkey() {
            // Toggle the launcher window visibility
            launcher.toggle();
        }
        
        private void handle_app_hotkey(int slot) {
            // Get the app_id configured for this slot
            string app_id = config.get_app_hotkey_id(slot);
            if (app_id == "") {
                warning("No app configured for hotkey slot %d", slot);
                return;
            }
            
            // Launch or focus the application
            launch_or_focus_app(app_id);
        }
        
        private void launch_or_focus_app(string app_id) {
            // Get the app from AppManager
            var app = app_manager.get_app(app_id);
            if (app == null) {
                warning("App not found: %s", app_id);
                hotkey_error("Application not found: %s".printf(app_id));
                return;
            }
            
            // Find windows for this app using Wnck
            var windows = find_app_windows(app_id);
            
            if (windows.length() > 0) {
                // App is running - focus the most recent window
                focus_window(windows.first().data);
            } else {
                // App is not running - launch it
                try {
                    app.launch();
                } catch (Error e) {
                    warning("Failed to launch %s: %s", app.name, e.message);
                    hotkey_error("Failed to launch %s: %s".printf(app.name, e.message));
                }
            }
        }
        
        private List<Wnck.Window> find_app_windows(string app_id) {
            var result = new List<Wnck.Window>();
            
            // Force Wnck to update its window list
            screen.force_update();
            
            // Get all windows from Wnck
            unowned List<Wnck.Window> windows = screen.get_windows();
            foreach (var window in windows) {
                // Skip windows that are not normal application windows
                if (window.get_window_type() != Wnck.WindowType.NORMAL) {
                    continue;
                }
                
                // Use AppManager to match window to app
                var matched_app = app_manager.find_by_window(window);
                if (matched_app != null && matched_app.id == app_id) {
                    result.append(window);
                }
            }
            
            // Sort by last activation time (most recent first)
            result.sort((a, b) => {
                // Windows don't have a direct "last activated" property,
                // but we can use the stacking order as a proxy
                // Higher stacking order = more recently used
                return (int)(b.get_sort_order() - a.get_sort_order());
            });
            
            return result;
        }
        
        private void focus_window(Wnck.Window window) {
            // Get current event timestamp from Keybinder
            uint32 timestamp = Keybinder.get_current_event_time();
            
            // Check if window is on a different workspace
            var workspace = window.get_workspace();
            var active_workspace = screen.get_active_workspace();
            
            if (workspace != null && workspace != active_workspace) {
                // Switch to the workspace containing the window
                workspace.activate(timestamp);
            }
            
            // Activate the window
            window.activate(timestamp);
        }
    }
}
