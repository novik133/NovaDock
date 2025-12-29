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
            foreach (var app in apps.get_values()) {
                if (app_name.contains(app.id.down()) || app.id.down().contains(app_name) ||
                    app.name.down().contains(app_name) || app_name.contains(app.name.down())) {
                    return app;
                }
            }
            return null;
        }
    }
}
