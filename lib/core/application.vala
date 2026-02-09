namespace NovaDock {
    public class Application : Gtk.Application {
        private DockWindow dock;
        private LauncherWindow launcher;
        private SettingsWindow settings;
        private AppManager app_manager;
        private ConfigManager config;
        private HotkeyManager hotkey_manager;
        
        private bool show_launcher = false;
        private bool show_settings = false;

        public Application() {
            Object(
                application_id: "org.novadock.app",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE
            );
            
            // Add command-line options
            add_main_option("launcher", 'l', 0, OptionArg.NONE, "Open the application launcher", null);
            add_main_option("settings", 's', 0, OptionArg.NONE, "Open the settings window", null);
        }
        
        protected override int handle_local_options(VariantDict options) {
            // Check for our custom options
            if (options.contains("launcher")) {
                show_launcher = true;
            }
            if (options.contains("settings")) {
                show_settings = true;
            }
            
            // Continue to command_line
            return -1;
        }
        
        protected override int command_line(ApplicationCommandLine command_line) {
            activate();
            return 0;
        }

        protected override void activate() {
            stderr.printf("activate() called\n");
            if (dock != null) {
                // If already running, handle the flags
                if (show_launcher) {
                    launcher.toggle();
                    show_launcher = false;
                }
                if (show_settings) {
                    settings.show_all();
                    show_settings = false;
                }
                dock.present();
                return;
            }

            stderr.printf("Creating config...\n");
            config = new ConfigManager();
            stderr.printf("Creating app_manager...\n");
            app_manager = new AppManager();
            stderr.printf("Creating dock...\n");
            dock = new DockWindow(this, app_manager);
            stderr.printf("Creating launcher...\n");
            launcher = new LauncherWindow(app_manager, config);
            stderr.printf("Creating settings...\n");
            settings = new SettingsWindow(config, app_manager);

            dock.launcher_requested.connect(() => {
                dock.hide();
                launcher.toggle();
            });
            launcher.hide.connect(() => dock.show());
            launcher.show.connect(() => dock.hide());
            dock.settings_requested.connect(() => settings.show_all());
            settings.settings_changed.connect(() => dock.reload_settings());
            settings.settings_changed.connect(() => {
                if (hotkey_manager != null) {
                    hotkey_manager.reload_hotkeys();
                }
            });
            settings.delete_event.connect(() => { settings.hide(); return true; });

            stderr.printf("Creating hotkey_manager...\n");
            hotkey_manager = new HotkeyManager(config, launcher, app_manager);
            hotkey_manager.hotkey_error.connect((message) => {
                stderr.printf("Hotkey error: %s\n", message);
                // Display notification to user
                var notification = new Notification("NovaDock Hotkey Error");
                notification.set_body(message);
                send_notification(null, notification);
            });
            if (hotkey_manager.initialize()) {
                stderr.printf("Hotkey manager initialized successfully\n");
                hotkey_manager.reload_hotkeys();
            } else {
                stderr.printf("Hotkey manager initialization failed\n");
            }

            stderr.printf("Showing dock...\n");
            dock.show_all();
            dock.present();
            dock.set_visible(true);
            stderr.printf("Dock visible, mapped=%s\n", dock.get_mapped().to_string());
            
            // Handle command-line flags after initialization
            if (show_launcher) {
                launcher.toggle();
                show_launcher = false;
            }
            if (show_settings) {
                settings.show_all();
                show_settings = false;
            }
        }
    }
}
