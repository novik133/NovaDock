# Changelog

## [0.2.0] - 2026-03-09

### Added
- Modern sidebar navigation in settings window (replaces tab layout)
- PayPal donation support (@noviktech133) in About tab
- Poll-based edge detection as auto-hide fallback
- Human-readable comments throughout entire codebase
- Arch Linux package (PKGBUILD)

### Fixed
- Icon flickering during magnification/resize on hover
- Auto-hide: dock now reliably reappears when mouse moves to screen bottom edge
- Spurious leave events no longer break auto-hide (filtered INFERIOR notifications)
- Global hotkeys now register correctly (proper keybinder angle-bracket format conversion)
- Input shape now covers full-width trigger strip when dock is hidden
- Removed debug print statements from application startup

### Changed
- Settings window redesigned with sidebar + stack layout
- Replaced Ko-fi donation with PayPal in About tab
- Version bumped to 0.2.0

## [0.1.3] - 2026-02-09

### Added
- Global hotkey support using keybinder-3.0 library
- Configure launcher hotkey to toggle application launcher from anywhere
- Configure up to 4 application hotkeys for quick launch/focus of pinned apps
- Hotkey capture widget in settings for easy keyboard shortcut configuration
- Hotkey conflict detection to prevent duplicate assignments
- Launch or focus behavior: launches app if not running, focuses if already running
- Automatic workspace switching when focusing apps on different workspaces
- Hotkeys tab in settings window for all hotkey configuration
- Persistent hotkey configuration saved to config file
- Error handling for unsupported systems and registration failures
- "Force Close" option in dock context menu to kill frozen applications
- Ko-fi donation button in About tab with support message
- Modernized About tab layout with better spacing and organization
- Debian package (.deb) with proper dependencies and metadata

### Fixed
- Touchpad two-finger swipe gestures in launcher now work properly with smooth scrolling
- Gestures no longer jump directly to last page
- Dock now positions correctly on primary monitor in dual/multi-monitor setups
- Dock no longer splits between monitors
- Command-line flags (--launcher, --settings) now work correctly
- Added short flags (-l, -s) for launcher and settings
- Fixed dock vibration/jittering on mouse hover at the edges
- Launcher grid now correctly shows 7 columns by default (was incorrectly showing 5)
- Icon spacing in launcher now scales properly with screen resolution

## [0.1.2] - 2026-01-02

### Added
- Drag and drop support for .desktop files onto the dock

### Fixed
- Dock vibration/jitter when hovering over icons
- Launcher icons too small on high-resolution displays
- Transparent window rectangle visible behind dock on XFCE4

## [0.1.1] - 2025-12-29

### Added
- Save and Cancel buttons in settings window
- Install custom themes from zip files (Settings → Appearance)
- Install custom plugins from zip files (Settings → Plugins)
- Widget plugins support (clock, script output)
- Theme documentation (docs/THEMES.md)
- Plugin documentation (docs/PLUGINS.md)

### Fixed
- Auto-hide now works correctly (dock moves off-screen when hidden)
- Settings changes only apply when Save is clicked
- Settings window stays open after saving

## [0.1.0] - 2025-12-29

### Added
- macOS-style dock with magnification effect on hover
- Full-screen application launcher with grid layout and search
- Pin/unpin applications via right-click context menu
- Running app indicators (dots for multiple windows)
- Window list popup for apps with multiple windows
- Folder support in launcher (drag-and-drop to create folders)
- Hide apps from launcher with settings to unhide
- Plugin system with Trash, Show Desktop, and Separator plugins
- Theme support with multiple built-in themes
- Left/right/bottom dock positioning
- Auto-hide with configurable delay
- Settings window with Appearance, Behavior, Plugins, Hidden Apps, and About tabs
- Multi-monitor support
- XFCE4 integration with autostart desktop file
- Man page documentation
