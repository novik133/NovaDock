<div align="center">

# NovaDock

**A macOS/GNOME-style dock and application launcher for XFCE4**

[![Version](https://img.shields.io/badge/version-0.2.0-blue?style=flat-square)](https://github.com/novik133/NovaDock/releases)
[![License](https://img.shields.io/badge/license-GPL--3.0-green?style=flat-square)](LICENSE)
[![Language](https://img.shields.io/badge/language-Vala-blueviolet?style=flat-square)](https://vala.dev)
[![GTK](https://img.shields.io/badge/toolkit-GTK3-orange?style=flat-square)](https://www.gtk.org)
[![Build](https://img.shields.io/badge/build-Meson-yellowgreen?style=flat-square)](https://mesonbuild.com)
[![Desktop](https://img.shields.io/badge/desktop-XFCE4-2284F2?style=flat-square)](https://xfce.org)
[![PayPal](https://img.shields.io/badge/Donate-PayPal-00457C?style=flat-square&logo=paypal&logoColor=white)](https://paypal.me/noviktech133)

</div>

<p align="center">
  <img src="Screenshots/1.png" width="100%" alt="NovaDock Main View">
</p>

<p align="center">
  <img src="Screenshots/2.png" width="48%" />
  <img src="Screenshots/3.png" width="48%" />
</p>

---

## Features

| Feature | Description |
|---------|-------------|
| **Dock Panel** | Animated dock with macOS-style magnification effect |
| **App Launcher** | Full-screen launchpad with grid view and search |
| **Pin/Unpin** | Right-click to pin running apps or unpin favourites |
| **App Indicators** | Visual dots for running applications |
| **Global Hotkeys** | Keyboard shortcuts for launcher and pinned apps |
| **Plugin System** | Extensible architecture for custom dock plugins |
| **Themes** | Installable themes for dock customisation |
| **Auto-Hide** | Configurable auto-hide with edge detection |
| **Multi-Monitor** | Full multi-monitor support |
| **Settings** | Modern sidebar settings panel |

## Requirements

| Dependency | Minimum Version |
|------------|----------------|
| GTK+ 3.0 | 3.22 |
| libwnck 3.0 | 3.20 |
| GLib 2.0 | 2.50 |
| keybinder-3.0 | 0.3.0 |
| Vala compiler | 0.48 |
| Meson + Ninja | 0.50 |
| gtk-layer-shell | 0.1 *(optional, Wayland)* |

## Building from Source

```bash
meson setup build
cd build
ninja
sudo ninja install
```

## Installation from Packages

Pre-built packages are available on the [Releases](https://github.com/novik133/NovaDock/releases) page.

### Import GPG Key

All packages are signed with GPG key `8419D50A73686C21`.

```bash
gpg --keyserver keyserver.ubuntu.com --recv-keys 8419D50A73686C21
```

### Debian / Ubuntu

```bash
gpg --export 8419D50A73686C21 | sudo tee /usr/share/keyrings/novadock.gpg > /dev/null
gpg --verify novadock_0.2.0_amd64.deb.asc novadock_0.2.0_amd64.deb
sudo dpkg -i novadock_0.2.0_amd64.deb
```

### Fedora / RHEL

```bash
gpg --export --armor 8419D50A73686C21 | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-novadock > /dev/null
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-novadock
gpg --verify novadock-0.2.0-1.x86_64.rpm.asc novadock-0.2.0-1.x86_64.rpm
sudo dnf install ./novadock-0.2.0-1.x86_64.rpm
```

### Arch Linux

```bash
sudo pacman-key --add <(gpg --export 8419D50A73686C21)
sudo pacman-key --lsign-key 8419D50A73686C21
gpg --verify novadock-0.2.0-1-x86_64.pkg.tar.zst.asc novadock-0.2.0-1-x86_64.pkg.tar.zst
sudo pacman -U novadock-0.2.0-1-x86_64.pkg.tar.zst
```

## Project Structure

```
NovaDock/
├── lib/                # Library (libnovadock)
│   ├── core/           # Application core
│   ├── dock/           # Dock panel components
│   ├── launcher/       # Full-screen app launcher
│   ├── hotkeys/        # Global hotkey manager
│   ├── plugins/        # Plugin system & built-in plugins
│   ├── settings/       # Settings UI
│   ├── themes/         # Theme system
│   └── meson.build
├── src/
│   ├── main.vala       # Entry point
│   └── meson.build
├── data/
│   ├── themes/         # Default themes
│   ├── icons/          # Dock icons
│   └── novadock.desktop
├── docs/               # Documentation
└── meson.build
```

## Usage

```bash
novadock              # Start dock
novadock --launcher   # Open launcher only  (-l)
novadock --settings   # Open settings       (-s)
```

## Customisation

- [Creating Custom Themes](docs/THEMES.md)
- [Creating Custom Plugins](docs/PLUGINS.md)

## Support

If you enjoy NovaDock, consider supporting development:

[![PayPal](https://img.shields.io/badge/Donate-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/noviktech133)

## License

This project is licensed under the [GPL-3.0](LICENSE) license.
