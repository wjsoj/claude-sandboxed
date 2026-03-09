# Maintainer: Your Name <your.email@example.com>
pkgname=claude-code-sandboxed
pkgver=1.0.0
pkgrel=1
pkgdesc="Claude Code with bubblewrap sandbox - restricts file system access to workspace"
arch=('any')
url="https://github.com/yourusername/claude-code-sandboxed"
license=('MIT')
depends=('bubblewrap')
optdepends=('claude-code: Official Claude Code CLI')
source=("claude-sandboxed")
sha256sums=('SKIP')

package() {
  install -Dm755 claude-sandboxed "$pkgdir/usr/bin/claude-sandboxed"
}
