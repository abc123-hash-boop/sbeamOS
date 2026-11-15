#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

log() {
  printf '[INFO] %s\n' "$*"
}

log "Configuring NetworkManager..."
install -d -m 0755 /etc/NetworkManager
cat > /etc/NetworkManager/NetworkManager.conf <<'NETWORKMANAGER'
[main]
plugins=ifupdown,keyfile
dns=systemd-resolved

[ifupdown]
managed=false
NETWORKMANAGER

log "Configuring Netplan to use NetworkManager..."
install -d -m 0755 /etc/netplan
cat > /etc/netplan/01-network-manager-all.yaml <<'NETPLAN'
network:
  version: 2
  renderer: NetworkManager
NETPLAN
chmod 0644 /etc/netplan/01-network-manager-all.yaml

log "Validating Netplan configuration..."
netplan generate

log "Enabling NetworkManager and systemd-resolved..."
systemctl enable NetworkManager.service
systemctl enable systemd-resolved.service
ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

log "NetworkManager and Netplan configuration completed."
