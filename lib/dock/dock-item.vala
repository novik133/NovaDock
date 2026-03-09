namespace NovaDock {
    /* represents a single item displayed on the dock */
    public class DockItem : Object {
        public string id { get; set; }
        public string name { get; set; }
        public string icon_name { get; set; }
        public string desktop_file { get; set; }
        public bool pinned { get; set; default = false; }
        public bool running { get; set; default = false; }
        public bool is_launcher { get; set; default = false; }
        public bool is_plugin { get; set; default = false; }
        public bool is_widget { get; set; default = false; }
        public Plugin? plugin { get; set; default = null; }
        public List<weak Wnck.Window> windows;

        /* create a regular app dock item */
        public DockItem(string id, string name, string icon_name) {
            this.id = id;
            this.name = name;
            this.icon_name = icon_name;
            this.windows = new List<weak Wnck.Window>();
        }

        /* create a dock item backed by a plugin */
        public DockItem.from_plugin(Plugin plugin) {
            this.id = plugin.id;
            this.name = plugin.name;
            this.icon_name = plugin.icon;
            this.is_plugin = true;
            this.plugin = plugin;
            this.pinned = true;
            this.windows = new List<weak Wnck.Window>();

            if (plugin is ScriptPlugin) {
                var sp = plugin as ScriptPlugin;
                this.is_widget = sp.is_widget;
            }
        }
    }
}
