namespace NovaDock {
    public class DockWindow : Gtk.Window {
        private WindowManager wm;
        private DockRenderer renderer;
        private AppManager app_manager;
        private ConfigManager config;
        private PluginManager plugin_manager;
        private ThemeManager theme_manager;
        private Theme current_theme;
        private List<DockItem> items;
        private Gtk.Menu? context_menu;

        public signal void launcher_requested();
        public signal void settings_requested();

        private double mouse_x = -1;
        private double mouse_y = -1;
        private bool hovering = false;
        private bool auto_hide = false;
        private bool hidden = false;
        private int base_height = 80;
        private int dock_padding = 12;
        private int icon_area_height = 60;
        private uint hide_timeout_id = 0;
        private string dock_position = "bottom";

        // Drag and drop
        private int drag_index = -1;
        private double drag_start_x;
        private bool dragging = false;

        public DockWindow(Gtk.Application app, AppManager app_manager) {
            Object(
                application: app,
                type: Gtk.WindowType.TOPLEVEL,
                decorated: false,
                skip_taskbar_hint: true,
                skip_pager_hint: true
            );

            renderer = new DockRenderer();
            this.app_manager = app_manager;
            config = new ConfigManager();
            plugin_manager = new PluginManager(config);
            theme_manager = new ThemeManager();
            items = new List<DockItem>();

            load_theme();

            // Add launcher button first
            var launcher_item = new DockItem("novadock-launcher", "Applications", "view-app-grid-symbolic");
            launcher_item.pinned = true;
            launcher_item.is_launcher = true;
            items.append(launcher_item);

            load_pinned_apps();
            
            // Add separator before system plugins (if enabled)
            if (config.get_plugin_enabled("separator")) {
                var sep = plugin_manager.get_plugin("separator");
                if (sep != null) {
                    items.append(new DockItem.from_plugin(sep));
                }
            }
            
            // Add show-desktop before trash (if enabled)
            if (config.get_plugin_enabled("show-desktop")) {
                var show_desktop = plugin_manager.get_plugin("show-desktop");
                if (show_desktop != null) {
                    items.append(new DockItem.from_plugin(show_desktop));
                }
            }
            
            // Add trash last (if enabled)
            if (config.get_plugin_enabled("trash")) {
                var trash = plugin_manager.get_plugin("trash") as TrashPlugin;
                if (trash != null) {
                    items.append(new DockItem.from_plugin(trash));
                    trash.changed.connect(() => {
                        renderer.clear_icon_cache("user-trash");
                        renderer.clear_icon_cache("user-trash-full");
                        queue_draw();
                    });
                }
            }

            set_default_size(calculate_width(), base_height);
            set_keep_above(true);
            stick();

            set_app_paintable(true);
            var screen = get_screen();
            var visual = screen.get_rgba_visual();
            if (visual != null) set_visual(visual);

            set_type_hint(Gdk.WindowTypeHint.DOCK);
            set_events(Gdk.EventMask.POINTER_MOTION_MASK |
                       Gdk.EventMask.LEAVE_NOTIFY_MASK |
                       Gdk.EventMask.ENTER_NOTIFY_MASK |
                       Gdk.EventMask.BUTTON_PRESS_MASK |
                       Gdk.EventMask.BUTTON_RELEASE_MASK);

            screen.size_changed.connect(position_dock);
            realize.connect(position_dock);

            wm = new WindowManager();
            wm.windows_changed.connect(update_running_apps);

            draw.connect(on_draw);
            motion_notify_event.connect(on_motion);
            leave_notify_event.connect(on_leave);
            enter_notify_event.connect(on_enter);
            button_press_event.connect(on_button_press);
            button_release_event.connect(on_button_release);

            auto_hide = config.get_auto_hide();
            dock_position = config.get_position();
            renderer.icon_size = config.get_icon_size();
            renderer.magnification = config.get_magnification();
        }

        private void load_pinned_apps() {
            foreach (var app_id in config.get_pinned_apps()) {
                var app = app_manager.get_app(app_id);
                if (app != null) {
                    var item = new DockItem(app.id, app.name, app.icon);
                    item.desktop_file = app.desktop_file;
                    item.pinned = true;
                    items.append(item);
                }
            }
            // Fallback defaults if no pinned apps
            bool has_pinned = false;
            foreach (var item in items) {
                if (item.pinned && !item.is_launcher && !item.is_plugin) {
                    has_pinned = true;
                    break;
                }
            }
            if (!has_pinned) {
                var files = new DockItem("thunar", "Files", "system-file-manager");
                files.pinned = true;
                items.append(files);
                var term = new DockItem("xfce4-terminal", "Terminal", "utilities-terminal");
                term.pinned = true;
                items.append(term);
            }
        }

        private void save_pinned_apps() {
            string[] pinned = {};
            foreach (var item in items) {
                if (item.pinned && !item.is_launcher && !item.is_plugin) pinned += item.id;
            }
            config.set_pinned_apps(pinned);
        }

        private void load_theme() {
            current_theme = theme_manager.get_theme(config.get_theme());
            if (current_theme == null) {
                current_theme = theme_manager.get_theme("default");
            }
            renderer.theme = current_theme;
        }

        private int calculate_width() {
            int total = dock_padding * 2;
            foreach (var item in items) {
                // Separator is narrower
                if (item.is_plugin && item.plugin != null && item.plugin.id == "separator") {
                    total += 24;
                } else {
                    total += renderer.icon_size + renderer.spacing;
                }
            }
            return int.max(total, 200);
        }

        private void position_dock() {
            var display = Gdk.Display.get_default();
            int monitor_num = config.get_multi_monitor() ? -1 : 0;
            Gdk.Monitor monitor;

            if (monitor_num < 0) {
                monitor = display.get_primary_monitor();
            } else {
                monitor = display.get_monitor(monitor_num) ?? display.get_primary_monitor();
            }

            var geometry = monitor.get_geometry();
            int dock_length = calculate_width();

            string position = config.get_position();
            int x, y;
            int hide_offset = hidden ? base_height - 4 : 0;

            switch (position) {
                case "left":
                    x = geometry.x - hide_offset;
                    y = geometry.y + (geometry.height - dock_length) / 2;
                    resize(base_height, dock_length);
                    break;
                case "right":
                    x = geometry.x + geometry.width - base_height + hide_offset;
                    y = geometry.y + (geometry.height - dock_length) / 2;
                    resize(base_height, dock_length);
                    break;
                default: // bottom
                    x = geometry.x + (geometry.width - dock_length) / 2;
                    y = geometry.y + geometry.height - base_height + hide_offset;
                    resize(dock_length, base_height);
                    break;
            }

            move(x, y);
        }

        private void update_running_apps() {
            var windows = wm.get_windows();

            // Reset running state (but not for launcher or plugins)
            foreach (var item in items) {
                if (!item.is_plugin && !item.is_launcher) {
                    item.running = false;
                    item.windows = new List<weak Wnck.Window>();
                }
            }

            // Match windows to dock items
            foreach (var window in windows) {
                var app = app_manager.find_by_window(window);
                if (app == null) continue;

                bool found = false;
                foreach (var item in items) {
                    // Skip launcher and plugins when matching
                    if (item.is_launcher || item.is_plugin) continue;
                    
                    if (item.id == app.id) {
                        item.running = true;
                        item.windows.append(window);
                        found = true;
                        break;
                    }
                }

                // Add non-pinned running app before separator
                if (!found) {
                    var item = new DockItem(app.id, app.name, app.icon);
                    item.desktop_file = app.desktop_file;
                    item.running = true;
                    item.windows.append(window);
                    
                    // Find separator index and insert before it
                    int insert_pos = find_separator_index();
                    if (insert_pos >= 0) {
                        items.insert(item, insert_pos);
                    } else {
                        items.append(item);
                    }
                }
            }

            // Remove non-pinned, non-running items (but not plugins or launcher)
            var to_remove = new List<DockItem>();
            foreach (var item in items) {
                if (!item.pinned && !item.running && !item.is_plugin && !item.is_launcher) {
                    to_remove.append(item);
                }
            }
            foreach (var item in to_remove) {
                items.remove(item);
            }

            position_dock();
            queue_draw();
        }

        private int find_separator_index() {
            int i = 0;
            foreach (var item in items) {
                if (item.is_plugin && item.plugin != null && item.plugin.id == "separator") {
                    return i;
                }
                i++;
            }
            return -1;
        }

        private bool on_draw(Cairo.Context cr) {
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.set_source_rgba(0, 0, 0, 0);
            cr.paint();

            cr.set_operator(Cairo.Operator.OVER);
            
            string position = config.get_position();
            if (position == "left" || position == "right") {
                draw_dock_background_vertical(cr, position);
                draw_items_vertical(cr, position);
            } else {
                draw_dock_background(cr);
                draw_items(cr);
            }

            return false;
        }

        private void draw_dock_background(Cairo.Context cr) {
            int width = get_allocated_width();
            int height = get_allocated_height();
            double radius = current_theme != null ? current_theme.corner_radius : 16;
            double margin = 4;

            // Background at bottom
            double x = margin;
            double y = height - icon_area_height - margin;
            double w = width - margin * 2;
            double h = icon_area_height;

            cr.new_path();
            cr.arc(x + w - radius, y + radius, radius, -Math.PI / 2, 0);
            cr.arc(x + w - radius, y + h - radius, radius, 0, Math.PI / 2);
            cr.arc(x + radius, y + h - radius, radius, Math.PI / 2, Math.PI);
            cr.arc(x + radius, y + radius, radius, Math.PI, 3 * Math.PI / 2);
            cr.close_path();

            if (current_theme != null) {
                cr.set_source_rgba(current_theme.bg_red, current_theme.bg_green,
                                   current_theme.bg_blue, current_theme.bg_alpha);
            } else {
                cr.set_source_rgba(0.15, 0.15, 0.15, 0.75);
            }
            cr.fill_preserve();

            if (current_theme != null) {
                cr.set_source_rgba(current_theme.border_red, current_theme.border_green,
                                   current_theme.border_blue, current_theme.border_alpha);
                cr.set_line_width(current_theme.border_width);
            } else {
                cr.set_source_rgba(1, 1, 1, 0.15);
                cr.set_line_width(1);
            }
            cr.stroke();
        }

        private void draw_dock_background_vertical(Cairo.Context cr, string position) {
            int width = get_allocated_width();
            int height = get_allocated_height();
            double radius = current_theme != null ? current_theme.corner_radius : 16;
            double margin = 4;

            double x, y, w, h;
            w = icon_area_height;
            h = height - margin * 2;
            y = margin;
            
            if (position == "left") {
                x = margin;
            } else { // right
                x = margin;  // Background starts at margin since window is already positioned at right edge
            }

            cr.new_path();
            cr.arc(x + w - radius, y + radius, radius, -Math.PI / 2, 0);
            cr.arc(x + w - radius, y + h - radius, radius, 0, Math.PI / 2);
            cr.arc(x + radius, y + h - radius, radius, Math.PI / 2, Math.PI);
            cr.arc(x + radius, y + radius, radius, Math.PI, 3 * Math.PI / 2);
            cr.close_path();

            if (current_theme != null) {
                cr.set_source_rgba(current_theme.bg_red, current_theme.bg_green,
                                   current_theme.bg_blue, current_theme.bg_alpha);
            } else {
                cr.set_source_rgba(0.15, 0.15, 0.15, 0.75);
            }
            cr.fill_preserve();

            if (current_theme != null) {
                cr.set_source_rgba(current_theme.border_red, current_theme.border_green,
                                   current_theme.border_blue, current_theme.border_alpha);
                cr.set_line_width(current_theme.border_width);
            } else {
                cr.set_source_rgba(1, 1, 1, 0.15);
                cr.set_line_width(1);
            }
            cr.stroke();
        }

        private void draw_items_vertical(Cairo.Context cr, string position) {
            double margin = 4;
            // Icons should be centered within the dock background area
            double icon_baseline = margin + icon_area_height / 2.0;
            
            // First pass: calculate all scales and total height
            double[] scales = new double[items.length()];
            double[] positions = new double[items.length()];
            double total_height = dock_padding;
            
            int i = 0;
            foreach (var item in items) {
                bool is_separator = item.is_plugin && item.plugin != null && item.plugin.id == "separator";
                
                if (is_separator) {
                    scales[i] = 1.0;
                    positions[i] = total_height + 12;
                    total_height += 24;
                } else {
                    double item_center_estimate = total_height + renderer.icon_size / 2.0;
                    double distance = hovering ? Math.fabs(mouse_y - item_center_estimate) : 1000;
                    scales[i] = renderer.calculate_scale(distance, mouse_y, hovering);
                    
                    double scaled_size = renderer.icon_size * scales[i];
                    positions[i] = total_height + scaled_size / 2.0;
                    total_height += scaled_size + renderer.spacing;
                }
                i++;
            }
            
            // Second pass: draw items
            i = 0;
            foreach (var item in items) {
                double scale = scales[i];
                double y = positions[i];
                double x = icon_baseline;
                
                renderer.draw_item(cr, item, x, y, scale, hovering);
                i++;
            }
        }

        private void draw_items(Cairo.Context cr) {
            int height = get_allocated_height();
            double icon_baseline = height - 10 - renderer.icon_size / 2.0; // Icons sit near bottom
            
            // First pass: calculate all scales and total width
            double[] scales = new double[items.length()];
            double[] positions = new double[items.length()];
            double total_width = dock_padding;
            
            int i = 0;
            foreach (var item in items) {
                bool is_separator = item.is_plugin && item.plugin != null && item.plugin.id == "separator";
                
                if (is_separator) {
                    scales[i] = 1.0;
                    positions[i] = total_width + 12; // center of separator
                    total_width += 24;
                } else {
                    // Calculate scale based on distance from mouse
                    double item_center_estimate = total_width + renderer.icon_size / 2.0;
                    double distance = hovering ? Math.fabs(mouse_x - item_center_estimate) : 1000;
                    scales[i] = renderer.calculate_scale(distance, mouse_x, hovering);
                    
                    double scaled_size = renderer.icon_size * scales[i];
                    positions[i] = total_width + scaled_size / 2.0;
                    total_width += scaled_size + renderer.spacing;
                }
                i++;
            }
            total_width += dock_padding - renderer.spacing;
            
            // Second pass: draw items at calculated positions
            i = 0;
            foreach (var item in items) {
                double scale = scales[i];
                double x = positions[i];
                // Icons rise up when magnified
                double scaled_size = renderer.icon_size * scale;
                double y = icon_baseline - (scaled_size - renderer.icon_size) / 2.0;
                
                renderer.draw_item(cr, item, x, y, scale, hovering);
                i++;
            }

            // Adjust window width only for horizontal dock
            if (config.get_position() == "bottom") {
                int new_width = (int)total_width;
                int current_width = get_allocated_width();
                if (Math.fabs(new_width - current_width) > 2) {
                    set_size_request(new_width, base_height);
                    position_dock();
                }
            }
        }

        private bool on_motion(Gdk.EventMotion event) {
            mouse_x = event.x;
            mouse_y = event.y;
            queue_draw();
            return true;
        }

        private bool on_enter(Gdk.EventCrossing event) {
            hovering = true;
            if (hide_timeout_id != 0) {
                Source.remove(hide_timeout_id);
                hide_timeout_id = 0;
            }
            if (auto_hide && hidden) {
                hidden = false;
                position_dock();
            }
            queue_draw();
            return true;
        }

        private bool on_leave(Gdk.EventCrossing event) {
            hovering = false;
            mouse_x = -1;
            mouse_y = -1;
            position_dock();

            if (auto_hide && !hidden) {
                int delay = config.get_hide_delay();
                hide_timeout_id = Timeout.add(delay, () => {
                    hidden = true;
                    position_dock();
                    hide_timeout_id = 0;
                    return false;
                });
            }

            queue_draw();
            return true;
        }

        private bool on_button_press(Gdk.EventButton event) {
            if (event.button == 1) {
                drag_start_x = event.x;
                drag_index = get_item_at(event.x, event.y);
            } else if (event.button == 3) {
                show_context_menu(event);
            }
            return true;
        }

        private bool on_button_release(Gdk.EventButton event) {
            if (event.button == 1 && drag_index >= 0) {
                int target = get_item_at(event.x, event.y);
                if (Math.fabs(event.x - drag_start_x) < 5 && target == drag_index) {
                    activate_item(drag_index);
                } else if (target >= 0 && target != drag_index) {
                    var item = items.nth_data(drag_index);
                    items.remove(item);
                    items.insert(item, target);
                    save_pinned_apps();
                    queue_draw();
                }
            }
            drag_index = -1;
            dragging = false;
            return true;
        }

        private void show_context_menu(Gdk.EventButton event) {
            int index = get_item_at(event.x, event.y);
            if (index < 0) return;

            var item = items.nth_data(index);
            if (item == null) return;

            // Plugin custom menu
            if (item.is_plugin && item.plugin != null && item.plugin.has_menu) {
                var menu = item.plugin.get_menu();
                if (menu != null) {
                    menu.popup_at_pointer(event);
                    return;
                }
            }

            context_menu = new Gtk.Menu();

            if (item.running) {
                var new_window = new Gtk.MenuItem.with_label("Open New Window");
                new_window.activate.connect(() => launch_app(item));
                context_menu.append(new_window);
                context_menu.append(new Gtk.SeparatorMenuItem());
            }

            if (item.pinned) {
                var unpin = new Gtk.MenuItem.with_label("Unpin from Dock");
                unpin.activate.connect(() => {
                    if (item.running) {
                        item.pinned = false;
                    } else {
                        items.remove(item);
                    }
                    save_pinned_apps();
                    queue_draw();
                });
                context_menu.append(unpin);
            } else {
                var pin = new Gtk.MenuItem.with_label("Pin to Dock");
                pin.activate.connect(() => {
                    item.pinned = true;
                    save_pinned_apps();
                    queue_draw();
                });
                context_menu.append(pin);
            }

            if (item.running && item.windows.length() > 0) {
                context_menu.append(new Gtk.SeparatorMenuItem());
                var close = new Gtk.MenuItem.with_label("Close Window");
                close.activate.connect(() => {
                    item.windows.nth_data(0).close(Gtk.get_current_event_time());
                });
                context_menu.append(close);
            }

            context_menu.append(new Gtk.SeparatorMenuItem());
            var settings_item = new Gtk.MenuItem.with_label("Dock Settings...");
            settings_item.activate.connect(() => settings_requested());
            context_menu.append(settings_item);

            context_menu.show_all();
            context_menu.popup_at_pointer(event);
        }

        private void launch_app(DockItem item) {
            var app = app_manager.get_app(item.id);
            if (app != null) {
                app.launch();
            }
        }

        public void reload_settings() {
            config = new ConfigManager();
            renderer.icon_size = config.get_icon_size();
            renderer.magnification = config.get_magnification();
            auto_hide = config.get_auto_hide();
            dock_position = config.get_position();
            load_theme();
            
            // Rebuild items list with updated plugin settings
            rebuild_items();
            
            // Handle autohide state change
            if (!auto_hide && hidden) {
                hidden = false;
            }
            
            position_dock();
            queue_draw();
        }

        private void rebuild_items() {
            items = new List<DockItem>();
            
            // Add launcher button first
            var launcher_item = new DockItem("novadock-launcher", "Applications", "view-app-grid-symbolic");
            launcher_item.pinned = true;
            launcher_item.is_launcher = true;
            items.append(launcher_item);

            load_pinned_apps();
            
            // Add separator before system plugins (if enabled)
            if (config.get_plugin_enabled("separator")) {
                var sep = plugin_manager.get_plugin("separator");
                if (sep != null) {
                    items.append(new DockItem.from_plugin(sep));
                }
            }
            
            // Add show-desktop before trash (if enabled)
            if (config.get_plugin_enabled("show-desktop")) {
                var show_desktop = plugin_manager.get_plugin("show-desktop");
                if (show_desktop != null) {
                    items.append(new DockItem.from_plugin(show_desktop));
                }
            }
            
            // Add trash last (if enabled)
            if (config.get_plugin_enabled("trash")) {
                var trash = plugin_manager.get_plugin("trash");
                if (trash != null) {
                    items.append(new DockItem.from_plugin(trash));
                }
            }
            
            // Add user plugins
            foreach (var plugin in plugin_manager.get_user_plugins()) {
                if (config.get_plugin_enabled(plugin.id)) {
                    var item = new DockItem.from_plugin(plugin);
                    items.append(item);
                    
                    // Connect widget update signal
                    if (plugin is ScriptPlugin) {
                        var sp = plugin as ScriptPlugin;
                        if (sp.is_widget) {
                            sp.updated.connect(() => queue_draw());
                        }
                    }
                }
            }
            
            // Re-apply running apps
            update_running_apps();
        }

        private int get_item_at(double click_x, double click_y) {
            string position = config.get_position();
            double click_pos = (position == "left" || position == "right") ? click_y : click_x;
            double mouse_pos = (position == "left" || position == "right") ? mouse_y : mouse_x;
            
            double pos = dock_padding;
            int i = 0;
            foreach (var item in items) {
                bool is_separator = item.is_plugin && item.plugin != null && item.plugin.id == "separator";
                
                double item_width;
                if (is_separator) {
                    item_width = 24;
                } else {
                    double item_center = pos + renderer.icon_size / 2.0;
                    double distance = hovering ? Math.fabs(mouse_pos - item_center) : 1000;
                    double scale = renderer.calculate_scale(distance, mouse_pos, hovering);
                    item_width = renderer.icon_size * scale + renderer.spacing;
                }
                
                if (click_pos >= pos && click_pos < pos + item_width) return i;
                pos += item_width;
                i++;
            }
            return -1;
        }

        public void debug_items() {
            stderr.printf("=== DOCK ITEMS ===\n");
            int i = 0;
            foreach (var item in items) {
                stderr.printf("[%d] id=%s, is_launcher=%s, is_plugin=%s\n", 
                    i, item.id, item.is_launcher.to_string(), item.is_plugin.to_string());
                i++;
            }
            stderr.printf("==================\n");
        }

        private void activate_item(int index) {
            debug_items();
            var item = items.nth_data(index);
            if (item == null) {
                stderr.printf("activate_item: item is null at index %d\n", index);
                return;
            }

            stderr.printf("activate_item: index=%d, %s, is_launcher=%s\n", index, item.id, item.is_launcher.to_string());

            if (item.is_launcher) {
                stderr.printf("Emitting launcher_requested signal\n");
                launcher_requested();
                return;
            }

            if (item.is_plugin && item.plugin != null) {
                item.plugin.activate();
                return;
            }

            if (item.running && item.windows.length() > 1) {
                show_window_list(item);
                return;
            }

            if (item.running && item.windows.length() > 0) {
                wm.activate_window(item.windows.nth_data(0));
            } else {
                launch_app(item);
                animate_bounce(index);
            }
        }

        private void show_window_list(DockItem item) {
            var menu = new Gtk.Menu();
            foreach (var window in item.windows) {
                var mi = new Gtk.MenuItem.with_label(window.get_name());
                mi.activate.connect(() => wm.activate_window(window));
                menu.append(mi);
            }
            menu.show_all();
            menu.popup_at_pointer(null);
        }

        private void animate_bounce(int index) {
            // Simple bounce animation using timeout
            int bounce_count = 0;
            Timeout.add(100, () => {
                bounce_count++;
                queue_draw();
                return bounce_count < 6;
            });
        }

        public void add_running_app(Wnck.Window window) {
            var app = app_manager.find_by_window(window);
            if (app == null) return;

            // Check if already in dock
            foreach (var item in items) {
                if (item.id == app.id) return;
            }

            var item = new DockItem(app.id, app.name, app.icon);
            item.desktop_file = app.desktop_file;
            item.running = true;
            item.windows.append(window);
            items.append(item);
            queue_draw();
        }

        public void set_auto_hide(bool enabled) {
            auto_hide = enabled;
            if (!enabled) {
                hidden = false;
                position_dock();
            }
        }
    }
}
