namespace NovaDock {
    public class SettingsWindow : Gtk.Window {
        private ConfigManager config;
        private AppManager app_manager;
        private ThemeManager theme_manager;
        private PluginManager plugin_manager;
        private Gtk.ListBox hidden_list;
        private Gtk.ComboBoxText theme_combo;
        private Gtk.Grid plugins_grid;
        public signal void settings_changed();

        // Pending settings
        private string pending_position;
        private int pending_icon_size;
        private double pending_magnification;
        private string pending_theme;
        private bool pending_auto_hide;
        private int pending_hide_delay;
        private bool pending_multi_monitor;
        private bool pending_separator;
        private bool pending_show_desktop;
        private bool pending_trash;

        public SettingsWindow(ConfigManager config, AppManager app_manager) {
            Object(
                title: "NovaDock Settings",
                default_width: 450,
                default_height: 450,
                resizable: false
            );
            this.config = config;
            this.app_manager = app_manager;
            this.theme_manager = new ThemeManager();
            this.plugin_manager = new PluginManager(config);
            load_pending_settings();
            build_ui();
            
            this.show.connect(() => update_hidden_list());
        }

        private void load_pending_settings() {
            pending_position = config.get_position();
            pending_icon_size = config.get_icon_size();
            pending_magnification = config.get_magnification();
            pending_theme = config.get_theme();
            pending_auto_hide = config.get_auto_hide();
            pending_hide_delay = config.get_hide_delay();
            pending_multi_monitor = config.get_multi_monitor();
            pending_separator = config.get_plugin_enabled("separator");
            pending_show_desktop = config.get_plugin_enabled("show-desktop");
            pending_trash = config.get_plugin_enabled("trash");
        }

        private void save_settings() {
            config.set_position(pending_position);
            config.set_icon_size(pending_icon_size);
            config.set_magnification(pending_magnification);
            config.set_theme(pending_theme);
            config.set_auto_hide(pending_auto_hide);
            config.set_hide_delay(pending_hide_delay);
            config.set_multi_monitor(pending_multi_monitor);
            config.set_plugin_enabled("separator", pending_separator);
            config.set_plugin_enabled("show-desktop", pending_show_desktop);
            config.set_plugin_enabled("trash", pending_trash);
            settings_changed();
        }

        private void build_ui() {
            var header = new Gtk.HeaderBar();
            header.title = "Settings";
            header.show_close_button = false;
            
            var cancel_btn = new Gtk.Button.with_label("Cancel");
            cancel_btn.clicked.connect(() => {
                load_pending_settings();
                close();
            });
            header.pack_start(cancel_btn);
            
            var save_btn = new Gtk.Button.with_label("Save");
            save_btn.get_style_context().add_class("suggested-action");
            save_btn.clicked.connect(() => save_settings());
            header.pack_end(save_btn);
            
            set_titlebar(header);

            var notebook = new Gtk.Notebook();
            notebook.margin = 12;

            notebook.append_page(create_appearance_tab(), new Gtk.Label("Appearance"));
            notebook.append_page(create_behavior_tab(), new Gtk.Label("Behavior"));
            notebook.append_page(create_plugins_tab(), new Gtk.Label("Plugins"));
            notebook.append_page(create_hidden_apps_tab(), new Gtk.Label("Hidden Apps"));
            notebook.append_page(create_about_tab(), new Gtk.Label("About"));

            add(notebook);
        }

        private Gtk.Widget create_appearance_tab() {
            var grid = new Gtk.Grid();
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.margin = 16;

            int row = 0;

            // Position
            grid.attach(new Gtk.Label("Position:") { halign = Gtk.Align.END }, 0, row, 1, 1);
            var position_combo = new Gtk.ComboBoxText();
            position_combo.append("bottom", "Bottom");
            position_combo.append("left", "Left");
            position_combo.append("right", "Right");
            position_combo.active_id = pending_position;
            position_combo.changed.connect(() => pending_position = position_combo.active_id);
            grid.attach(position_combo, 1, row++, 1, 1);

            // Icon size
            grid.attach(new Gtk.Label("Icon Size:") { halign = Gtk.Align.END }, 0, row, 1, 1);
            var size_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 32, 72, 4);
            size_scale.set_value(pending_icon_size);
            size_scale.hexpand = true;
            size_scale.value_changed.connect(() => pending_icon_size = (int)size_scale.get_value());
            grid.attach(size_scale, 1, row++, 1, 1);

            // Magnification
            grid.attach(new Gtk.Label("Magnification:") { halign = Gtk.Align.END }, 0, row, 1, 1);
            var mag_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            var mag_switch = new Gtk.Switch();
            mag_switch.active = pending_magnification > 1.0;
            mag_switch.valign = Gtk.Align.CENTER;

            var mag_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 1.2, 2.0, 0.1);
            mag_scale.set_value(pending_magnification > 1.0 ? pending_magnification : 1.5);
            mag_scale.hexpand = true;
            mag_scale.sensitive = mag_switch.active;

            mag_switch.notify["active"].connect(() => {
                mag_scale.sensitive = mag_switch.active;
                pending_magnification = mag_switch.active ? mag_scale.get_value() : 1.0;
            });
            mag_scale.value_changed.connect(() => {
                if (mag_switch.active) pending_magnification = mag_scale.get_value();
            });

            mag_box.pack_start(mag_switch, false, false, 0);
            mag_box.pack_start(mag_scale, true, true, 0);
            grid.attach(mag_box, 1, row++, 1, 1);

            // Theme
            grid.attach(new Gtk.Label("Theme:") { halign = Gtk.Align.END }, 0, row, 1, 1);
            var theme_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            theme_combo = new Gtk.ComboBoxText();
            refresh_theme_list();
            theme_combo.changed.connect(() => pending_theme = theme_combo.active_id);
            theme_combo.hexpand = true;
            theme_box.pack_start(theme_combo, true, true, 0);
            
            var install_btn = new Gtk.Button.from_icon_name("folder-open-symbolic", Gtk.IconSize.BUTTON);
            install_btn.tooltip_text = "Install theme from file";
            install_btn.clicked.connect(on_install_theme);
            theme_box.pack_start(install_btn, false, false, 0);
            grid.attach(theme_box, 1, row++, 1, 1);

            return grid;
        }

        private void refresh_theme_list() {
            theme_combo.remove_all();
            foreach (var theme in theme_manager.get_all_themes()) {
                theme_combo.append(theme.id, theme.name);
            }
            theme_combo.active_id = pending_theme;
        }

        private void on_install_theme() {
            var dialog = new Gtk.FileChooserDialog(
                "Install Theme", this, Gtk.FileChooserAction.OPEN,
                "_Cancel", Gtk.ResponseType.CANCEL,
                "_Open", Gtk.ResponseType.ACCEPT
            );
            
            var filter = new Gtk.FileFilter();
            filter.set_filter_name("Theme files (*.zip)");
            filter.add_pattern("*.zip");
            dialog.add_filter(filter);
            
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                var path = dialog.get_filename();
                if (theme_manager.install_theme(path)) {
                    refresh_theme_list();
                }
            }
            dialog.destroy();
        }

        private Gtk.Widget create_behavior_tab() {
            var grid = new Gtk.Grid();
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.margin = 16;

            int row = 0;

            // Auto-hide
            grid.attach(new Gtk.Label("Auto-hide:") { halign = Gtk.Align.END }, 0, row, 1, 1);
            var hide_switch = new Gtk.Switch();
            hide_switch.active = pending_auto_hide;
            hide_switch.halign = Gtk.Align.START;
            hide_switch.notify["active"].connect(() => pending_auto_hide = hide_switch.active);
            grid.attach(hide_switch, 1, row++, 1, 1);

            // Hide delay
            grid.attach(new Gtk.Label("Hide Delay (ms):") { halign = Gtk.Align.END }, 0, row, 1, 1);
            var delay_spin = new Gtk.SpinButton.with_range(0, 2000, 100);
            delay_spin.value = pending_hide_delay;
            delay_spin.value_changed.connect(() => pending_hide_delay = (int)delay_spin.value);
            grid.attach(delay_spin, 1, row++, 1, 1);

            // Show on all monitors
            grid.attach(new Gtk.Label("Show on all monitors:") { halign = Gtk.Align.END }, 0, row, 1, 1);
            var multi_switch = new Gtk.Switch();
            multi_switch.active = pending_multi_monitor;
            multi_switch.halign = Gtk.Align.START;
            multi_switch.notify["active"].connect(() => pending_multi_monitor = multi_switch.active);
            grid.attach(multi_switch, 1, row++, 1, 1);

            return grid;
        }

        private Gtk.Widget create_plugins_tab() {
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            box.margin = 16;

            var label = new Gtk.Label("Show these items on the dock:");
            label.halign = Gtk.Align.START;
            box.pack_start(label, false, false, 0);

            plugins_grid = new Gtk.Grid();
            plugins_grid.row_spacing = 8;
            plugins_grid.column_spacing = 12;
            refresh_plugins_list();
            box.pack_start(plugins_grid, false, false, 0);

            var install_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            install_box.margin_top = 16;
            
            var install_btn = new Gtk.Button.with_label("Install Plugin...");
            install_btn.clicked.connect(on_install_plugin);
            install_box.pack_start(install_btn, false, false, 0);
            box.pack_start(install_box, false, false, 0);

            return box;
        }

        private void refresh_plugins_list() {
            plugins_grid.foreach((w) => plugins_grid.remove(w));
            int row = 0;

            // Separator
            plugins_grid.attach(new Gtk.Label("Separator") { halign = Gtk.Align.START }, 0, row, 1, 1);
            var sep_switch = new Gtk.Switch();
            sep_switch.active = pending_separator;
            sep_switch.halign = Gtk.Align.START;
            sep_switch.notify["active"].connect(() => pending_separator = sep_switch.active);
            plugins_grid.attach(sep_switch, 1, row++, 1, 1);

            // Show Desktop
            plugins_grid.attach(new Gtk.Label("Show Desktop") { halign = Gtk.Align.START }, 0, row, 1, 1);
            var desktop_switch = new Gtk.Switch();
            desktop_switch.active = pending_show_desktop;
            desktop_switch.halign = Gtk.Align.START;
            desktop_switch.notify["active"].connect(() => pending_show_desktop = desktop_switch.active);
            plugins_grid.attach(desktop_switch, 1, row++, 1, 1);

            // Trash
            plugins_grid.attach(new Gtk.Label("Trash") { halign = Gtk.Align.START }, 0, row, 1, 1);
            var trash_switch = new Gtk.Switch();
            trash_switch.active = pending_trash;
            trash_switch.halign = Gtk.Align.START;
            trash_switch.notify["active"].connect(() => pending_trash = trash_switch.active);
            plugins_grid.attach(trash_switch, 1, row++, 1, 1);

            // User plugins
            foreach (var plugin in plugin_manager.get_user_plugins()) {
                plugins_grid.attach(new Gtk.Label(plugin.name) { halign = Gtk.Align.START }, 0, row, 1, 1);
                var sw = new Gtk.Switch();
                sw.active = config.get_plugin_enabled(plugin.id);
                sw.halign = Gtk.Align.START;
                var pid = plugin.id;
                sw.notify["active"].connect(() => config.set_plugin_enabled(pid, sw.active));
                plugins_grid.attach(sw, 1, row++, 1, 1);
            }

            plugins_grid.show_all();
        }

        private void on_install_plugin() {
            var dialog = new Gtk.FileChooserDialog(
                "Install Plugin", this, Gtk.FileChooserAction.OPEN,
                "_Cancel", Gtk.ResponseType.CANCEL,
                "_Open", Gtk.ResponseType.ACCEPT
            );
            
            var filter = new Gtk.FileFilter();
            filter.set_filter_name("Plugin files (*.zip)");
            filter.add_pattern("*.zip");
            dialog.add_filter(filter);
            
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                if (plugin_manager.install_plugin(dialog.get_filename())) {
                    refresh_plugins_list();
                }
            }
            dialog.destroy();
        }

        private Gtk.Widget create_hidden_apps_tab() {
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
            box.margin = 16;

            var label = new Gtk.Label("Hidden apps won't appear in the launcher.\nRight-click an app in launcher to hide it.");
            label.halign = Gtk.Align.START;
            label.margin_bottom = 10;
            box.pack_start(label, false, false, 0);

            var scroll = new Gtk.ScrolledWindow(null, null);
            scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scroll.vexpand = true;

            hidden_list = new Gtk.ListBox();
            hidden_list.selection_mode = Gtk.SelectionMode.NONE;
            scroll.add(hidden_list);
            box.pack_start(scroll, true, true, 0);

            update_hidden_list();

            return box;
        }

        private void update_hidden_list() {
            hidden_list.foreach((w) => hidden_list.remove(w));

            var hidden_ids = config.get_hidden_apps();
            foreach (var app_id in hidden_ids) {
                var app = app_manager.get_app(app_id);
                string name = app != null ? app.name : app_id;

                var row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
                row.margin = 6;

                var app_label = new Gtk.Label(name);
                app_label.halign = Gtk.Align.START;
                app_label.hexpand = true;
                row.pack_start(app_label, true, true, 0);

                var unhide_btn = new Gtk.Button.with_label("Unhide");
                unhide_btn.clicked.connect(() => {
                    config.unhide_app(app_id);
                    update_hidden_list();
                });
                row.pack_end(unhide_btn, false, false, 0);

                hidden_list.add(row);
            }

            if (hidden_ids.length == 0) {
                var empty = new Gtk.Label("No hidden apps");
                empty.margin = 20;
                hidden_list.add(empty);
            }

            hidden_list.show_all();
        }

        private Gtk.Widget create_about_tab() {
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            box.margin = 24;
            box.halign = Gtk.Align.CENTER;
            box.valign = Gtk.Align.CENTER;

            var title = new Gtk.Label("<span size='xx-large' weight='bold'>NovaDock</span>");
            title.use_markup = true;
            box.pack_start(title, false, false, 0);

            var version = new Gtk.Label("Version 0.1.2");
            version.get_style_context().add_class("dim-label");
            box.pack_start(version, false, false, 0);

            var desc = new Gtk.Label("A macOS/GNOME-style dock and application launcher for XFCE4");
            desc.wrap = true;
            desc.justify = Gtk.Justification.CENTER;
            desc.margin_top = 10;
            box.pack_start(desc, false, false, 0);

            var author = new Gtk.Label("<b>Author:</b> Kamil 'Novik' Nowicki");
            author.use_markup = true;
            author.margin_top = 20;
            box.pack_start(author, false, false, 0);

            var copyright = new Gtk.Label("Copyright © 2025-2026");
            box.pack_start(copyright, false, false, 0);

            var email = new Gtk.LinkButton.with_label("mailto:novik@noviktech.com", "novik@noviktech.com");
            box.pack_start(email, false, false, 0);

            var website = new Gtk.LinkButton.with_label("https://noviktech.com", "noviktech.com");
            box.pack_start(website, false, false, 0);

            var github = new Gtk.LinkButton.with_label("https://github.com/novik133/NovaDock", "GitHub");
            box.pack_start(github, false, false, 0);

            var license = new Gtk.Label("<small>Licensed under GPL-3.0</small>");
            license.use_markup = true;
            license.margin_top = 20;
            license.get_style_context().add_class("dim-label");
            box.pack_start(license, false, false, 0);

            return box;
        }
    }
}
