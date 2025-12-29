namespace NovaDock {
    public class SeparatorPlugin : Object, Plugin {
        public string id { get { return "separator"; } }
        public string name { get { return "Separator"; } }
        public string icon { owned get { return ""; } }
        public bool has_action { get { return false; } }
        public bool has_menu { get { return false; } }

        public void activate() {}

        public Gtk.Menu? get_menu() {
            return null;
        }

        public void draw(Cairo.Context cr, double x, double y, int size) {
            cr.set_source_rgba(1, 1, 1, 0.3);
            cr.set_line_width(2);
            cr.move_to(x, y - size / 3);
            cr.line_to(x, y + size / 3);
            cr.stroke();
        }
    }
}
