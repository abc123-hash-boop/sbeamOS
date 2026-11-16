#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

log() {
  printf '[INFO] %s\n' "$*"
}

log "Installing the SbeamOS everyday desktop application suite..."

# Core productivity: Writer, Calc and Impress only; avoid pulling the full
# LibreOffice meta-package and its optional database / formula components.
# The GTK integration keeps LibreOffice visually consistent with GNOME.
apt-get install --yes --no-install-recommends \
  libreoffice-writer \
  libreoffice-calc \
  libreoffice-impress \
  libreoffice-gtk3 \
  fonts-liberation \
  fonts-crosextra-carlito \
  fonts-crosextra-caladea \
  papers \
  showtime \
  rhythmbox \
  file-roller \
  gnome-screenshot \
  simple-scan \
  seahorse \
  gnome-calendar \
  transmission-gtk

log "Everyday desktop applications installed."
