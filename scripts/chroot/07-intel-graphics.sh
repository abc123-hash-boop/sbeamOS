#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

log() {
  printf '[INFO] %s\n' "$*"
}

log "Enabling Ubuntu Universe repository for additional graphics utilities..."
if grep -qE '^deb .* resolute main$' /etc/apt/sources.list; then
  sed -i -E '/^deb .* resolute main$/ s/ main$/ main universe/' /etc/apt/sources.list
fi

log "Refreshing APT package indexes..."
apt-get -o APT::Update::Error-Mode=any update

log "Installing Intel integrated graphics, Vulkan, and VA-API support..."
apt-get install --yes --no-install-recommends \
  intel-gpu-tools \
  intel-media-va-driver \
  libgl1-mesa-dri \
  libglx-mesa0 \
  mesa-utils \
  mesa-va-drivers \
  mesa-vulkan-drivers \
  vainfo \
  vulkan-tools

log "Intel graphics userspace stack installation completed."
