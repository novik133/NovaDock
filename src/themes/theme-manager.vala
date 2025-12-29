namespace NovaDock {
    public class ThemeManager : Object {
        private HashTable<string, Theme> themes;
        private string themes_dir;
        private string user_themes_dir;

        public ThemeManager() {
            themes = new HashTable<string, Theme>(str_hash, str_equal);
            themes_dir = "/usr/share/novadock/themes";
            user_themes_dir = Path.build_filename(Environment.get_home_dir(), ".local/share/novadock/themes");

            DirUtils.create_with_parents(user_themes_dir, 0755);
            load_builtin_themes();
            scan_themes();
        }

        private void load_builtin_themes() {
            // Default (macOS-style)
            var def = new Theme("default", "Default");
            themes.set(def.id, def);

            // Dark
            var dark = new Theme("dark", "Dark");
            dark.bg_red = 0.08; dark.bg_green = 0.08; dark.bg_blue = 0.08;
            dark.bg_alpha = 0.85;
            dark.border_alpha = 0.1;
            themes.set(dark.id, dark);

            // Light
            var light = new Theme("light", "Light");
            light.bg_red = 0.95; light.bg_green = 0.95; light.bg_blue = 0.95;
            light.bg_alpha = 0.85;
            light.border_red = 0; light.border_green = 0; light.border_blue = 0;
            light.border_alpha = 0.1;
            light.indicator_red = 0.2; light.indicator_green = 0.2; light.indicator_blue = 0.2;
            themes.set(light.id, light);

            // Transparent
            var trans = new Theme("transparent", "Transparent");
            trans.bg_alpha = 0.3;
            trans.border_alpha = 0.2;
            themes.set(trans.id, trans);
        }

        private void scan_themes() {
            scan_directory(themes_dir);
            scan_directory(user_themes_dir);
        }

        private void scan_directory(string dir) {
            try {
                var directory = Dir.open(dir);
                string? name;
                while ((name = directory.read_name()) != null) {
                    var theme_file = Path.build_filename(dir, name, "theme.ini");
                    if (FileUtils.test(theme_file, FileTest.EXISTS)) {
                        var theme = new Theme.from_file(theme_file);
                        themes.set(theme.id, theme);
                    }
                }
            } catch (Error e) {}
        }

        public Theme? get_theme(string id) {
            return themes.get(id);
        }

        public List<weak Theme> get_all_themes() {
            return themes.get_values();
        }

        public bool install_theme(string zip_path) {
            try {
                var name = Path.get_basename(zip_path).replace(".zip", "");
                var dest = Path.build_filename(user_themes_dir, name);
                DirUtils.create_with_parents(dest, 0755);

                Process.spawn_command_line_sync("unzip -o %s -d %s".printf(zip_path, dest));

                var theme_file = Path.build_filename(dest, "theme.ini");
                if (FileUtils.test(theme_file, FileTest.EXISTS)) {
                    var theme = new Theme.from_file(theme_file);
                    themes.set(theme.id, theme);
                    return true;
                }
            } catch (Error e) {}
            return false;
        }

        public void uninstall_theme(string id) {
            var theme = themes.get(id);
            if (theme != null && theme.path != null) {
                var dir = Path.get_dirname(theme.path);
                if (dir.has_prefix(user_themes_dir)) {
                    try {
                        Process.spawn_command_line_sync("rm -rf " + dir);
                        themes.remove(id);
                    } catch (Error e) {}
                }
            }
        }
    }
}
