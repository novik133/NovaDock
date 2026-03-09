namespace NovaDock {
    /* main application class - wires up all components */
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
            /* register CLI flags */
            add_main_option("launcher", 'l', 0, OptionArg.NONE, "Open the application launcher", null);
            add_main_option("settings", 's', 0, OptionArg.NONE, "Open the settings window", null);
        }

        /* parse CLI flags before activation */
        protected override int handle_local_options(VariantDict options) {
            if (options.contains("launcher")) show_launcher = true;
            if (options.contains("settings"))  show_settings = true;
            return -1;
        }

        protected override int command_line(ApplicationCommandLine command_line) {
            activate();
            return 0;
        }

        /* create or present the dock and all related windows */
        protected override void activate() {
            if (dock != null) {
                /* already running: just handle any CLI flags */
                if (show_launcher) { launcher.toggle(); show_launcher = false; }
                if (show_settings) { settings.show_all(); show_settings = false; }
                dock.present();
                return;
            }

            /* first launch: create all components */
            config = new ConfigManager();
            app_manager = new AppManager();
            dock = new DockWindow(this, app_manager);
            launcher = new LauncherWindow(app_manager, config);
            settings = new SettingsWindow(config, app_manager);

            /* connect signals between components */
            dock.launcher_requested.connect(() => {
                dock.hide();
                launcher.toggle();
            });
            launcher.hide.connect(() => dock.show());
            launcher.show.connect(() => dock.hide());
            dock.settings_requested.connect(() => settings.show_all());
            settings.settings_changed.connect(() => dock.reload_settings());
            settings.settings_changed.connect(() => {
                if (hotkey_manager != null) hotkey_manager.reload_hotkeys();
            });
            /* hide settings instead of destroying so it can reopen */
            settings.delete_event.connect(() => { settings.hide(); return true; });

            /* set up global hotkeys */
            hotkey_manager = new HotkeyManager(config, launcher, app_manager);
            hotkey_manager.hotkey_error.connect((message) => {
                stderr.printf("Hotkey error: %s\n", message);
                var notification = new Notification("NovaDock Hotkey Error");
                notification.set_body(message);
                send_notification(null, notification);
            });
            if (hotkey_manager.initialize()) {
                hotkey_manager.reload_hotkeys();
            }

            /* show the dock */
            dock.show_all();
            dock.present();
            dock.set_visible(true);

            /* handle CLI flags after init */
            if (show_launcher) { launcher.toggle(); show_launcher = false; }
            if (show_settings) { settings.show_all(); show_settings = false; }
        }
    }
}
