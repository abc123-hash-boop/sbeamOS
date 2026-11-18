#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/installer"

log() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

[[ -d "$SOURCE_DIR/src/sbeamos_installer" ]] || die "Installer source directory is missing: $SOURCE_DIR"

log "Installing GTK 3 SbeamOS system installer dependencies..."
apt-get install --yes --no-install-recommends \
  python3 \
  python3-gi \
  gir1.2-gtk-3.0 \
  pkexec \
  rsync \
  parted \
  dosfstools \
  e2fsprogs \
  util-linux \
  grub2-common \
  grub-pc-bin \
  grub-efi-amd64-bin \
  efibootmgr

log "Installing SbeamOS installer application..."
install -d -m 0755 /usr/lib/sbeamos-installer/src \
  /usr/share/applications
rm -rf /usr/lib/sbeamos-installer/src/sbeamos_installer
cp -a "$SOURCE_DIR/src/sbeamos_installer" /usr/lib/sbeamos-installer/src/
install -m 0755 "$SOURCE_DIR/sbeamos-installer" /usr/bin/sbeamos-installer
install -m 0644 "$SOURCE_DIR/data/sbeamos-installer.desktop" \
  /usr/share/applications/sbeamos-installer.desktop

log "SbeamOS GTK installer installed."
