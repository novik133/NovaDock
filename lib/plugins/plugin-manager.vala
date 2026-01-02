namespace NovaDock {
    public class PluginManager : Object {
        private HashTable<string, Plugin> plugins;
        private ConfigManager config;
        private string user_plugins_dir;

        public PluginManager(ConfigManager config) {
            this.config = config;
            plugins = new HashTable<string, Plugin>(str_hash, str_equal);
            user_plugins_dir = Path.build_filename(Environment.get_home_dir(), ".local/share/novadock/plugins");
            DirUtils.create_with_parents(user_plugins_dir, 0755);
            load_builtin_plugins();
            load_user_plugins();
        }

        private void load_builtin_plugins() {
            register_plugin(new TrashPlugin());
            register_plugin(new ShowDesktopPlugin());
            register_plugin(new SeparatorPlugin());
        }

        private void load_user_plugins() {
            try {
                var dir = Dir.open(user_plugins_dir);
                string? name;
                while ((name = dir.read_name()) != null) {
                    var plugin_file = Path.build_filename(user_plugins_dir, name, "plugin.ini");
                    if (FileUtils.test(plugin_file, FileTest.EXISTS)) {
                        var plugin = new ScriptPlugin.from_file(plugin_file);
                        if (plugin.id != null) {
                            register_plugin(plugin);
                        }
                    }
                }
            } catch (Error e) {}
        }

        public void register_plugin(Plugin plugin) {
            plugins.set(plugin.id, plugin);
        }

        public void unregister_plugin(string id) {
            plugins.remove(id);
        }

        public Plugin? get_plugin(string id) {
            return plugins.get(id);
        }

        public List<weak Plugin> get_all_plugins() {
            return plugins.get_values();
        }

        public List<weak Plugin> get_user_plugins() {
            var list = new List<weak Plugin>();
            foreach (var plugin in plugins.get_values()) {
                if (plugin is ScriptPlugin) {
                    list.append(plugin);
                }
            }
            return list;
        }

        public bool install_plugin(string zip_path) {
            try {
                var name = Path.get_basename(zip_path).replace(".zip", "");
                var dest = Path.build_filename(user_plugins_dir, name);
                DirUtils.create_with_parents(dest, 0755);

                Process.spawn_command_line_sync("unzip -o %s -d %s".printf(zip_path, dest));

                var plugin_file = Path.build_filename(dest, "plugin.ini");
                if (FileUtils.test(plugin_file, FileTest.EXISTS)) {
                    var plugin = new ScriptPlugin.from_file(plugin_file);
                    if (plugin.id != null) {
                        register_plugin(plugin);
                        return true;
                    }
                }
            } catch (Error e) {}
            return false;
        }

        public void uninstall_plugin(string id) {
            var plugin = plugins.get(id) as ScriptPlugin;
            if (plugin != null && plugin.path != null) {
                var dir = Path.get_dirname(plugin.path);
                if (dir.has_prefix(user_plugins_dir)) {
                    try {
                        Process.spawn_command_line_sync("rm -rf " + dir);
                        plugins.remove(id);
                    } catch (Error e) {}
                }
            }
        }

        public string[] get_enabled_plugins() {
            try {
                var keyfile = new KeyFile();
                var path = Path.build_filename(Environment.get_home_dir(), ".config/novadock/config.ini");
                keyfile.load_from_file(path, KeyFileFlags.NONE);
                return keyfile.get_string_list("Plugins", "enabled");
            } catch (Error e) {
                return {"trash", "show-desktop"};
            }
        }

        public void set_enabled_plugins(string[] ids) {
            try {
                var keyfile = new KeyFile();
                var path = Path.build_filename(Environment.get_home_dir(), ".config/novadock/config.ini");
                try { keyfile.load_from_file(path, KeyFileFlags.NONE); } catch (Error e) {}
                keyfile.set_string_list("Plugins", "enabled", ids);
                keyfile.save_to_file(path);
            } catch (Error e) {}
        }
    }
}
