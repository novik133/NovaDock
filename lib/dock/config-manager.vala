namespace NovaDock {
    /* reads and writes ~/.config/novadock/config.ini */
    public class ConfigManager : Object {
        private string config_dir;
        private string config_file;
        private KeyFile keyfile;

        /* load or create config on construction */
        public ConfigManager() {
            config_dir = Path.build_filename(Environment.get_home_dir(), ".config", "novadock");
            config_file = Path.build_filename(config_dir, "config.ini");
            keyfile = new KeyFile();

            DirUtils.create_with_parents(config_dir, 0755);
            load();
        }

        /* load config from disk, silently ignore if missing */
        private void load() {
            try {
                keyfile.load_from_file(config_file, KeyFileFlags.NONE);
            } catch (Error e) {}
        }

        /* persist config to disk */
        public void save() {
            try {
                keyfile.save_to_file(config_file);
            } catch (Error e) {
                warning("Failed to save config: %s", e.message);
            }
        }

        /* get list of pinned app ids or desktop file paths */
        public string[] get_pinned_apps() {
            try {
                return keyfile.get_string_list("Dock", "pinned");
            } catch (Error e) {
                return {"org.gnome.Nautilus", "org.gnome.Terminal", "firefox"};
            }
        }

        /* store pinned app list */
        public void set_pinned_apps(string[] apps) {
            keyfile.set_string_list("Dock", "pinned", apps);
            save();
        }

        public int get_icon_size() {
            try { return keyfile.get_integer("Dock", "icon_size"); }
            catch (Error e) { return 48; }
        }

        public void set_icon_size(int size) {
            keyfile.set_integer("Dock", "icon_size", size);
            save();
        }

        public bool get_auto_hide() {
            try { return keyfile.get_boolean("Dock", "auto_hide"); }
            catch (Error e) { return false; }
        }

        public void set_auto_hide(bool enabled) {
            keyfile.set_boolean("Dock", "auto_hide", enabled);
            save();
        }

        public string get_position() {
            try { return keyfile.get_string("Dock", "position"); }
            catch (Error e) { return "bottom"; }
        }

        public void set_position(string pos) {
            keyfile.set_string("Dock", "position", pos);
            save();
        }

        public double get_magnification() {
            try { return keyfile.get_double("Dock", "magnification"); }
            catch (Error e) { return 1.5; }
        }

        public void set_magnification(double mag) {
            keyfile.set_double("Dock", "magnification", mag);
            save();
        }
        public string get_theme() {
            try { return keyfile.get_string("Dock", "theme"); }
            catch (Error e) { return "default"; }
        }

        public void set_theme(string theme) {
            keyfile.set_string("Dock", "theme", theme);
            save();
        }

        public int get_hide_delay() {
            try { return keyfile.get_integer("Dock", "hide_delay"); }
            catch (Error e) { return 500; }
        }

        public void set_hide_delay(int delay) {
            keyfile.set_integer("Dock", "hide_delay", delay);
            save();
        }

        public bool get_multi_monitor() {
            try { return keyfile.get_boolean("Dock", "multi_monitor"); }
            catch (Error e) { return false; }
        }

        public void set_multi_monitor(bool enabled) {
            keyfile.set_boolean("Dock", "multi_monitor", enabled);
            save();
        }

        public bool get_plugin_enabled(string plugin_id) {
            try {
                return keyfile.get_boolean("Plugins", plugin_id);
            } catch (Error e) {
                return true; // Default enabled
            }
        }

        public void set_plugin_enabled(string plugin_id, bool enabled) {
            keyfile.set_boolean("Plugins", plugin_id, enabled);
            save();
        }
        public string[] get_hidden_apps() {
            try {
                return keyfile.get_string_list("Launcher", "hidden");
            } catch (Error e) {
                return {};
            }
        }

        public void set_hidden_apps(string[] apps) {
            keyfile.set_string_list("Launcher", "hidden", apps);
            save();
        }

        public void hide_app(string app_id) {
            var hidden = get_hidden_apps();
            foreach (var id in hidden) {
                if (id == app_id) return;
            }
            hidden += app_id;
            set_hidden_apps(hidden);
        }

        public void unhide_app(string app_id) {
            var hidden = get_hidden_apps();
            string[] new_hidden = {};
            foreach (var id in hidden) {
                if (id != app_id) new_hidden += id;
            }
            set_hidden_apps(new_hidden);
        }

        public bool is_app_hidden(string app_id) {
            foreach (var id in get_hidden_apps()) {
                if (id == app_id) return true;
            }
            return false;
        }

        /* get all folder ids from config */
        public string[] get_folder_ids() {
            try {
                return keyfile.get_string_list("Folders", "ids");
            } catch (Error e) {
                return {};
            }
        }

        public string get_folder_name(string folder_id) {
            try {
                return keyfile.get_string("Folder_" + folder_id, "name");
            } catch (Error e) {
                return "Folder";
            }
        }

        public string[] get_folder_apps(string folder_id) {
            try {
                return keyfile.get_string_list("Folder_" + folder_id, "apps");
            } catch (Error e) {
                return {};
            }
        }

        public void create_folder(string folder_id, string name, string[] apps) {
            var ids = get_folder_ids();
            bool exists = false;
            foreach (var id in ids) {
                if (id == folder_id) { exists = true; break; }
            }
            if (!exists) {
                ids += folder_id;
                keyfile.set_string_list("Folders", "ids", ids);
            }
            keyfile.set_string("Folder_" + folder_id, "name", name);
            keyfile.set_string_list("Folder_" + folder_id, "apps", apps);
            save();
        }

        public void rename_folder(string folder_id, string name) {
            keyfile.set_string("Folder_" + folder_id, "name", name);
            save();
        }

        public void add_app_to_folder(string folder_id, string app_id) {
            var apps = get_folder_apps(folder_id);
            foreach (var a in apps) {
                if (a == app_id) return;
            }
            apps += app_id;
            keyfile.set_string_list("Folder_" + folder_id, "apps", apps);
            save();
        }

        public void remove_app_from_folder(string folder_id, string app_id) {
            var apps = get_folder_apps(folder_id);
            string[] new_apps = {};
            foreach (var a in apps) {
                if (a != app_id) new_apps += a;
            }
            keyfile.set_string_list("Folder_" + folder_id, "apps", new_apps);
            save();
        }

        public void delete_folder(string folder_id) {
            var ids = get_folder_ids();
            string[] new_ids = {};
            foreach (var id in ids) {
                if (id != folder_id) new_ids += id;
            }
            keyfile.set_string_list("Folders", "ids", new_ids);
            try {
                keyfile.remove_group("Folder_" + folder_id);
            } catch (Error e) {}
            save();
        }

        public string? get_app_folder(string app_id) {
            foreach (var folder_id in get_folder_ids()) {
                foreach (var a in get_folder_apps(folder_id)) {
                    if (a == app_id) return folder_id;
                }
            }
            return null;
        }

        /* hotkey configuration accessors */
        public string get_launcher_hotkey() {
            try {
                return keyfile.get_string("Hotkeys", "launcher");
            } catch (Error e) {
                return "";
            }
        }

        public void set_launcher_hotkey(string hotkey) {
            keyfile.set_string("Hotkeys", "launcher", hotkey);
            save();
        }

        public string get_app_hotkey_id(int slot) {
            try {
                return keyfile.get_string("Hotkeys", "app_%d_id".printf(slot));
            } catch (Error e) {
                return "";
            }
        }

        public void set_app_hotkey_id(int slot, string app_id) {
            keyfile.set_string("Hotkeys", "app_%d_id".printf(slot), app_id);
            save();
        }

        public string get_app_hotkey(int slot) {
            try {
                return keyfile.get_string("Hotkeys", "app_%d_hotkey".printf(slot));
            } catch (Error e) {
                return "";
            }
        }

        public void set_app_hotkey(int slot, string hotkey) {
            keyfile.set_string("Hotkeys", "app_%d_hotkey".printf(slot), hotkey);
            save();
        }
    }
}
