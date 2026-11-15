#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '[INFO] %s\n' "$*"
}

shopt -s nullglob
scripts=("$SCRIPT_DIR"/[0-9][0-9]-*.sh)

if (("${#scripts[@]}" == 0)); then
  log "No numbered chroot modules found in $SCRIPT_DIR"
  exit 1
fi

for script in "${scripts[@]}"; do
  log "Running $(basename -- "$script")"
  /bin/bash "$script"
done

log "All chroot modules completed successfully."
