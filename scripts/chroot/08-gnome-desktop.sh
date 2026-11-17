#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

log() {
  printf '[INFO] %s\n' "$*"
}

log "Installing the SbeamOS GNOME desktop..."

# Install GNOME directly instead of ubuntu-desktop-minimal. The Ubuntu
# desktop metapackage pulls in Snap and Ubuntu-specific update components.
apt-get install --yes --no-install-recommends \
  gdm3 \
  gnome-shell \
  gnome-session \
  gnome-control-center \
  gnome-settings-daemon \
  ibus \
  ibus-libpinyin \
  gnome-shell-ubuntu-extensions \
  gnome-shell-extension-manager \
  gnome-shell-extension-user-theme \
  gnome-tweaks \
  nautilus \
  gvfs \
  gvfs-backends \
  gvfs-fuse \
  gnome-keyring \
  xdg-user-dirs \
  xdg-user-dirs-gtk \
  xdg-desktop-portal \
  xdg-desktop-portal-gnome \
  pipewire-audio \
  wireplumber \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  ptyxis \
  gnome-calculator \
  gnome-text-editor \
  loupe \
  gnome-disk-utility \
  gnome-system-monitor \
  dconf-cli \
  fontconfig \
  fonts-cantarell \
  fonts-noto-core \
  fonts-noto-cjk \
  fonts-noto-color-emoji \
  adwaita-icon-theme

log "Enabling the graphical desktop and GNOME Display Manager..."
systemctl set-default graphical.target
systemctl enable gdm3.service

log "GNOME desktop packages installed and GDM enabled."
