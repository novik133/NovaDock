namespace NovaDock {
    /* dock plugin that shows trash icon and allows emptying trash */
    public class TrashPlugin : Object, Plugin {
        public string id { get { return "trash"; } }
        public string name { get { return "Trash"; } }
        public string icon { owned get { return get_current_icon(); } }
        public bool has_action { get { return true; } }
        public bool has_menu { get { return true; } }

        private string trash_path;
        private FileMonitor? monitor;

        public signal void changed();

        public TrashPlugin() {
            trash_path = Path.build_filename(Environment.get_home_dir(), ".local/share/Trash/files");
            setup_monitor();
        }

        /* watch trash directory for changes */
        private void setup_monitor() {
            try {
                var dir = File.new_for_path(trash_path);
                monitor = dir.monitor_directory(FileMonitorFlags.NONE, null);
                monitor.changed.connect(() => changed());
            } catch (Error e) {}
        }

        public string get_current_icon() {
            return is_empty() ? "user-trash" : "user-trash-full";
        }

        private bool is_empty() {
            try {
                var dir = Dir.open(trash_path);
                return dir.read_name() == null;
            } catch (Error e) {
                return true;
            }
        }

        public void activate() {
            try {
                Process.spawn_command_line_async("xdg-open trash://");
            } catch (Error e) {}
        }

        public Gtk.Menu? get_menu() {
            var menu = new Gtk.Menu();

            var open = new Gtk.MenuItem.with_label("Open Trash");
            open.activate.connect(() => activate());
            menu.append(open);

            if (!is_empty()) {
                var empty = new Gtk.MenuItem.with_label("Empty Trash");
                empty.activate.connect(() => empty_trash());
                menu.append(empty);
            }

            menu.show_all();
            return menu;
        }

        /* empty the trash via gio or manual fallback */
        private void empty_trash() {
            try {
                // Use gio to properly empty trash
                Process.spawn_command_line_async("gio trash --empty");
            } catch (Error e) {
                // Fallback to manual deletion
                try {
                    var trash_files = Path.build_filename(Environment.get_home_dir(), ".local/share/Trash/files");
                    var trash_info = Path.build_filename(Environment.get_home_dir(), ".local/share/Trash/info");
                    Process.spawn_command_line_sync("rm -rf %s/*".printf(trash_files));
                    Process.spawn_command_line_sync("rm -rf %s/*".printf(trash_info));
                } catch (Error e2) {}
            }
        }

        public void draw(Cairo.Context cr, double x, double y, int size) {
            // Uses default icon rendering
        }
    }
}
