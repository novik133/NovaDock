namespace NovaDock {
    /* manages global keyboard shortcuts via keybinder */
    public class HotkeyManager : Object {
        private ConfigManager config;
        private LauncherWindow launcher;
        private AppManager app_manager;
        private Wnck.Screen screen;
        /* keybinder-format string -> action_id */
        private HashTable<string, string> registered_hotkeys;

        public signal void hotkey_error(string message);

        public HotkeyManager(ConfigManager config, LauncherWindow launcher, AppManager app_manager) {
            this.config = config;
            this.launcher = launcher;
            this.app_manager = app_manager;
            this.registered_hotkeys = new HashTable<string, string>(str_hash, str_equal);
        }

        /* initialise keybinder library; returns false if unsupported */
        public bool initialize() {
            if (!Keybinder.supported()) {
                warning("Keybinder not supported on this system");
                hotkey_error("Global hotkeys are not available on this system");
                return false;
            }
            Keybinder.init();
            screen = Wnck.Screen.get_default();
            return true;
        }

        /* register a hotkey (display format) with an action id */
        public bool register_hotkey(string display_keystring, string action_id) {
            /* convert "Super+Ctrl+A" to "<Super><Ctrl>a" for keybinder */
            string keystring = HotkeyCaptureButton.to_keybinder_format(display_keystring);
            if (keystring == "") return false;

            if (!Keybinder.bind_full(keystring, (ks) => {
                on_hotkey_pressed(ks);
            })) {
                warning("Failed to register hotkey: %s (keybinder: %s)", display_keystring, keystring);
                hotkey_error("Failed to register hotkey: %s (may be in use by another application)".printf(display_keystring));
                return false;
            }

            registered_hotkeys.set(keystring, action_id);
            return true;
        }

        /* unbind a single hotkey */
        public void unregister_hotkey(string display_keystring) {
            string keystring = HotkeyCaptureButton.to_keybinder_format(display_keystring);
            Keybinder.unbind_all(keystring);
            registered_hotkeys.remove(keystring);
        }

        /* unbind all registered hotkeys */
        public void unregister_all() {
            var keys = registered_hotkeys.get_keys();
            foreach (var keystring in keys) {
                Keybinder.unbind_all(keystring);
            }
            registered_hotkeys.remove_all();
        }

        /* reload hotkeys from config after settings change */
        public void reload_hotkeys() {
            unregister_all();

            string launcher_hotkey = config.get_launcher_hotkey();
            if (launcher_hotkey != "") {
                if (!register_hotkey(launcher_hotkey, "launcher")) {
                    warning("Failed to register launcher hotkey: %s", launcher_hotkey);
                }
            }

            for (int slot = 1; slot <= 4; slot++) {
                string app_hotkey = config.get_app_hotkey(slot);
                string app_id = config.get_app_hotkey_id(slot);
                if (app_hotkey != "" && app_id != "") {
                    string action_id = "app_%d".printf(slot);
                    if (!register_hotkey(app_hotkey, action_id)) {
                        warning("Failed to register app hotkey for slot %d: %s", slot, app_hotkey);
                    }
                }
            }
        }
        
        /* called by keybinder when a hotkey is pressed */
        private void on_hotkey_pressed(string keystring) {
            string? action_id = registered_hotkeys.get(keystring);
            if (action_id == null) {
                warning("Hotkey pressed but no action found: %s", keystring);
                return;
            }

            if (action_id == "launcher") {
                handle_launcher_hotkey();
            } else if (action_id.has_prefix("app_")) {
                int slot = int.parse(action_id.substring(4));
                handle_app_hotkey(slot);
            }
        }

        /* toggle the launcher overlay */
        private void handle_launcher_hotkey() {
            launcher.toggle();
        }

        /* launch or focus the app assigned to given slot */
        private void handle_app_hotkey(int slot) {
            string app_id = config.get_app_hotkey_id(slot);
            if (app_id == "") {
                warning("No app configured for hotkey slot %d", slot);
                return;
            }
            launch_or_focus_app(app_id);
        }

        /* if app is running focus it, otherwise start it */
        private void launch_or_focus_app(string app_id) {
            var app = app_manager.get_app(app_id);
            if (app == null) {
                warning("App not found: %s", app_id);
                hotkey_error("Application not found: %s".printf(app_id));
                return;
            }

            var windows = find_app_windows(app_id);
            if (windows.length() > 0) {
                focus_window(windows.first().data);
            } else {
                app.launch();
            }
        }

        /* find all normal windows belonging to given app */
        private List<Wnck.Window> find_app_windows(string app_id) {
            var result = new List<Wnck.Window>();
            screen.force_update();

            unowned List<Wnck.Window> windows = screen.get_windows();
            foreach (var window in windows) {
                if (window.get_window_type() != Wnck.WindowType.NORMAL) continue;
                var matched_app = app_manager.find_by_window(window);
                if (matched_app != null && matched_app.id == app_id) {
                    result.append(window);
                }
            }

            result.sort((a, b) => {
                return (int)(b.get_sort_order() - a.get_sort_order());
            });
            return result;
        }

        /* bring a window to front, switching workspace if needed */
        private void focus_window(Wnck.Window window) {
            uint32 timestamp = Keybinder.get_current_event_time();
            var workspace = window.get_workspace();
            var active_workspace = screen.get_active_workspace();

            if (workspace != null && workspace != active_workspace) {
                workspace.activate(timestamp);
            }
            window.activate(timestamp);
        }
    }
}
