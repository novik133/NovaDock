project('novadock', 'vala', 'c',
  version: '0.1.0',
  meson_version: '>= 0.50.0',
)

gnome = import('gnome')

dependencies = [
  dependency('gtk+-3.0'),
  dependency('glib-2.0'),
  dependency('gio-2.0'),
  dependency('libwnck-3.0'),
]

add_project_arguments('-DWNCK_I_KNOW_THIS_IS_UNSTABLE', language: 'c')

sources = files(
  'src/main.vala',
  'src/application.vala',
  'src/dock/dock-window.vala',
  'src/dock/dock-item.vala',
  'src/dock/dock-renderer.vala',
  'src/dock/window-manager.vala',
  'src/dock/app-manager.vala',
  'src/dock/config-manager.vala',
  'src/launcher/launcher-window.vala',
  'src/settings/settings-window.vala',
  'src/plugins/plugin.vala',
  'src/plugins/plugin-manager.vala',
  'src/plugins/trash-plugin.vala',
  'src/plugins/show-desktop-plugin.vala',
  'src/plugins/separator-plugin.vala',
  'src/themes/theme.vala',
  'src/themes/theme-manager.vala',
)

executable('novadock',
  sources,
  dependencies: dependencies,
  install: true,
)

# Install data files
install_data('data/novadock.desktop',
  install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data('data/novadock-autostart.desktop',
  install_dir: join_paths(get_option('sysconfdir'), 'xdg/autostart')
)

install_man('data/novadock.1')
