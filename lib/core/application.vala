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
                flags: ApplicationFlags.FLAGS_NONE | ApplicationFlags.NON_UNIQUE
            );
        }

        protected override void activate() {
            stderr.printf("activate() called\n");
            if (dock != null) {
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
            settings.delete_event.connect(() => { settings.hide(); return true; });

            stderr.printf("Showing dock...\n");
            dock.show_all();
            dock.present();
            dock.set_visible(true);
            stderr.printf("Dock visible, mapped=%s\n", dock.get_mapped().to_string());
        }
    }
}
