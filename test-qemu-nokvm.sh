#!/usr/bin/env bash
set -Eeuo pipefail

# Boot the SbeamOS Live ISO with QEMU's software TCG accelerator.
# This deliberately does not use KVM, so it also works without VT-x/AMD-V.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/VERSION"
[[ -s "$VERSION_FILE" ]] || { printf '[ERROR] SbeamOS VERSION file is missing: %s\n' "$VERSION_FILE" >&2; exit 1; }
BUILD_VERSION="$(< "$VERSION_FILE")"
ISO_PATH="${1:-$SCRIPT_DIR/build/SbeamOS-${BUILD_VERSION}-amd64.iso}"

log() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

command -v qemu-system-x86_64 >/dev/null 2>&1 || die "qemu-system-x86_64 is not installed. Install qemu-system-x86 first."
[[ -f "$ISO_PATH" ]] || die "SbeamOS ISO not found: $ISO_PATH"

ISO_PATH="$(realpath -- "$ISO_PATH")"
RAM_MB="${RAM_MB:-4096}"
CPUS="${CPUS:-2}"

[[ "$RAM_MB" =~ ^[0-9]+$ ]] && ((RAM_MB >= 1024)) || die "RAM_MB must be an integer of at least 1024 (MiB)."
[[ "$CPUS" =~ ^[0-9]+$ ]] && ((CPUS >= 1)) || die "CPUS must be a positive integer."

log "Starting SbeamOS with QEMU TCG software emulation (KVM disabled)."
log "ISO: $ISO_PATH"
log "Memory: ${RAM_MB} MiB | CPUs: $CPUS"

exec qemu-system-x86_64 \
  -accel tcg,thread=multi \
  -machine q35 \
  -cpu max \
  -m "$RAM_MB" \
  -smp "$CPUS" \
  -cdrom "$ISO_PATH" \
  -boot order=d \
  -vga std \
  -display gtk
