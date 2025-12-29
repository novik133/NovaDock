namespace NovaDock {
    public class DockRenderer : Object {
        private Gtk.IconTheme icon_theme;
        private HashTable<string, Gdk.Pixbuf?> icon_cache;

        public int icon_size { get; set; default = 48; }
        public double magnification { get; set; default = 1.5; }
        public int spacing { get; set; default = 8; }
        public Theme? theme { get; set; default = null; }

        public DockRenderer() {
            icon_theme = Gtk.IconTheme.get_default();
            icon_cache = new HashTable<string, Gdk.Pixbuf?>(str_hash, str_equal);
            
            // Clear cache when icon theme changes
            icon_theme.changed.connect(() => {
                icon_cache.remove_all();
            });
        }

        public void clear_icon_cache(string icon_name) {
            // Remove all sizes of this icon from cache
            var keys_to_remove = new List<string>();
            icon_cache.foreach((key, val) => {
                if (key.has_prefix(icon_name + "_")) {
                    keys_to_remove.append(key);
                }
            });
            foreach (var key in keys_to_remove) {
                icon_cache.remove(key);
            }
        }

        public Gdk.Pixbuf? get_icon(string icon_name, int size) {
            // Always load at a fixed large size for quality, then scale
            int load_size = 96;
            string key = icon_name;
            
            Gdk.Pixbuf? base_pixbuf = null;
            
            if (icon_cache.contains(key)) {
                base_pixbuf = icon_cache.get(key);
            } else {
                var theme = Gtk.IconTheme.get_default();
                try {
                    base_pixbuf = theme.load_icon(icon_name, load_size, Gtk.IconLookupFlags.FORCE_SIZE);
                } catch (Error e) {
                    try {
                        base_pixbuf = theme.load_icon("application-x-executable", load_size, Gtk.IconLookupFlags.FORCE_SIZE);
                    } catch (Error e2) {}
                }
                icon_cache.set(key, base_pixbuf);
            }
            
            if (base_pixbuf == null) return null;
            
            // Scale to requested size
            if (base_pixbuf.get_width() != size) {
                return base_pixbuf.scale_simple(size, size, Gdk.InterpType.BILINEAR);
            }
            return base_pixbuf;
        }

        public void draw_item(Cairo.Context cr, DockItem item, double x, double y, double scale, bool hovered) {
            // Draw separator as a line, not an icon
            if (item.is_plugin && item.plugin != null && item.plugin.id == "separator") {
                cr.set_source_rgba(1, 1, 1, 0.4);
                cr.set_line_width(2);
                double line_height = icon_size * 0.6;
                cr.move_to(x, y - line_height / 2);
                cr.line_to(x, y + line_height / 2);
                cr.stroke();
                return;
            }

            int size = (int)(icon_size * scale);
            
            // Widget plugins - draw text instead of icon
            if (item.is_widget && item.plugin is ScriptPlugin) {
                var sp = item.plugin as ScriptPlugin;
                draw_widget_text(cr, sp.display_text, x, y, size);
                return;
            }
            
            // Get icon name - for plugins, get it fresh each time
            string icon_name = item.icon_name;
            if (item.is_plugin && item.plugin != null) {
                icon_name = item.plugin.icon;
            }
            
            var pixbuf = get_icon(icon_name, size);

            if (pixbuf != null) {
                double draw_x = x - size / 2.0;
                double draw_y = y - size / 2.0;

                Gdk.cairo_set_source_pixbuf(cr, pixbuf, draw_x, draw_y);
                cr.paint();
            }

            // Running indicator dots
            if (item.running) {
                if (theme != null) {
                    cr.set_source_rgba(theme.indicator_red, theme.indicator_green,
                                       theme.indicator_blue, theme.indicator_alpha);
                } else {
                    cr.set_source_rgba(1, 1, 1, 0.9);
                }

                int window_count = (int)item.windows.length();
                int dots = int.min(window_count, 3);
                double dot_spacing = 6;
                double start_x = x - (dots - 1) * dot_spacing / 2;

                for (int i = 0; i < dots; i++) {
                    cr.arc(start_x + i * dot_spacing, y + size / 2.0 + 6, 2.5, 0, 2 * Math.PI);
                    cr.fill();
                }
            }
        }

        private void draw_widget_text(Cairo.Context cr, string text, double x, double y, int size) {
            cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_font_size(size * 0.35);
            
            Cairo.TextExtents extents;
            cr.text_extents(text, out extents);
            
            double text_x = x - extents.width / 2;
            double text_y = y + extents.height / 2;
            
            cr.set_source_rgba(1, 1, 1, 1);
            cr.move_to(text_x, text_y);
            cr.show_text(text);
        }

        public double calculate_scale(double distance, double hover_pos, bool hovering) {
            if (!hovering) return 1.0;

            double range = icon_size * 2.5;
            if (distance > range) return 1.0;

            double factor = 1.0 - (distance / range);
            return 1.0 + (magnification - 1.0) * factor * factor;
        }
    }
}
