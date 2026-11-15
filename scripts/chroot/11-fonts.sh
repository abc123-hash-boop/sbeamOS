#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[INFO] %s\n' "$*"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/fonts"
TARGET_DIR="/usr/local/share/fonts/sbeamos"

log "Installing bundled Sbeam font..."

[[ -d "$SOURCE_DIR" ]] || {
  printf '[ERROR] Bundled fonts directory is missing: %s\n' "$SOURCE_DIR" >&2
  exit 1
}

mapfile -d '' font_files < <(find "$SOURCE_DIR" -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print0)
(("${#font_files[@]}" > 0)) || {
  printf '[ERROR] No TTF or OTF font files were found.\n' >&2
  exit 1
}

install -d -m 0755 "$TARGET_DIR"
install -m 0644 "${font_files[@]}" "$TARGET_DIR/"

log "Refreshing fontconfig cache..."
fc-cache --force "$TARGET_DIR"

log "Configuring Sbeam as the default GNOME interface font..."
install -d -m 0755 /etc/dconf/profile /etc/dconf/db/local.d
if [[ ! -f /etc/dconf/profile/user ]]; then
  cat > /etc/dconf/profile/user <<'PROFILE'
user-db:user
system-db:local
PROFILE
fi

cat > /etc/dconf/db/local.d/01-sbeamos-font <<'DCONF'
[org/gnome/desktop/interface]
font-name='Sbeam 10'
DCONF

dconf update

log "Sbeam font installation completed."
