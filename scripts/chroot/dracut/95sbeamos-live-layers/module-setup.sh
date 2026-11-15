#!/bin/bash

check() {
    # This module is only for the dedicated Live initramfs.
    [[ $hostonly ]] && return 1
    return 255
}

depends() {
    echo "dmsquash-live dmsquash-live-autooverlay overlayfs"
}

install() {
    inst_hook pre-pivot 90 "$moddir/sbeamos-live-prepare.sh"
}
