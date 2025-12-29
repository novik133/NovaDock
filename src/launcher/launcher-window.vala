namespace NovaDock {
    public class LauncherWindow : Gtk.Window {
        private AppManager app_manager;
        private ConfigManager config;
        private Gtk.SearchEntry search_entry;
        private Gtk.Grid app_grid;
        private Gtk.Box page_indicator;
        private List<weak AppInfo> filtered_apps;
        private int cols = 7;
        private int rows = 4;
        private int current_page = 0;
        private int total_pages = 1;
        private string current_category = "All";
        private string? drag_app_id = null;
        private string? open_folder_id = null;
        private Gtk.Window? folder_window = null;

        public LauncherWindow(AppManager app_manager, ConfigManager config) {
            Object(
                type: Gtk.WindowType.TOPLEVEL,
                decorated: false,
                skip_taskbar_hint: true,
                skip_pager_hint: true
            );

            this.app_manager = app_manager;
            this.config = config;
            filtered_apps = new List<weak AppInfo>();

            set_app_paintable(true);
            var visual = get_screen().get_rgba_visual();
            if (visual != null) set_visual(visual);

            fullscreen();
            set_keep_above(true);

            set_events(Gdk.EventMask.KEY_PRESS_MASK | Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.SCROLL_MASK);
            key_press_event.connect(on_key_press);
            button_press_event.connect(on_bg_click);
            scroll_event.connect(on_scroll);
            draw.connect(on_draw);

            build_ui();
            update_grid();
        }

        private void build_ui() {
            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 15);
            main_box.halign = Gtk.Align.FILL;
            main_box.valign = Gtk.Align.FILL;
            main_box.margin_top = 40;
            main_box.margin_bottom = 60;
            main_box.margin_start = 40;
            main_box.margin_end = 40;

            // Search bar
            var search_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            search_box.halign = Gtk.Align.CENTER;
            search_entry = new Gtk.SearchEntry();
            search_entry.placeholder_text = "Search applications...";
            search_entry.width_request = 400;
            search_entry.get_style_context().add_class("launcher-search");
            search_entry.search_changed.connect(on_search_changed);
            search_box.pack_start(search_entry, false, false, 0);
            main_box.pack_start(search_box, false, false, 0);

            // App grid
            app_grid = new Gtk.Grid();
            app_grid.row_spacing = 25;
            app_grid.column_spacing = 25;
            app_grid.halign = Gtk.Align.CENTER;
            app_grid.valign = Gtk.Align.CENTER;
            app_grid.vexpand = true;
            app_grid.hexpand = true;
            main_box.pack_start(app_grid, true, true, 0);

            // Page indicator dots
            page_indicator = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            page_indicator.halign = Gtk.Align.CENTER;
            page_indicator.margin_top = 15;
            main_box.pack_start(page_indicator, false, false, 0);

            add(main_box);

            apply_css();
        }

        private void filter_category(string category) {
            current_category = category;
            on_search_changed();
        }

        private void apply_css() {
            var css = new Gtk.CssProvider();
            try {
                css.load_from_data("""
                    .launcher-search {
                        font-size: 18px;
                        padding: 12px 20px;
                        border-radius: 10px;
                        background: rgba(255,255,255,0.15);
                        border: 1px solid rgba(255,255,255,0.2);
                        color: white;
                    }
                    .launcher-search:focus {
                        background: rgba(255,255,255,0.2);
                    }
                    .app-item {
                        padding: 10px;
                        border-radius: 12px;
                        background: transparent;
                    }
                    .app-item:hover {
                        background: rgba(255,255,255,0.1);
                    }
                    .app-item:selected {
                        background: rgba(255,255,255,0.2);
                    }
                    .app-name {
                        color: white;
                        font-size: 12px;
                    }
                    .category-btn {
                        background: transparent;
                        border: none;
                        color: rgba(255,255,255,0.7);
                        padding: 6px 12px;
                        border-radius: 6px;
                    }
                    .category-btn:hover {
                        background: rgba(255,255,255,0.1);
                        color: white;
                    }
                    .page-dot {
                        min-width: 10px;
                        min-height: 10px;
                        padding: 0;
                        border-radius: 5px;
                        background: rgba(255,255,255,0.4);
                        border: none;
                    }
                    .page-dot:hover {
                        background: rgba(255,255,255,0.6);
                    }
                    .page-dot.active {
                        background: rgba(255,255,255,0.9);
                    }
                    .folder-icon {
                        background: rgba(255,255,255,0.2);
                        border-radius: 12px;
                        border: none;
                        padding: 8px;
                    }
                    .folder-title {
                        font-size: 14px;
                        font-weight: bold;
                        color: white;
                        background: transparent;
                    }
                """);
                Gtk.StyleContext.add_provider_for_screen(
                    get_screen(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
                );
            } catch (Error e) {}
        }

        private bool on_draw(Cairo.Context cr) {
            cr.set_source_rgba(0.1, 0.1, 0.1, 0.92);
            cr.paint();
            return false;
        }

        private void on_search_changed() {
            string query = search_entry.text.down();
            filtered_apps = new List<weak AppInfo>();

            foreach (var app in app_manager.get_all_apps()) {
                // Skip hidden apps
                if (config.is_app_hidden(app.id)) continue;
                // Skip apps in folders (they show via folder icon)
                if (config.get_app_folder(app.id) != null) continue;
                
                bool matches_query = query == "" || app.name.down().contains(query) || app.id.down().contains(query);

                if (matches_query) {
                    filtered_apps.append(app);
                }
            }
            current_page = 0;
            update_grid();
        }

        private bool app_in_category(AppInfo app, string category) {
            string cat_lower = category.down();
            foreach (var c in app.categories) {
                if (c.down().contains(cat_lower)) return true;
            }
            return false;
        }

        private void update_grid() {
            // Clear grid
            app_grid.foreach((w) => app_grid.remove(w));

            // Sort alphabetically
            filtered_apps.sort((a, b) => strcmp(a.name, b.name));

            // Collect items: folders + apps
            var items = new List<string>();
            
            // Add folders first (only if not searching)
            if (search_entry.text == "") {
                foreach (var folder_id in config.get_folder_ids()) {
                    items.append("folder:" + folder_id);
                }
            }
            
            // Add apps
            foreach (var app in filtered_apps) {
                items.append("app:" + app.id);
            }

            int items_per_page = cols * rows;
            total_pages = (int)((items.length() + items_per_page - 1) / items_per_page);
            if (total_pages < 1) total_pages = 1;
            if (current_page >= total_pages) current_page = total_pages - 1;

            int start = current_page * items_per_page;
            int idx = 0;
            
            foreach (var item in items) {
                if (idx < start) {
                    idx++;
                    continue;
                }
                if (idx >= start + items_per_page) break;
                
                int pos = idx - start;
                int col = pos % cols;
                int row = pos / cols;
                
                Gtk.Widget widget;
                if (item.has_prefix("folder:")) {
                    widget = create_folder_item(item.substring(7));
                } else {
                    var app = app_manager.get_app(item.substring(4));
                    if (app != null) {
                        widget = create_app_item(app);
                    } else {
                        idx++;
                        continue;
                    }
                }
                app_grid.attach(widget, col, row, 1, 1);
                idx++;
            }
            
            app_grid.show_all();
            update_page_indicator();
        }

        private void update_page_indicator() {
            page_indicator.foreach((w) => page_indicator.remove(w));
            
            for (int i = 0; i < total_pages; i++) {
                var dot = new Gtk.Button();
                dot.set_size_request(12, 12);
                dot.get_style_context().add_class("page-dot");
                if (i == current_page) {
                    dot.get_style_context().add_class("active");
                }
                int page = i;
                dot.clicked.connect(() => {
                    current_page = page;
                    update_grid();
                });
                page_indicator.pack_start(dot, false, false, 0);
            }
            page_indicator.show_all();
        }

        private Gtk.Widget create_app_item(AppInfo app) {
            var btn = new Gtk.Button();
            btn.relief = Gtk.ReliefStyle.NONE;
            btn.get_style_context().add_class("app-item");
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
            box.set_data("app-id", app.id);

            var icon = new Gtk.Image();
            try {
                var theme = Gtk.IconTheme.get_default();
                var pixbuf = theme.load_icon(app.icon, 64, Gtk.IconLookupFlags.FORCE_SIZE);
                icon.set_from_pixbuf(pixbuf);
            } catch (Error e) {
                icon.set_from_icon_name("application-x-executable", Gtk.IconSize.DIALOG);
            }

            var label = new Gtk.Label(app.name);
            label.get_style_context().add_class("app-name");
            label.max_width_chars = 12;
            label.ellipsize = Pango.EllipsizeMode.END;

            box.pack_start(icon, false, false, 0);
            box.pack_start(label, false, false, 0);
            
            btn.add(box);
            btn.set_size_request(100, 100);
            
            // Left click - launch
            btn.clicked.connect(() => {
                app.launch();
                hide();
            });
            
            // Right click - context menu
            btn.button_press_event.connect((event) => {
                if (event.button == 3) {
                    show_app_menu(app, event);
                    return true;
                }
                return false;
            });
            
            // Drag source
            Gtk.drag_source_set(btn, Gdk.ModifierType.BUTTON1_MASK, {}, Gdk.DragAction.MOVE);
            Gtk.drag_source_add_text_targets(btn);
            btn.drag_data_get.connect((ctx, data, info, time) => {
                data.set_text("app:" + app.id, -1);
            });
            
            // Drop target (to create folder)
            Gtk.drag_dest_set(btn, Gtk.DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
            Gtk.drag_dest_add_text_targets(btn);
            btn.drag_data_received.connect((ctx, x, y, data, info, time) => {
                string? dropped = data.get_text();
                if (dropped != null && dropped.has_prefix("app:")) {
                    string other_id = dropped.substring(4);
                    if (other_id != app.id) {
                        // Create new folder
                        string folder_id = "folder_%lld".printf(GLib.get_real_time());
                        config.create_folder(folder_id, "New Folder", {other_id, app.id});
                        on_search_changed();
                    }
                }
            });

            return btn;
        }

        private void show_app_menu(AppInfo app, Gdk.EventButton event) {
            var menu = new Gtk.Menu();
            
            var hide_item = new Gtk.MenuItem.with_label("Hide from Launcher");
            hide_item.activate.connect(() => {
                config.hide_app(app.id);
                on_search_changed();
            });
            menu.append(hide_item);
            
            menu.show_all();
            menu.popup_at_pointer(event);
        }

        private Gtk.Widget create_folder_item(string folder_id) {
            var btn = new Gtk.Button();
            btn.relief = Gtk.ReliefStyle.NONE;
            btn.get_style_context().add_class("app-item");
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
            
            // Create folder icon with mini app icons
            var icon_box = new Gtk.Grid();
            icon_box.row_spacing = 2;
            icon_box.column_spacing = 2;
            icon_box.halign = Gtk.Align.CENTER;
            
            var apps = config.get_folder_apps(folder_id);
            int i = 0;
            foreach (var app_id in apps) {
                if (i >= 4) break;
                var app = app_manager.get_app(app_id);
                if (app != null) {
                    var icon = new Gtk.Image();
                    try {
                        var theme = Gtk.IconTheme.get_default();
                        var pixbuf = theme.load_icon(app.icon, 24, Gtk.IconLookupFlags.FORCE_SIZE);
                        icon.set_from_pixbuf(pixbuf);
                    } catch (Error e) {
                        icon.set_from_icon_name("application-x-executable", Gtk.IconSize.LARGE_TOOLBAR);
                    }
                    icon_box.attach(icon, i % 2, i / 2, 1, 1);
                    i++;
                }
            }
            
            // Folder background
            var folder_frame = new Gtk.Frame(null);
            folder_frame.get_style_context().add_class("folder-icon");
            folder_frame.set_size_request(64, 64);
            folder_frame.add(icon_box);

            var label = new Gtk.Label(config.get_folder_name(folder_id));
            label.get_style_context().add_class("app-name");
            label.max_width_chars = 12;
            label.ellipsize = Pango.EllipsizeMode.END;

            box.pack_start(folder_frame, false, false, 0);
            box.pack_start(label, false, false, 0);
            
            btn.add(box);
            btn.set_size_request(100, 100);
            
            // Click to open folder
            btn.clicked.connect(() => {
                open_folder(folder_id);
            });
            
            // Right click menu
            btn.button_press_event.connect((event) => {
                if (event.button == 3) {
                    show_folder_menu(folder_id, event);
                    return true;
                }
                return false;
            });
            
            // Drop target
            Gtk.drag_dest_set(btn, Gtk.DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
            Gtk.drag_dest_add_text_targets(btn);
            btn.drag_data_received.connect((ctx, x, y, data, info, time) => {
                string? app_id = data.get_text();
                if (app_id != null && app_id.has_prefix("app:")) {
                    config.add_app_to_folder(folder_id, app_id.substring(4));
                    on_search_changed();
                }
            });

            return btn;
        }

        private void show_folder_menu(string folder_id, Gdk.EventButton event) {
            var menu = new Gtk.Menu();
            
            var rename_item = new Gtk.MenuItem.with_label("Rename Folder");
            rename_item.activate.connect(() => {
                rename_folder_dialog(folder_id);
            });
            menu.append(rename_item);
            
            var delete_item = new Gtk.MenuItem.with_label("Delete Folder");
            delete_item.activate.connect(() => {
                config.delete_folder(folder_id);
                on_search_changed();
            });
            menu.append(delete_item);
            
            menu.show_all();
            menu.popup_at_pointer(event);
        }

        private void rename_folder_dialog(string folder_id) {
            var dialog = new Gtk.Dialog.with_buttons("Rename Folder", this,
                Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                "_Cancel", Gtk.ResponseType.CANCEL,
                "_OK", Gtk.ResponseType.OK);
            
            var entry = new Gtk.Entry();
            entry.text = config.get_folder_name(folder_id);
            entry.margin = 20;
            dialog.get_content_area().add(entry);
            dialog.show_all();
            
            dialog.response.connect((response) => {
                if (response == Gtk.ResponseType.OK) {
                    config.rename_folder(folder_id, entry.text);
                    on_search_changed();
                }
                dialog.destroy();
            });
        }

        private void open_folder(string folder_id) {
            if (folder_window != null) {
                folder_window.destroy();
            }
            
            folder_window = new Gtk.Window(Gtk.WindowType.POPUP);
            folder_window.set_transient_for(this);
            folder_window.set_decorated(false);
            folder_window.set_size_request(500, 450);
            
            var screen = get_screen();
            var visual = screen.get_rgba_visual();
            if (visual != null) folder_window.set_visual(visual);
            folder_window.set_app_paintable(true);
            
            folder_window.draw.connect((cr) => {
                int w = folder_window.get_allocated_width();
                int h = folder_window.get_allocated_height();
                double r = 20;
                
                cr.new_path();
                cr.arc(r, r, r, Math.PI, 3 * Math.PI / 2);
                cr.arc(w - r, r, r, 3 * Math.PI / 2, 0);
                cr.arc(w - r, h - r, r, 0, Math.PI / 2);
                cr.arc(r, h - r, r, Math.PI / 2, Math.PI);
                cr.close_path();
                
                cr.set_source_rgba(0.2, 0.2, 0.2, 0.95);
                cr.fill();
                return false;
            });
            
            var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
            vbox.margin = 15;
            
            // Folder name (editable)
            var name_entry = new Gtk.Entry();
            name_entry.text = config.get_folder_name(folder_id);
            name_entry.halign = Gtk.Align.CENTER;
            name_entry.has_frame = false;
            name_entry.get_style_context().add_class("folder-title");
            name_entry.activate.connect(() => {
                config.rename_folder(folder_id, name_entry.text);
            });
            name_entry.focus_out_event.connect(() => {
                config.rename_folder(folder_id, name_entry.text);
                return false;
            });
            vbox.pack_start(name_entry, false, false, 0);
            
            // Apps grid
            var grid = new Gtk.Grid();
            grid.row_spacing = 10;
            grid.column_spacing = 10;
            grid.halign = Gtk.Align.CENTER;
            
            var apps = config.get_folder_apps(folder_id);
            int i = 0;
            foreach (var app_id in apps) {
                var app = app_manager.get_app(app_id);
                if (app != null) {
                    var item = create_folder_app_item(app, folder_id);
                    grid.attach(item, i % 4, i / 4, 1, 1);
                    i++;
                }
            }
            vbox.pack_start(grid, true, true, 0);
            
            folder_window.add(vbox);
            
            // Position in center
            int win_x, win_y, win_w, win_h;
            get_position(out win_x, out win_y);
            get_size(out win_w, out win_h);
            folder_window.move(win_x + (win_w - 500) / 2, win_y + (win_h - 450) / 2);
            
            folder_window.show_all();
            
            // Close on click outside
            folder_window.focus_out_event.connect(() => {
                folder_window.destroy();
                folder_window = null;
                return false;
            });
        }

        private Gtk.Widget create_folder_app_item(AppInfo app, string folder_id) {
            var btn = new Gtk.Button();
            btn.relief = Gtk.ReliefStyle.NONE;
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
            
            var icon = new Gtk.Image();
            try {
                var theme = Gtk.IconTheme.get_default();
                var pixbuf = theme.load_icon(app.icon, 48, Gtk.IconLookupFlags.FORCE_SIZE);
                icon.set_from_pixbuf(pixbuf);
            } catch (Error e) {
                icon.set_from_icon_name("application-x-executable", Gtk.IconSize.DIALOG);
            }
            
            var label = new Gtk.Label(app.name);
            label.max_width_chars = 8;
            label.ellipsize = Pango.EllipsizeMode.END;
            label.get_style_context().add_class("app-name");
            
            box.pack_start(icon, false, false, 0);
            box.pack_start(label, false, false, 0);
            btn.add(box);
            
            btn.clicked.connect(() => {
                app.launch();
                if (folder_window != null) folder_window.destroy();
                folder_window = null;
                hide();
            });
            
            // Drag source - drag out of folder
            Gtk.drag_source_set(btn, Gdk.ModifierType.BUTTON1_MASK, {}, Gdk.DragAction.MOVE);
            Gtk.drag_source_add_text_targets(btn);
            btn.drag_data_get.connect((ctx, data, info, time) => {
                data.set_text("folder_app:" + folder_id + ":" + app.id, -1);
            });
            btn.drag_end.connect((ctx) => {
                // Check if dropped outside folder - remove from folder
                if (folder_window != null) {
                    int fx, fy, fw, fh;
                    folder_window.get_position(out fx, out fy);
                    folder_window.get_size(out fw, out fh);
                    
                    int mx, my;
                    var display = Gdk.Display.get_default();
                    var seat = display.get_default_seat();
                    var pointer = seat.get_pointer();
                    pointer.get_position(null, out mx, out my);
                    
                    if (mx < fx || mx > fx + fw || my < fy || my > fy + fh) {
                        config.remove_app_from_folder(folder_id, app.id);
                        // Delete folder if 1 or 0 apps remain
                        if (config.get_folder_apps(folder_id).length <= 1) {
                            config.delete_folder(folder_id);
                        }
                        folder_window.destroy();
                        folder_window = null;
                        on_search_changed();
                    }
                }
            });
            
            btn.button_press_event.connect((event) => {
                if (event.button == 3) {
                    var menu = new Gtk.Menu();
                    var remove = new Gtk.MenuItem.with_label("Remove from Folder");
                    remove.activate.connect(() => {
                        config.remove_app_from_folder(folder_id, app.id);
                        // Delete folder if 1 or 0 apps remain
                        if (config.get_folder_apps(folder_id).length <= 1) {
                            config.delete_folder(folder_id);
                        }
                        if (folder_window != null) folder_window.destroy();
                        folder_window = null;
                        on_search_changed();
                    });
                    menu.append(remove);
                    menu.show_all();
                    menu.popup_at_pointer(event);
                    return true;
                }
                return false;
            });
            
            return btn;
        }

        private void on_app_activated() {
            // Handled by button click
        }

        private bool on_key_press(Gdk.EventKey event) {
            if (event.keyval == Gdk.Key.Escape) {
                if (folder_window != null) {
                    folder_window.destroy();
                    folder_window = null;
                    return true;
                }
                hide();
                return true;
            }
            if (event.keyval == Gdk.Key.Left) {
                if (current_page > 0) {
                    current_page--;
                    update_grid();
                }
                return true;
            }
            if (event.keyval == Gdk.Key.Right) {
                if (current_page < total_pages - 1) {
                    current_page++;
                    update_grid();
                }
                return true;
            }
            if (!search_entry.has_focus) {
                search_entry.grab_focus();
            }
            return false;
        }

        private bool on_bg_click(Gdk.EventButton event) {
            // Close folder popup if open
            if (folder_window != null) {
                folder_window.destroy();
                folder_window = null;
                return true;
            }
            // Close if clicking outside app grid
            int w, h;
            get_size(out w, out h);
            if (event.x < 50 || event.x > w - 50 || event.y < 50 || event.y > h - 50) {
                hide();
                return true;
            }
            return false;
        }

        private bool on_scroll(Gdk.EventScroll event) {
            if (event.direction == Gdk.ScrollDirection.LEFT || event.direction == Gdk.ScrollDirection.UP) {
                if (current_page > 0) {
                    current_page--;
                    update_grid();
                }
                return true;
            }
            if (event.direction == Gdk.ScrollDirection.RIGHT || event.direction == Gdk.ScrollDirection.DOWN) {
                if (current_page < total_pages - 1) {
                    current_page++;
                    update_grid();
                }
                return true;
            }
            // Handle smooth scrolling
            if (event.direction == Gdk.ScrollDirection.SMOOTH) {
                if (event.delta_x > 0.5 || event.delta_y > 0.5) {
                    if (current_page < total_pages - 1) {
                        current_page++;
                        update_grid();
                    }
                } else if (event.delta_x < -0.5 || event.delta_y < -0.5) {
                    if (current_page > 0) {
                        current_page--;
                        update_grid();
                    }
                }
                return true;
            }
            return false;
        }

        public void toggle() {
            if (visible) {
                hide();
            } else {
                search_entry.text = "";
                on_search_changed();
                show_all();
                search_entry.grab_focus();
            }
        }
    }
}
