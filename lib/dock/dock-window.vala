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

        private int drag_index = -1;
        private double drag_start_x;

        private bool use_layer_shell = false;

        private const Gtk.TargetEntry[] DROP_TARGETS = {
            { "text/uri-list", 0, 0 }
        };

        public DockWindow(Gtk.Application app, AppManager app_manager) {
            Object(application: app);
            
            // Check if layer-shell works
            use_layer_shell = GtkLayerShell.is_supported();
            stderr.printf("Layer shell supported: %s\n", use_layer_shell.to_string());
            
            if (use_layer_shell) {
                GtkLayerShell.init_for_window(this);
                GtkLayerShell.set_layer(this, GtkLayerShell.Layer.TOP);
                GtkLayerShell.set_anchor(this, GtkLayerShell.Edge.BOTTOM, true);
                GtkLayerShell.set_namespace(this, "novadock");
            }
            
            // Always set these
            set_decorated(false);
            if (!use_layer_shell) {
                // Override redirect bypasses compositor entirely
                realize.connect(() => {
                    get_window().set_override_redirect(true);
                });
            }

            this.app_manager = app_manager;
            renderer = new DockRenderer();
            config = new ConfigManager();
            plugin_manager = new PluginManager(config);
            theme_manager = new ThemeManager();
            items = new List<DockItem>();

            load_theme();
            
            var launcher_item = new DockItem("novadock-launcher", "Applications", "view-app-grid-symbolic");
            launcher_item.pinned = true;
            launcher_item.is_launcher = true;
            items.append(launcher_item);

            load_pinned_apps();
            load_plugins();

            // Window setup
            set_skip_taskbar_hint(true);
            set_skip_pager_hint(true);
            set_keep_above(true);
            if (!use_layer_shell) {
                stick();
                get_screen().size_changed.connect(position_dock);
            }

            set_app_paintable(true);
            var visual = get_screen().get_rgba_visual();
            if (visual != null) set_visual(visual);

            set_events(Gdk.EventMask.POINTER_MOTION_MASK |
                       Gdk.EventMask.LEAVE_NOTIFY_MASK |
                       Gdk.EventMask.ENTER_NOTIFY_MASK |
                       Gdk.EventMask.BUTTON_PRESS_MASK |
                       Gdk.EventMask.BUTTON_RELEASE_MASK);

            // Enable drag-and-drop for .desktop files
            Gtk.drag_dest_set(this, Gtk.DestDefaults.ALL, DROP_TARGETS, Gdk.DragAction.COPY);
            drag_data_received.connect(on_drag_data_received);

            set_default_size(calculate_width(), base_height);

            if (!use_layer_shell) {
                realize.connect(position_dock);
            }

            wm = new WindowManager();
            wm.windows_changed.connect(update_running_apps);

            draw.connect(on_draw);
            motion_notify_event.connect(on_motion);
            leave_notify_event.connect(on_leave);
            enter_notify_event.connect(on_enter);
            button_press_event.connect(on_button_press);
            button_release_event.connect(on_button_release);

            auto_hide = config.get_auto_hide();
            renderer.icon_size = config.get_icon_size();
            renderer.magnification = config.get_magnification();
        }

        private void load_plugins() {
            if (config.get_plugin_enabled("separator")) {
                var sep = plugin_manager.get_plugin("separator");
                if (sep != null) items.append(new DockItem.from_plugin(sep));
            }
            if (config.get_plugin_enabled("show-desktop")) {
                var p = plugin_manager.get_plugin("show-desktop");
                if (p != null) items.append(new DockItem.from_plugin(p));
            }
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
        }

        private void load_pinned_apps() {
            foreach (var entry in config.get_pinned_apps()) {
                DockItem? item = null;
                
                // Check if it's a path to a .desktop file
                if (entry.has_suffix(".desktop") && FileUtils.test(entry, FileTest.EXISTS)) {
                    var app = new AppInfo.from_desktop_file(entry);
                    if (app.exec != "") {
                        item = new DockItem(app.id, app.name, app.icon);
                        item.desktop_file = app.desktop_file;
                    }
                } else {
                    // Try as app ID
                    var app = app_manager.get_app(entry);
                    if (app != null) {
                        item = new DockItem(app.id, app.name, app.icon);
                        item.desktop_file = app.desktop_file;
                    }
                }
                
                if (item != null) {
                    item.pinned = true;
                    items.append(item);
                }
            }
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
                if (item.pinned && !item.is_launcher && !item.is_plugin) {
                    // Save desktop file path if available, otherwise just ID
                    if (item.desktop_file != null && item.desktop_file != "")
                        pinned += item.desktop_file;
                    else
                        pinned += item.id;
                }
            }
            config.set_pinned_apps(pinned);
        }

        private void load_theme() {
            current_theme = theme_manager.get_theme(config.get_theme());
            if (current_theme == null) current_theme = theme_manager.get_theme("default");
            renderer.theme = current_theme;
        }

        private int calculate_width() {
            int total = dock_padding * 2;
            foreach (var item in items) {
                if (item.is_plugin && item.plugin != null && item.plugin.id == "separator") {
                    total += 24;
                } else {
                    // Use max magnified size so window never needs to resize
                    total += (int)(renderer.icon_size * renderer.magnification) + renderer.spacing;
                }
            }
            return int.max(total, 200);
        }

        private void position_dock() {
            if (use_layer_shell) {
                // Layer shell handles positioning
                resize(calculate_width(), base_height);
                return;
            }
            
            // X11 positioning
            var screen = get_screen();
            int screen_width = screen.get_width();
            int screen_height = screen.get_height();
            
            int dock_width = calculate_width();
            int hide_offset = hidden ? base_height - 4 : 0;

            int x = (screen_width - dock_width) / 2;
            int y = screen_height - base_height + hide_offset;

            resize(dock_width, base_height);
            move(x, y);
        }

        private void update_running_apps() {
            var windows = wm.get_windows();

            foreach (var item in items) {
                if (!item.is_plugin && !item.is_launcher) {
                    item.running = false;
                    item.windows = new List<weak Wnck.Window>();
                }
            }

            foreach (var window in windows) {
                var app = app_manager.find_by_window(window);
                if (app == null) {
                    stderr.printf("No app found for window: %s (class: %s)\n", 
                        window.get_name(), window.get_class_group_name() ?? "null");
                    continue;
                }

                bool found = false;
                foreach (var item in items) {
                    if (item.is_launcher || item.is_plugin) continue;
                    if (item.id == app.id) {
                        item.running = true;
                        item.windows.append(window);
                        found = true;
                        break;
                    }
                }

                if (!found) {
                    stderr.printf("App '%s' not found in dock items, adding new\n", app.id);
                    var item = new DockItem(app.id, app.name, app.icon);
                    item.desktop_file = app.desktop_file;
                    item.running = true;
                    item.windows.append(window);
                    int sep_idx = find_separator_index();
                    if (sep_idx >= 0) items.insert(item, sep_idx);
                    else items.append(item);
                }
            }

            var to_remove = new List<DockItem>();
            foreach (var item in items) {
                if (!item.pinned && !item.running && !item.is_plugin && !item.is_launcher)
                    to_remove.append(item);
            }
            foreach (var item in to_remove) items.remove(item);

            position_dock();
            queue_draw();
        }

        private int find_separator_index() {
            int i = 0;
            foreach (var item in items) {
                if (item.is_plugin && item.plugin != null && item.plugin.id == "separator") return i;
                i++;
            }
            return -1;
        }

        private bool on_draw(Cairo.Context cr) {
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.set_source_rgba(0, 0, 0, 0);
            cr.paint();
            cr.set_operator(Cairo.Operator.OVER);
            
            double dock_width = get_current_dock_width();
            draw_dock_background(cr, dock_width);
            draw_items(cr);
            
            // Set input shape to match visible dock area
            update_input_shape(dock_width);
            
            return false;
        }
        
        private void update_input_shape(double dock_width) {
            var window = get_window();
            if (window == null) return;
            
            int width = get_allocated_width();
            int height = get_allocated_height();
            
            var region = new Cairo.Region.rectangle({
                (int)((width - dock_width) / 2.0),
                height - icon_area_height - 4,
                (int)dock_width,
                icon_area_height + 4
            });
            window.input_shape_combine_region(region, 0, 0);
        }

        private double get_current_dock_width() {
            int n = (int)items.length();
            double[] scales = new double[n];
            double[] base_centers = new double[n];
            
            // Calculate base positions
            double pos = 0;
            int i = 0;
            foreach (var item in items) {
                bool is_sep = item.is_plugin && item.plugin != null && item.plugin.id == "separator";
                if (is_sep) {
                    base_centers[i] = pos + 12;
                    pos += 24;
                } else {
                    base_centers[i] = pos + renderer.icon_size / 2.0;
                    pos += renderer.icon_size + renderer.spacing;
                }
                i++;
            }
            
            double base_width = pos;
            int width = get_allocated_width();
            double start_x = (width - base_width) / 2.0;
            
            // Calculate scales
            i = 0;
            foreach (var item in items) {
                bool is_sep = item.is_plugin && item.plugin != null && item.plugin.id == "separator";
                if (is_sep) {
                    scales[i] = 1.0;
                } else {
                    double center_x = start_x + base_centers[i];
                    double dist = hovering ? Math.fabs(mouse_x - center_x) : 1000;
                    scales[i] = renderer.calculate_scale(dist, mouse_x, hovering);
                }
                i++;
            }
            
            // Calculate actual width with magnification
            double actual_width = 0;
            i = 0;
            foreach (var item in items) {
                bool is_sep = item.is_plugin && item.plugin != null && item.plugin.id == "separator";
                if (is_sep) {
                    actual_width += 24;
                } else {
                    actual_width += renderer.icon_size * scales[i] + renderer.spacing;
                }
                i++;
            }
            
            return actual_width + dock_padding * 2;
        }

        private void draw_dock_background(Cairo.Context cr, double dock_width) {
            int width = get_allocated_width();
            int height = get_allocated_height();
            double radius = current_theme != null ? current_theme.corner_radius : 16;
            double margin = 4;

            // Center the background based on actual dock content width
            double x = (width - dock_width) / 2.0 + margin;
            double y = height - icon_area_height - margin;
            double w = dock_width - margin * 2;
            double h = icon_area_height;

            cr.new_path();
            cr.arc(x + w - radius, y + radius, radius, -Math.PI / 2, 0);
            cr.arc(x + w - radius, y + h - radius, radius, 0, Math.PI / 2);
            cr.arc(x + radius, y + h - radius, radius, Math.PI / 2, Math.PI);
            cr.arc(x + radius, y + radius, radius, Math.PI, 3 * Math.PI / 2);
            cr.close_path();

            if (current_theme != null)
                cr.set_source_rgba(current_theme.bg_red, current_theme.bg_green, current_theme.bg_blue, current_theme.bg_alpha);
            else
                cr.set_source_rgba(0.15, 0.15, 0.15, 0.75);
            cr.fill_preserve();

            if (current_theme != null) {
                cr.set_source_rgba(current_theme.border_red, current_theme.border_green, current_theme.border_blue, current_theme.border_alpha);
                cr.set_line_width(current_theme.border_width);
            } else {
                cr.set_source_rgba(1, 1, 1, 0.15);
                cr.set_line_width(1);
            }
            cr.stroke();
        }

        private void draw_items(Cairo.Context cr) {
            int height = get_allocated_height();
            int width = get_allocated_width();
            double icon_baseline = height - 10 - renderer.icon_size / 2.0;

            int n = (int)items.length();
            double[] scales = new double[n];
            
            // Calculate base width and positions for scale calculation
            double base_width = 0;
            foreach (var item in items) {
                bool is_sep = item.is_plugin && item.plugin != null && item.plugin.id == "separator";
                base_width += is_sep ? 24 : renderer.icon_size + renderer.spacing;
            }
            
            // Calculate scales based on base positions (centered in window)
            double base_x = (width - base_width) / 2.0;
            double pos = base_x;
            int i = 0;
            foreach (var item in items) {
                bool is_sep = item.is_plugin && item.plugin != null && item.plugin.id == "separator";
                double item_width = is_sep ? 24 : renderer.icon_size + renderer.spacing;
                double center = pos + item_width / 2.0;
                if (is_sep) {
                    scales[i] = 1.0;
                } else {
                    double dist = hovering ? Math.fabs(mouse_x - center) : 1000;
                    scales[i] = renderer.calculate_scale(dist, mouse_x, hovering);
                }
                pos += item_width;
                i++;
            }
            
            // Calculate actual width with current scales
            double actual_width = 0;
            i = 0;
            foreach (var item in items) {
                bool is_sep = item.is_plugin && item.plugin != null && item.plugin.id == "separator";
                actual_width += is_sep ? 24 : renderer.icon_size * scales[i] + renderer.spacing;
                i++;
            }
            
            // Draw items centered
            double start_x = (width - actual_width) / 2.0;
            pos = start_x;
            i = 0;
            foreach (var item in items) {
                bool is_sep = item.is_plugin && item.plugin != null && item.plugin.id == "separator";
                double sz = renderer.icon_size * scales[i];
                double x, item_width;
                if (is_sep) {
                    x = pos + 12;
                    item_width = 24;
                } else {
                    x = pos + sz / 2.0;
                    item_width = sz + renderer.spacing;
                }
                double y = icon_baseline - (sz - renderer.icon_size) / 2.0;
                renderer.draw_item(cr, item, x, y, scales[i], hovering);
                pos += item_width;
                i++;
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
            if (hide_timeout_id != 0) { Source.remove(hide_timeout_id); hide_timeout_id = 0; }
            if (auto_hide && hidden) { hidden = false; position_dock(); }
            queue_draw();
            return true;
        }

        private bool on_leave(Gdk.EventCrossing event) {
            hovering = false;
            mouse_x = -1;
            mouse_y = -1;
            position_dock();
            if (auto_hide && !hidden) {
                hide_timeout_id = Timeout.add(config.get_hide_delay(), () => {
                    hidden = true;
                    position_dock();
                    hide_timeout_id = 0;
                    return false;
                });
            }
            queue_draw();
            return true;
        }

        private void on_drag_data_received(Gdk.DragContext context, int x, int y,
                                           Gtk.SelectionData data, uint info, uint time) {
            var uris = data.get_uris();
            foreach (var uri in uris) {
                if (!uri.has_suffix(".desktop")) continue;
                
                string path;
                try {
                    path = Filename.from_uri(uri);
                } catch (Error e) { continue; }
                
                var app = new AppInfo.from_desktop_file(path);
                if (app.exec == "") continue;
                
                // Check if already in dock
                bool exists = false;
                foreach (var item in items) {
                    if (item.id == app.id) { exists = true; break; }
                }
                if (exists) continue;
                
                var item = new DockItem(app.id, app.name, app.icon);
                item.desktop_file = app.desktop_file;
                item.pinned = true;
                
                int sep_idx = find_separator_index();
                if (sep_idx >= 0) items.insert(item, sep_idx);
                else items.append(item);
            }
            save_pinned_apps();
            position_dock();
            queue_draw();
            Gtk.drag_finish(context, true, false, time);
        }

        private bool on_button_press(Gdk.EventButton event) {
            if (event.button == 1) {
                drag_start_x = event.x;
                drag_index = get_item_at(event.x);
            } else if (event.button == 3) {
                show_context_menu(event);
            }
            return true;
        }

        private bool on_button_release(Gdk.EventButton event) {
            if (event.button == 1 && drag_index >= 0) {
                int target = get_item_at(event.x);
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
            return true;
        }

        private int get_item_at(double click_x) {
            int width = get_allocated_width();
            
            // Calculate total width first
            double total_width = 0;
            foreach (var item in items) {
                bool is_sep = item.is_plugin && item.plugin != null && item.plugin.id == "separator";
                if (is_sep) {
                    total_width += 24;
                } else {
                    total_width += renderer.icon_size + renderer.spacing;
                }
            }
            
            double start_x = (width - total_width) / 2.0;
            double pos = start_x;
            int i = 0;
            foreach (var item in items) {
                bool is_sep = item.is_plugin && item.plugin != null && item.plugin.id == "separator";
                double w = is_sep ? 24 : renderer.icon_size + renderer.spacing;
                if (click_x >= pos && click_x < pos + w) return i;
                pos += w;
                i++;
            }
            return -1;
        }

        private void activate_item(int index) {
            var item = items.nth_data(index);
            if (item == null) return;

            if (item.is_launcher) { launcher_requested(); return; }
            if (item.is_plugin && item.plugin != null) { item.plugin.activate(); return; }
            if (item.running && item.windows.length() > 1) { show_window_list(item); return; }
            if (item.running && item.windows.length() > 0) {
                wm.activate_window(item.windows.nth_data(0));
            } else {
                var app = app_manager.get_app(item.id);
                if (app != null) app.launch();
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

        private void show_context_menu(Gdk.EventButton event) {
            int index = get_item_at(event.x);
            if (index < 0) return;
            var item = items.nth_data(index);
            if (item == null) return;

            if (item.is_plugin && item.plugin != null && item.plugin.has_menu) {
                var m = item.plugin.get_menu();
                if (m != null) { m.popup_at_pointer(event); return; }
            }

            context_menu = new Gtk.Menu();

            if (item.running) {
                var nw = new Gtk.MenuItem.with_label("Open New Window");
                nw.activate.connect(() => { var a = app_manager.get_app(item.id); if (a != null) a.launch(); });
                context_menu.append(nw);
                context_menu.append(new Gtk.SeparatorMenuItem());
            }

            if (item.pinned) {
                var unpin = new Gtk.MenuItem.with_label("Unpin from Dock");
                unpin.activate.connect(() => {
                    if (item.running) item.pinned = false; else items.remove(item);
                    save_pinned_apps(); queue_draw();
                });
                context_menu.append(unpin);
            } else {
                var pin = new Gtk.MenuItem.with_label("Pin to Dock");
                pin.activate.connect(() => { item.pinned = true; save_pinned_apps(); queue_draw(); });
                context_menu.append(pin);
            }

            if (item.running && item.windows.length() > 0) {
                context_menu.append(new Gtk.SeparatorMenuItem());
                var cl = new Gtk.MenuItem.with_label("Close Window");
                cl.activate.connect(() => item.windows.nth_data(0).close(Gtk.get_current_event_time()));
                context_menu.append(cl);
            }

            context_menu.append(new Gtk.SeparatorMenuItem());
            var st = new Gtk.MenuItem.with_label("Dock Settings...");
            st.activate.connect(() => settings_requested());
            context_menu.append(st);

            context_menu.show_all();
            context_menu.popup_at_pointer(event);
        }

        public void reload_settings() {
            config = new ConfigManager();
            renderer.icon_size = config.get_icon_size();
            renderer.magnification = config.get_magnification();
            auto_hide = config.get_auto_hide();
            load_theme();
            
            items = new List<DockItem>();
            var launcher_item = new DockItem("novadock-launcher", "Applications", "view-app-grid-symbolic");
            launcher_item.pinned = true;
            launcher_item.is_launcher = true;
            items.append(launcher_item);
            load_pinned_apps();
            load_plugins();
            
            if (!auto_hide && hidden) hidden = false;
            position_dock();
            queue_draw();
        }
    }
}
