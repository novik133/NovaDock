namespace NovaDock {
    public class PluginManager : Object {
        private HashTable<string, Plugin> plugins;
        private ConfigManager config;

        public PluginManager(ConfigManager config) {
            this.config = config;
            plugins = new HashTable<string, Plugin>(str_hash, str_equal);
            load_builtin_plugins();
        }

        private void load_builtin_plugins() {
            register_plugin(new TrashPlugin());
            register_plugin(new ShowDesktopPlugin());
            register_plugin(new SeparatorPlugin());
        }

        public void register_plugin(Plugin plugin) {
            plugins.set(plugin.id, plugin);
        }

        public Plugin? get_plugin(string id) {
            return plugins.get(id);
        }

        public List<weak Plugin> get_all_plugins() {
            return plugins.get_values();
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
