namespace NovaDock {
    public class Application : Gtk.Application {
        private DockWindow dock;
        private LauncherWindow launcher;
        private SettingsWindow settings;
        private AppManager app_manager;
        private ConfigManager config;

        public Application() {
            Object(
                application_id: "org.novadock.app",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE
            );
        }

        protected override void activate() {
            if (dock != null) {
                dock.present();
                return;
            }

            config = new ConfigManager();
            app_manager = new AppManager();
            dock = new DockWindow(this, app_manager);
            launcher = new LauncherWindow(app_manager, config);
            settings = new SettingsWindow(config, app_manager);

            dock.launcher_requested.connect(() => {
                dock.hide();
                launcher.toggle();
            });
            launcher.hide.connect(() => dock.show());
            launcher.show.connect(() => dock.hide());
            dock.settings_requested.connect(() => settings.show_all());
            settings.settings_changed.connect(() => dock.reload_settings());
            settings.delete_event.connect(() => { settings.hide(); return true; });

            dock.show_all();
        }

        protected override int command_line(ApplicationCommandLine cmd) {
            string[] args = cmd.get_arguments();
            activate();

            foreach (var arg in args) {
                if (arg == "--launcher") {
                    launcher.toggle();
                } else if (arg == "--settings") {
                    settings.show_all();
                } else if (arg == "--version") {
                    cmd.print("NovaDock 0.1.0\n");
                    return 0;
                }
            }
            return 0;
        }

        private static int _main(string[] args) {
            // Force Wnck to start tracking
            Wnck.Screen.get_default();

            var app = new Application();
            return app.run(args);
        }
    }
}
