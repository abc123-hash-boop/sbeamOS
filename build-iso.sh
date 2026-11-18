#!/usr/bin/env bash
set -Eeuo pipefail

# Build a hybrid BIOS/UEFI Live ISO from the prepared Ubuntu RootFS.
# Run after ./chroot.sh has completed successfully.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS="$SCRIPT_DIR/rootfs"
ISO_CONFIG="$SCRIPT_DIR/scripts/iso/grub.cfg"
BUILD_DIR="$SCRIPT_DIR/build"
VERSION_FILE="$SCRIPT_DIR/VERSION"
[[ -s "$VERSION_FILE" ]] || { printf '[ERROR] SbeamOS VERSION file is missing: %s\n' "$VERSION_FILE" >&2; exit 1; }
BUILD_VERSION="$(< "$VERSION_FILE")"
[[ "$BUILD_VERSION" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { printf '[ERROR] Invalid SbeamOS version: %s\n' "$BUILD_VERSION" >&2; exit 1; }
OUTPUT_ISO="${1:-$BUILD_DIR/SbeamOS-${BUILD_VERSION}-amd64.iso}"

log() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run this script as root: sudo $0 [output.iso]"
[[ -d "$ROOTFS" ]] || die "RootFS not found. Run ./download.sh first."
[[ -f "$ISO_CONFIG" ]] || die "GRUB configuration not found: $ISO_CONFIG"

for command in mksquashfs grub-mkrescue xorriso; do
  command -v "$command" >/dev/null 2>&1 || die "Missing build dependency: $command"
done

for path in dev proc sys run; do
  mountpoint -q "$ROOTFS/$path" && die "RootFS/$path is mounted. Finish or clean up the chroot stage first."
done

[[ -s "$ROOTFS/boot/sbeamos-live-initrd.img" ]] || die "Dedicated Live initrd missing. Run ./chroot.sh successfully first."

kernel_image="$(find "$ROOTFS/boot" -maxdepth 1 -type f -name 'vmlinuz-*' -printf '%f\n' | sort -V | tail -n 1)"
[[ -n "$kernel_image" ]] || die "No installed kernel found in RootFS/boot."
[[ -s "$ROOTFS/boot/$kernel_image" ]] || die "Kernel image is empty: $kernel_image"

mkdir -p "$BUILD_DIR"
mkdir -p "$(dirname -- "$OUTPUT_ISO")"
OUTPUT_ISO="$(realpath -m -- "$OUTPUT_ISO")"
WORK_DIR="$(mktemp -d "$BUILD_DIR/.sbeamos-iso.XXXXXX")"
ISO_ROOT="$WORK_DIR/iso"

cleanup() { rm -rf -- "$WORK_DIR"; }
trap cleanup EXIT INT TERM

log "Preparing ISO filesystem..."
install -d -m 0755 "$ISO_ROOT/boot/grub" "$ISO_ROOT/LiveOS"
install -m 0644 "$ISO_CONFIG" "$ISO_ROOT/boot/grub/grub.cfg"
install -m 0644 "$ROOTFS/boot/$kernel_image" "$ISO_ROOT/boot/vmlinuz"
install -m 0644 "$ROOTFS/boot/sbeamos-live-initrd.img" "$ISO_ROOT/boot/sbeamos-live-initrd.img"

log "Creating compressed SquashFS root filesystem..."
# Keep mount-point directories but exclude their transient contents.
mksquashfs "$ROOTFS" "$ISO_ROOT/LiveOS/rootfs.squashfs" \
  -noappend -comp zstd -Xcompression-level 22 -b 1M -wildcards \
  -e 'dev/*' 'proc/*' 'sys/*' 'run/*' 'tmp/*'

[[ -s "$ISO_ROOT/LiveOS/rootfs.squashfs" ]] || die "SquashFS image was not created."

log "Generating hybrid BIOS/UEFI ISO (volume label: SBEAMOS)..."
grub-mkrescue -o "$OUTPUT_ISO" -V SBEAMOS "$ISO_ROOT"

[[ -s "$OUTPUT_ISO" ]] || die "GRUB did not create the ISO image."

log "Validating ISO metadata..."
if command -v xorriso >/dev/null 2>&1; then
  xorriso -indev "$OUTPUT_ISO" -pvd_info 2>&1 | grep -F 'SBEAMOS' >/dev/null \
    || die "ISO volume label validation failed; expected SBEAMOS."
fi

log "SbeamOS ISO build completed."
printf '[INFO] Kernel: %s\n' "$kernel_image"
printf '[INFO] ISO: %s\n' "$OUTPUT_ISO"
printf '[INFO] Size: %s\n' "$(du -h "$OUTPUT_ISO" | awk '{print $1}')"
