namespace NovaDock {
    public class ScriptPlugin : Object, Plugin {
        private string _id;
        private string _name;
        private string _icon;
        private string _command;
        private string _path;
        private string _type;
        private string _format;
        private string _script;
        private int _interval;
        private string _display_text;
        private uint _timer_id;

        public string id { get { return _id; } }
        public string name { get { return _name; } }
        public string icon { owned get { return _icon; } }
        public string path { get { return _path; } }
        public string display_text { get { return _display_text; } }
        public bool has_action { get { return _command != null && _command.length > 0; } }
        public bool has_menu { get { return false; } }
        public bool is_widget { get { return _type == "widget"; } }

        public signal void updated();

        public ScriptPlugin.from_file(string path) {
            _path = path;
            _display_text = "";
            load();
            if (is_widget) {
                update_widget();
                if (_interval > 0) {
                    _timer_id = Timeout.add_seconds(_interval, () => {
                        update_widget();
                        return true;
                    });
                }
            }
        }

        ~ScriptPlugin() {
            if (_timer_id > 0) Source.remove(_timer_id);
        }

        private void load() {
            try {
                var keyfile = new KeyFile();
                keyfile.load_from_file(_path, KeyFileFlags.NONE);

                _id = keyfile.get_string("Plugin", "id");
                _name = keyfile.get_string("Plugin", "name");
                _icon = keyfile.has_key("Plugin", "icon") ? keyfile.get_string("Plugin", "icon") : "";
                _type = keyfile.has_key("Plugin", "type") ? keyfile.get_string("Plugin", "type") : "launcher";
                
                if (keyfile.has_key("Plugin", "command"))
                    _command = keyfile.get_string("Plugin", "command");
                if (keyfile.has_key("Plugin", "format"))
                    _format = keyfile.get_string("Plugin", "format");
                if (keyfile.has_key("Plugin", "script"))
                    _script = keyfile.get_string("Plugin", "script");
                if (keyfile.has_key("Plugin", "interval"))
                    _interval = keyfile.get_integer("Plugin", "interval");
                else
                    _interval = 1;
            } catch (Error e) {
                _id = null;
            }
        }

        private void update_widget() {
            if (_format != null) {
                var now = new DateTime.now_local();
                _display_text = now.format(_format);
            } else if (_script != null) {
                try {
                    var dir = Path.get_dirname(_path);
                    var cmd = _script;
                    if (!Path.is_absolute(_script) && FileUtils.test(Path.build_filename(dir, _script), FileTest.EXISTS)) {
                        cmd = Path.build_filename(dir, _script);
                    }
                    string output;
                    Process.spawn_command_line_sync(cmd, out output);
                    _display_text = output.strip();
                } catch (Error e) {
                    _display_text = "?";
                }
            }
            updated();
        }

        public void activate() {
            if (_command != null) {
                try {
                    var dir = Path.get_dirname(_path);
                    var cmd = _command;
                    if (!Path.is_absolute(_command) && FileUtils.test(Path.build_filename(dir, _command), FileTest.EXISTS)) {
                        cmd = Path.build_filename(dir, _command);
                    }
                    Process.spawn_command_line_async(cmd);
                } catch (Error e) {}
            }
        }

        public Gtk.Menu? get_menu() {
            return null;
        }

        public void draw(Cairo.Context cr, double x, double y, int size) {
            // Uses default icon rendering
        }
    }
}
