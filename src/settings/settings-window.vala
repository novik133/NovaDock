namespace NovaDock {
    public class SettingsWindow : Gtk.Window {
        private ConfigManager config;
        private AppManager app_manager;
        private Gtk.ListBox hidden_list;
        public signal void settings_changed();

        public SettingsWindow(ConfigManager config, AppManager app_manager) {
            Object(
                title: "NovaDock Settings",
                default_width: 450,
                default_height: 400,
                resizable: false
            );
            this.config = config;
            this.app_manager = app_manager;
            build_ui();
            
            // Refresh hidden list when window is shown
            this.show.connect(() => update_hidden_list());
        }

        private void build_ui() {
            var header = new Gtk.HeaderBar();
            header.title = "Settings";
            header.show_close_button = true;
            set_titlebar(header);

            var notebook = new Gtk.Notebook();
            notebook.margin = 12;

            // Appearance tab
            notebook.append_page(create_appearance_tab(), new Gtk.Label("Appearance"));

            // Behavior tab
            notebook.append_page(create_behavior_tab(), new Gtk.Label("Behavior"));

            // Plugins tab
            notebook.append_page(create_plugins_tab(), new Gtk.Label("Plugins"));

            // Hidden Apps tab
            notebook.append_page(create_hidden_apps_tab(), new Gtk.Label("Hidden Apps"));

            // About tab
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
            position_combo.active_id = config.get_position();
            position_combo.changed.connect(() => {
                config.set_position(position_combo.active_id);
                settings_changed();
            });
            grid.attach(position_combo, 1, row++, 1, 1);

            // Icon size
            grid.attach(new Gtk.Label("Icon Size:") { halign = Gtk.Align.END }, 0, row, 1, 1);
            var size_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 32, 72, 4);
            size_scale.set_value(config.get_icon_size());
            size_scale.hexpand = true;
            size_scale.value_changed.connect(() => {
                config.set_icon_size((int)size_scale.get_value());
                settings_changed();
            });
            grid.attach(size_scale, 1, row++, 1, 1);

            // Magnification
            grid.attach(new Gtk.Label("Magnification:") { halign = Gtk.Align.END }, 0, row, 1, 1);
            var mag_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            var mag_switch = new Gtk.Switch();
            mag_switch.active = config.get_magnification() > 1.0;
            mag_switch.valign = Gtk.Align.CENTER;

            var mag_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 1.2, 2.0, 0.1);
            mag_scale.set_value(config.get_magnification());
            mag_scale.hexpand = true;
            mag_scale.sensitive = mag_switch.active;

            mag_switch.notify["active"].connect(() => {
                mag_scale.sensitive = mag_switch.active;
                config.set_magnification(mag_switch.active ? mag_scale.get_value() : 1.0);
                settings_changed();
            });
            mag_scale.value_changed.connect(() => {
                if (mag_switch.active) {
                    config.set_magnification(mag_scale.get_value());
                    settings_changed();
                }
            });

            mag_box.pack_start(mag_switch, false, false, 0);
            mag_box.pack_start(mag_scale, true, true, 0);
            grid.attach(mag_box, 1, row++, 1, 1);

            // Theme
            grid.attach(new Gtk.Label("Theme:") { halign = Gtk.Align.END }, 0, row, 1, 1);
            var theme_combo = new Gtk.ComboBoxText();
            theme_combo.append("default", "Default");
            theme_combo.append("dark", "Dark");
            theme_combo.append("light", "Light");
            theme_combo.active_id = config.get_theme();
            theme_combo.changed.connect(() => {
                config.set_theme(theme_combo.active_id);
                settings_changed();
            });
            grid.attach(theme_combo, 1, row++, 1, 1);

            return grid;
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
            hide_switch.active = config.get_auto_hide();
            hide_switch.halign = Gtk.Align.START;
            hide_switch.notify["active"].connect(() => {
                config.set_auto_hide(hide_switch.active);
                settings_changed();
            });
            grid.attach(hide_switch, 1, row++, 1, 1);

            // Hide delay
            grid.attach(new Gtk.Label("Hide Delay (ms):") { halign = Gtk.Align.END }, 0, row, 1, 1);
            var delay_spin = new Gtk.SpinButton.with_range(0, 2000, 100);
            delay_spin.value = config.get_hide_delay();
            delay_spin.value_changed.connect(() => {
                config.set_hide_delay((int)delay_spin.value);
                settings_changed();
            });
            grid.attach(delay_spin, 1, row++, 1, 1);

            // Show on all monitors
            grid.attach(new Gtk.Label("Show on all monitors:") { halign = Gtk.Align.END }, 0, row, 1, 1);
            var multi_switch = new Gtk.Switch();
            multi_switch.active = config.get_multi_monitor();
            multi_switch.halign = Gtk.Align.START;
            multi_switch.notify["active"].connect(() => {
                config.set_multi_monitor(multi_switch.active);
                settings_changed();
            });
            grid.attach(multi_switch, 1, row++, 1, 1);

            return grid;
        }

        private Gtk.Widget create_plugins_tab() {
            var grid = new Gtk.Grid();
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.margin = 16;

            var label = new Gtk.Label("Show these items on the dock:");
            label.halign = Gtk.Align.START;
            label.margin_bottom = 10;
            grid.attach(label, 0, 0, 2, 1);

            // Separator
            grid.attach(new Gtk.Label("Separator") { halign = Gtk.Align.START }, 0, 1, 1, 1);
            var sep_switch = new Gtk.Switch();
            sep_switch.active = config.get_plugin_enabled("separator");
            sep_switch.halign = Gtk.Align.START;
            sep_switch.notify["active"].connect(() => {
                config.set_plugin_enabled("separator", sep_switch.active);
                settings_changed();
            });
            grid.attach(sep_switch, 1, 1, 1, 1);

            // Show Desktop
            grid.attach(new Gtk.Label("Show Desktop") { halign = Gtk.Align.START }, 0, 2, 1, 1);
            var desktop_switch = new Gtk.Switch();
            desktop_switch.active = config.get_plugin_enabled("show-desktop");
            desktop_switch.halign = Gtk.Align.START;
            desktop_switch.notify["active"].connect(() => {
                config.set_plugin_enabled("show-desktop", desktop_switch.active);
                settings_changed();
            });
            grid.attach(desktop_switch, 1, 2, 1, 1);

            // Trash
            grid.attach(new Gtk.Label("Trash") { halign = Gtk.Align.START }, 0, 3, 1, 1);
            var trash_switch = new Gtk.Switch();
            trash_switch.active = config.get_plugin_enabled("trash");
            trash_switch.halign = Gtk.Align.START;
            trash_switch.notify["active"].connect(() => {
                config.set_plugin_enabled("trash", trash_switch.active);
                settings_changed();
            });
            grid.attach(trash_switch, 1, 3, 1, 1);

            return grid;
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

            // App name
            var title = new Gtk.Label("<span size='xx-large' weight='bold'>NovaDock</span>");
            title.use_markup = true;
            box.pack_start(title, false, false, 0);

            // Version
            var version = new Gtk.Label("Version 0.1.0");
            version.get_style_context().add_class("dim-label");
            box.pack_start(version, false, false, 0);

            // Description
            var desc = new Gtk.Label("A macOS/GNOME-style dock and application launcher for XFCE4");
            desc.wrap = true;
            desc.justify = Gtk.Justification.CENTER;
            desc.margin_top = 10;
            box.pack_start(desc, false, false, 0);

            // Author
            var author = new Gtk.Label("<b>Author:</b> Kamil 'Novik' Nowicki");
            author.use_markup = true;
            author.margin_top = 20;
            box.pack_start(author, false, false, 0);

            // Copyright
            var copyright = new Gtk.Label("Copyright © 2025");
            box.pack_start(copyright, false, false, 0);

            // Links
            var email = new Gtk.LinkButton.with_label("mailto:novik@noviktech.com", "novik@noviktech.com");
            box.pack_start(email, false, false, 0);

            var website = new Gtk.LinkButton.with_label("https://noviktech.com", "noviktech.com");
            box.pack_start(website, false, false, 0);

            var github = new Gtk.LinkButton.with_label("https://github.com/novik133/NovaDock", "GitHub");
            box.pack_start(github, false, false, 0);

            // License
            var license = new Gtk.Label("<small>Licensed under GPL-3.0</small>");
            license.use_markup = true;
            license.margin_top = 20;
            license.get_style_context().add_class("dim-label");
            box.pack_start(license, false, false, 0);

            return box;
        }
    }
}
