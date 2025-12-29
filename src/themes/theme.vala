namespace NovaDock {
    public class Theme : Object {
        public string id { get; set; }
        public string name { get; set; }
        public string path { get; set; }

        public double bg_red { get; set; default = 0.15; }
        public double bg_green { get; set; default = 0.15; }
        public double bg_blue { get; set; default = 0.15; }
        public double bg_alpha { get; set; default = 0.75; }

        public double border_red { get; set; default = 1.0; }
        public double border_green { get; set; default = 1.0; }
        public double border_blue { get; set; default = 1.0; }
        public double border_alpha { get; set; default = 0.15; }

        public double indicator_red { get; set; default = 1.0; }
        public double indicator_green { get; set; default = 1.0; }
        public double indicator_blue { get; set; default = 1.0; }
        public double indicator_alpha { get; set; default = 0.9; }

        public double corner_radius { get; set; default = 16; }
        public double border_width { get; set; default = 1; }

        public Theme(string id, string name) {
            this.id = id;
            this.name = name;
        }

        public Theme.from_file(string path) {
            this.path = path;
            this.id = Path.get_basename(Path.get_dirname(path));
            load();
        }

        private void load() {
            try {
                var keyfile = new KeyFile();
                keyfile.load_from_file(path, KeyFileFlags.NONE);

                name = keyfile.get_string("Theme", "name");

                if (keyfile.has_key("Background", "red"))
                    bg_red = keyfile.get_double("Background", "red");
                if (keyfile.has_key("Background", "green"))
                    bg_green = keyfile.get_double("Background", "green");
                if (keyfile.has_key("Background", "blue"))
                    bg_blue = keyfile.get_double("Background", "blue");
                if (keyfile.has_key("Background", "alpha"))
                    bg_alpha = keyfile.get_double("Background", "alpha");

                if (keyfile.has_key("Border", "red"))
                    border_red = keyfile.get_double("Border", "red");
                if (keyfile.has_key("Border", "green"))
                    border_green = keyfile.get_double("Border", "green");
                if (keyfile.has_key("Border", "blue"))
                    border_blue = keyfile.get_double("Border", "blue");
                if (keyfile.has_key("Border", "alpha"))
                    border_alpha = keyfile.get_double("Border", "alpha");

                if (keyfile.has_key("Indicator", "red"))
                    indicator_red = keyfile.get_double("Indicator", "red");
                if (keyfile.has_key("Indicator", "green"))
                    indicator_green = keyfile.get_double("Indicator", "green");
                if (keyfile.has_key("Indicator", "blue"))
                    indicator_blue = keyfile.get_double("Indicator", "blue");
                if (keyfile.has_key("Indicator", "alpha"))
                    indicator_alpha = keyfile.get_double("Indicator", "alpha");

                if (keyfile.has_key("Style", "corner_radius"))
                    corner_radius = keyfile.get_double("Style", "corner_radius");
                if (keyfile.has_key("Style", "border_width"))
                    border_width = keyfile.get_double("Style", "border_width");

            } catch (Error e) {
                name = id;
            }
        }
    }
}
