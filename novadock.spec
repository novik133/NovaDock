Name:           novadock
Version:        0.2.0
Release:        1%{?dist}
Summary:        A macOS/GNOME-style dock and application launcher for XFCE4

License:        GPL-3.0-or-later
URL:            https://github.com/novik133/NovaDock
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  meson >= 0.50.0
BuildRequires:  ninja-build
BuildRequires:  vala >= 0.48
BuildRequires:  gcc
BuildRequires:  pkgconfig(gtk+-3.0) >= 3.22
BuildRequires:  pkgconfig(glib-2.0) >= 2.50
BuildRequires:  pkgconfig(libwnck-3.0) >= 3.20
BuildRequires:  pkgconfig(gtk-layer-shell-0) >= 0.1
BuildRequires:  pkgconfig(keybinder-3.0) >= 0.3.0

Requires:       gtk3 >= 3.22
Requires:       glib2 >= 2.50
Requires:       libwnck3 >= 3.20
Requires:       gtk-layer-shell >= 0.1
Requires:       libkeybinder3 >= 0.3.0

%description
NovaDock is a modern, feature-rich dock and application launcher designed
for XFCE4 desktop environment. It provides a macOS-style dock with smooth
animations, magnification effects, and a full-screen application launcher.

Features:
* Animated dock with macOS-style magnification effect
* Full-screen application launcher with grid view and search
* Pin/unpin applications with right-click context menu
* Visual indicators for running applications
* Global hotkey support for quick access
* Plugin system for extensibility
* Theme support for customization
* Multi-monitor support
* Auto-hide functionality

%prep
%autosetup -n NovaDock-%{version}

%build
%meson
%meson_build

%install
%meson_install

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_bindir}/novadock
%{_datadir}/applications/novadock.desktop
%{_datadir}/icons/hicolor/scalable/apps/novadock-launcher.svg
%{_datadir}/novadock/
%{_mandir}/man1/novadock.1*
%config(noreplace) %{_sysconfdir}/xdg/autostart/novadock-autostart.desktop

%changelog
* Sun Mar 09 2026 Kamil 'Novik' Nowicki <novik@noviktech.com> - 0.2.0-1
- Version 0.2.0 release
- Modern sidebar navigation in settings window
- PayPal donation support in About tab
- Fixed icon flickering during magnification
- Fixed auto-hide reliability issues
- Fixed global hotkeys registration
- Removed debug print statements

* Sun Feb 09 2026 Kamil 'Novik' Nowicki <novik@noviktech.com> - 0.1.3-1
- Version 0.1.3 release
- Added global hotkey support
- Added force close option in context menu
- Fixed touchpad gestures in launcher
- Fixed multi-monitor positioning
- Added Debian package support

* Fri Jan 02 2026 Kamil 'Novik' Nowicki <novik@noviktech.com> - 0.1.2-1
- Version 0.1.2 release
- Added drag and drop support for .desktop files
- Fixed dock vibration on hover
- Fixed launcher icons on high-resolution displays

* Sun Dec 29 2025 Kamil 'Novik' Nowicki <novik@noviktech.com> - 0.1.1-1
- Version 0.1.1 release
- Added custom theme and plugin installation
- Fixed auto-hide functionality
- Added widget plugins support

* Sun Dec 29 2025 Kamil 'Novik' Nowicki <novik@noviktech.com> - 0.1.0-1
- Initial release
