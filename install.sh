#!/bin/sh
# Cài hoặc cập nhật bản Pitboard đã patch cho root, lấy từ GitHub Release của fork.
#
#   sh install.sh                 # bản stable mới nhất
#   sh install.sh v0.15.0-root    # một bản cụ thể (cả prerelease)
#
# Biến môi trường:
#   PITBOARD_FORK         owner/repo lấy release, mặc định datpham-lab/pitboard
#   PITBOARD_INSTALL_DIR  nơi cài, mặc định /usr/local/bin
set -eu

REPO="${PITBOARD_FORK:-datpham-lab/pitboard}"
DEST="${PITBOARD_INSTALL_DIR:-/usr/local/bin}"
TAG="${1:-}"

fail() { printf 'error: %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = Linux ] || fail "Script này chỉ dành cho Linux."

case $(uname -m) in
  x86_64 | amd64) target=x86_64-unknown-linux-musl ;;
  aarch64 | arm64) target=aarch64-unknown-linux-musl ;;
  *) fail "Không có bản build cho $(uname -m)." ;;
esac

get() { curl -fsSL "$@"; }

if [ -z "$TAG" ]; then
  # /releases/latest bỏ qua prerelease.
  TAG=$(get "https://api.github.com/repos/$REPO/releases/latest" |
    sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)
  [ -n "$TAG" ] || fail "Không tìm thấy release nào trong $REPO."
fi

asset="pitboard-${TAG}-${target}.tar.gz"
base="https://github.com/$REPO/releases/download/$TAG"

if command -v pitboard >/dev/null 2>&1; then
  printf 'Đang có: %s\n' "$(pitboard --version 2>/dev/null || echo '?')"
fi
printf 'Cài %s (%s) vào %s\n' "$TAG" "$target" "$DEST"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

get -o "$tmp/$asset" "$base/$asset"
get -o "$tmp/$asset.sha256" "$base/$asset.sha256"
(cd "$tmp" && sha256sum -c "$asset.sha256") || fail "Sai checksum, dừng."

tar -xzf "$tmp/$asset" -C "$tmp"
mkdir -p "$DEST"
install -m 755 "$tmp/pitboard" "$DEST/pitboard.new"
mv -f "$DEST/pitboard.new" "$DEST/pitboard"

"$DEST/pitboard" --version
