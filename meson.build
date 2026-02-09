project('novadock', 'vala', 'c',
  version: '0.1.3',
  meson_version: '>= 0.50.0',
)

gnome = import('gnome')

dependencies = [
  dependency('gtk+-3.0'),
  dependency('glib-2.0'),
  dependency('gio-2.0'),
  dependency('libwnck-3.0'),
  dependency('gtk-layer-shell-0'),
  dependency('keybinder-3.0', version: '>= 0.3.0'),
]

add_project_arguments('-DWNCK_I_KNOW_THIS_IS_UNSTABLE', language: 'c')
add_project_arguments('--vapidir', meson.current_source_dir() / 'vapi', language: 'vala')

subdir('lib')
subdir('src')

install_data('data/novadock.desktop',
  install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data('data/novadock-autostart.desktop',
  install_dir: join_paths(get_option('sysconfdir'), 'xdg/autostart')
)

install_man('data/novadock.1')
