namespace NovaDock {
    public class WindowManager : Object {
        private Wnck.Screen screen;

        public signal void windows_changed();

        public WindowManager() {
            screen = Wnck.Screen.get_default();
            screen.window_opened.connect(() => windows_changed());
            screen.window_closed.connect(() => windows_changed());
            screen.active_window_changed.connect(() => windows_changed());
        }

        public List<weak Wnck.Window> get_windows() {
            var windows = new List<weak Wnck.Window>();
            foreach (var window in screen.get_windows()) {
                if (!window.is_skip_tasklist()) {
                    windows.append(window);
                }
            }
            return windows;
        }

        public void activate_window(Wnck.Window window) {
            window.activate(Gtk.get_current_event_time());
        }
    }
}
