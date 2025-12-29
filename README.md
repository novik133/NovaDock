# NovaDock

A macOS/GNOME-style dock and application launcher for XFCE4.

<p align="center">
  <img src="Screenshot/1.png" width="100%" alt="NovaDock Main View">
</p>

<p align="center">
  <img src="Screenshot/2.png" width="48%" />
  <img src="Screenshot/3.png" width="48%" />
</p>

## Features

- **Dock Panel** - Animated dock with macOS-style magnification effect
- **Application Launcher** - Full-screen launchpad with grid view and search
- **Pin/Unpin Apps** - Right-click to pin running apps or unpin favorites
- **App Indicators** - Visual indicators for running applications
- **Multi-Instance Support** - Right-click → "Open New Window" for running apps
- **Plugin System** - Extensible architecture for custom dock plugins
- **Theme Support** - Installable themes for dock customization
- **Settings Panel** - Configure dock position, size, behavior, and appearance

## Technology Stack

- **Language:** Vala
- **UI Toolkit:** GTK3
- **Build System:** Meson
- **Target DE:** XFCE4

## Requirements

- GTK+ 3.0
- libwnck 3.0 (window management)
- GLib 2.0
- Vala compiler (valac)
- Meson & Ninja

## Building

```bash
meson setup build
cd build
ninja
sudo ninja install
```

## Project Structure

```
NovaDock/
├── src/
│   ├── dock/           # Dock panel components
│   ├── launcher/       # Full-screen app launcher
│   ├── plugins/        # Plugin system & built-in plugins
│   ├── settings/       # Settings UI
│   └── main.vala       # Entry point
├── data/
│   ├── themes/         # Default themes
│   ├── icons/          # Dock icons
│   └── novadock.desktop
├── plugins/            # External plugin examples
└── meson.build
```

## Usage

```bash
novadock              # Start dock
novadock --launcher   # Open launcher only
novadock --settings   # Open settings
```

## License

GPL-3.0
