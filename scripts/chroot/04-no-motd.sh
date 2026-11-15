#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[INFO] %s\n' "$*"
}

log "Removing Ubuntu update-manager and dynamic MOTD configuration..."

rm -rf -- /etc/update-manager/ /etc/update-motd.d/

log "MOTD cleanup completed."
