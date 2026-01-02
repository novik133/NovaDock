namespace NovaDock {
    public class AppInfo : Object {
        public string id { get; set; }
        public string name { get; set; }
        public string icon { get; set; }
        public string exec { get; set; }
        public string desktop_file { get; set; }
        public string[] categories { get; set; }

        public AppInfo.from_desktop_file(string path) {
            desktop_file = path;
            id = Path.get_basename(path).replace(".desktop", "");

            try {
                var keyfile = new KeyFile();
                keyfile.load_from_file(path, KeyFileFlags.NONE);

                name = keyfile.get_locale_string("Desktop Entry", "Name");
                icon = keyfile.get_string("Desktop Entry", "Icon");
                exec = keyfile.get_string("Desktop Entry", "Exec");
                // Remove field codes from exec
                exec = exec.replace("%U", "").replace("%u", "")
                           .replace("%F", "").replace("%f", "").strip();

                if (keyfile.has_key("Desktop Entry", "Categories")) {
                    categories = keyfile.get_string("Desktop Entry", "Categories").split(";");
                } else {
                    categories = new string[0];
                }
            } catch (Error e) {
                name = id;
                icon = "application-x-executable";
                exec = "";
            }
        }

        public void launch() {
            try {
                Process.spawn_command_line_async(exec);
            } catch (Error e) {
                warning("Failed to launch %s: %s", name, e.message);
            }
        }
    }

    public class AppManager : Object {
        private HashTable<string, AppInfo> apps;
        private string[] app_dirs = {
            "/usr/share/applications",
            "/usr/local/share/applications"
        };

        public AppManager() {
            apps = new HashTable<string, AppInfo>(str_hash, str_equal);
            var home = Environment.get_home_dir();
            app_dirs += Path.build_filename(home, ".local/share/applications");
            load_applications();
        }

        private void load_applications() {
            foreach (var dir in app_dirs) {
                try {
                    var directory = Dir.open(dir);
                    string? name;
                    while ((name = directory.read_name()) != null) {
                        if (name.has_suffix(".desktop")) {
                            var path = Path.build_filename(dir, name);
                            var app = new AppInfo.from_desktop_file(path);
                            if (app.exec != "" && !is_hidden(path)) {
                                apps.set(app.id, app);
                            }
                        }
                    }
                } catch (Error e) {}
            }
        }

        private bool is_hidden(string path) {
            try {
                var keyfile = new KeyFile();
                keyfile.load_from_file(path, KeyFileFlags.NONE);
                if (keyfile.has_key("Desktop Entry", "NoDisplay")) {
                    return keyfile.get_boolean("Desktop Entry", "NoDisplay");
                }
            } catch (Error e) {}
            return false;
        }

        public AppInfo? get_app(string id) {
            return apps.get(id);
        }

        public List<weak AppInfo> get_all_apps() {
            return apps.get_values();
        }

        public AppInfo? find_by_window(Wnck.Window window) {
            var wnck_app = window.get_application();
            if (wnck_app == null) return null;

            string app_name = wnck_app.get_name().down();
            string? class_group = window.get_class_group_name();
            string? class_instance = window.get_class_instance_name();
            string cg = class_group != null ? class_group.down() : "";
            string ci = class_instance != null ? class_instance.down() : "";
            
            AppInfo? best_match = null;
            int best_score = 0;
            
            foreach (var app in apps.get_values()) {
                string id_lower = app.id.down();
                string name_lower = app.name.down();
                string exec_base = Path.get_basename(app.exec.split(" ")[0]).down();
                int score = 0;
                
                // Exact matches get highest score
                if (cg == id_lower || ci == id_lower) score = 100;
                else if (cg == exec_base || ci == exec_base) score = 90;
                else if (app_name == id_lower || app_name == name_lower) score = 80;
                // Partial matches
                else if (cg != "" && (cg.has_prefix(id_lower) || id_lower.has_prefix(cg))) score = 50;
                else if (ci != "" && (ci.has_prefix(id_lower) || id_lower.has_prefix(ci))) score = 50;
                else if (cg != "" && (cg.has_prefix(exec_base) || exec_base.has_prefix(cg))) score = 40;
                else if (app_name.contains(id_lower) || id_lower.contains(app_name)) score = 30;
                else if (name_lower.contains(app_name) || app_name.contains(name_lower)) score = 20;
                
                // Prefer shorter IDs (more specific match) when scores are equal
                if (score > best_score || (score == best_score && best_match != null && id_lower.length < best_match.id.length)) {
                    best_score = score;
                    best_match = app;
                }
            }
            return best_match;
        }
    }
}
