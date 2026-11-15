#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

log() {
  printf '[INFO] %s\n' "$*"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULE_SOURCE="$SCRIPT_DIR/dracut/95sbeamos-live-layers"
MODULE_TARGET="/usr/lib/dracut/modules.d/95sbeamos-live-layers"

log "Installing the SbeamOS Dracut Live integration module..."
[[ -f "$MODULE_SOURCE/module-setup.sh" ]] || {
  printf '[ERROR] Missing Dracut module: %s\n' "$MODULE_SOURCE/module-setup.sh" >&2
  exit 1
}
[[ -f "$MODULE_SOURCE/sbeamos-live-prepare.sh" ]] || {
  printf '[ERROR] Missing Live preparation hook.\n' >&2
  exit 1
}

install -d -m 0755 "$MODULE_TARGET"
install -m 0644 "$MODULE_SOURCE/module-setup.sh" "$MODULE_TARGET/module-setup.sh"
install -m 0644 "$MODULE_SOURCE/sbeamos-live-prepare.sh" "$MODULE_TARGET/sbeamos-live-prepare.sh"

log "Checking that the required upstream Dracut modules are available..."
available_modules="$(dracut --list-modules)"
for module in dmsquash-live dmsquash-live-autooverlay overlayfs sbeamos-live-layers; do
  if ! grep -Fxq "$module" <<< "$available_modules"; then
    printf '[ERROR] Required Dracut module is unavailable: %s\n' "$module" >&2
    exit 1
  fi
done

log "Building the dedicated non-host-only SbeamOS Live initrd..."
kernel_version="$(find /lib/modules -mindepth 1 -maxdepth 1 -type d \
  -printf '%f\n' | sort -V | tail -n 1)"

[[ -n "$kernel_version" ]] || {
  printf '[ERROR] No installed kernel modules were found.\n' >&2
  exit 1
}

live_initrd="/boot/sbeamos-live-initrd.img"

# Include only drivers shipped with this kernel. Some display drivers (notably
# qxl and bochs) live in Ubuntu's linux-modules-extra package and may be absent
# from a minimal kernel installation. Dracut's Live modules handle the core
# loop/squashfs/overlay requirements and pull in their own dependencies.
requested_drivers=(loop squashfs overlay virtio_gpu qxl bochs vmwgfx vboxvideo)
add_drivers=()
for driver in "${requested_drivers[@]}"; do
  if modinfo -k "$kernel_version" "$driver" >/dev/null 2>&1; then
    add_drivers+=("$driver")
  else
    log "Kernel driver is unavailable and will be skipped: $driver"
  fi
done

log "Including kernel drivers: ${add_drivers[*]:-(Dracut defaults)}"
dracut_args=(
  --force
  --no-hostonly
  --no-hostonly-cmdline
  --add "dmsquash-live dmsquash-live-autooverlay overlayfs sbeamos-live-layers"
)
if ((${#add_drivers[@]})); then
  dracut_args+=(--add-drivers "${add_drivers[*]}")
fi

dracut "${dracut_args[@]}" "$live_initrd" "$kernel_version"

[[ -s "$live_initrd" ]] || {
  printf '[ERROR] Dracut did not create a valid Live initrd.\n' >&2
  exit 1
}

log "Inspecting the generated Live initrd..."
lsinitrd -m "$live_initrd" | grep -Fxq "sbeamos-live-layers" || {
  printf '[ERROR] The generated initrd is missing the SbeamOS Live module.\n' >&2
  exit 1
}
lsinitrd "$live_initrd" | grep -E 'dmsquash-live|create-overlay' >/dev/null || {
  printf '[ERROR] The generated initrd is missing upstream Live root components.\n' >&2
  exit 1
}

log "SbeamOS Live initrd created for kernel $kernel_version."
