libnovadock_sources = files(
  'core/application.vala',
  'dock/dock-window.vala',
  'dock/dock-item.vala',
  'dock/dock-renderer.vala',
  'dock/window-manager.vala',
  'dock/app-manager.vala',
  'dock/config-manager.vala',
  'launcher/launcher-window.vala',
  'settings/settings-window.vala',
  'plugins/plugin.vala',
  'plugins/plugin-manager.vala',
  'plugins/script-plugin.vala',
  'plugins/trash-plugin.vala',
  'plugins/show-desktop-plugin.vala',
  'plugins/separator-plugin.vala',
  'themes/theme.vala',
  'themes/theme-manager.vala',
)

libnovadock = static_library('novadock',
  libnovadock_sources,
  dependencies: dependencies,
  install: false,
)

libnovadock_dep = declare_dependency(
  link_with: libnovadock,
  dependencies: dependencies,
)
