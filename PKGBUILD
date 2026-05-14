# Maintainer: wjsoj <pattersonnelson658@gmail.com>
pkgname=claude-code-sandboxed
pkgver=1.1.0
pkgrel=1
pkgdesc="Claude Code with bubblewrap sandbox - profiles, socks5 proxy, burn mode"
arch=('any')
url="https://github.com/wjsoj/claude-sandboxed"
license=('MIT')
depends=('bubblewrap')
optdepends=(
  'claude-code: Official Claude Code CLI'
  'gost: required for per-profile SOCKS5 proxy bridging'
)
source=("claude-sandbox")
sha256sums=('SKIP')

package() {
  install -Dm755 claude-sandbox "$pkgdir/usr/bin/claude-sandbox"
}
