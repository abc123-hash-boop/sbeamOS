#!/usr/bin/env bash
set -Eeuo pipefail

# Configure the machine identity inside the target RootFS.
HOSTNAME="sbeamos"

log() {
  printf '[INFO] %s\n' "$*"
}

log "Setting hostname to ${HOSTNAME}..."
printf '%s\n' "$HOSTNAME" > /etc/hostname

cat > /etc/hosts <<EOF
127.0.0.1 localhost
127.0.1.1 ${HOSTNAME}
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

log "Hostname configuration completed."
