# Maintainer: Kamil 'Novik' Nowicki <novik@noviktech.com>
pkgname=novadock
pkgver=0.2.0
pkgrel=1
pkgdesc="A macOS/GNOME-style dock and application launcher for XFCE4"
arch=('x86_64' 'aarch64')
url="https://github.com/novik133/NovaDock"
license=('GPL3')
depends=(
  'gtk3>=3.22'
  'libwnck3>=3.20'
  'glib2>=2.50'
  'gtk-layer-shell>=0.1'
  'libkeybinder3>=0.3.0'
)
makedepends=(
  'meson'
  'ninja'
  'vala'
)
source=("${pkgname}-${pkgver}.tar.gz::${url}/archive/v${pkgver}.tar.gz")
sha256sums=('SKIP')

build() {
  cd "NovaDock-${pkgver}"
  meson setup build --prefix=/usr
  ninja -C build
}

package() {
  cd "NovaDock-${pkgver}"
  DESTDIR="${pkgdir}" ninja -C build install
}
