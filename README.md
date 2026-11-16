# SbeamOS

SbeamOS is an Ubuntu 26.04 (Resolute)-based Linux desktop distribution project.
The current build targets amd64 PCs and uses GNOME, systemd, Dracut, SquashFS,
OverlayFS and GRUB for its planned Live environment. Casper is not part of the
Live boot design.

## Build stages

Run the scripts from the repository root; they resolve their own paths, so the
current working directory does not need to be the project directory.

```bash
./download.sh
./chroot.sh
sudo ./build-iso.sh
```

`download.sh` creates the Ubuntu RootFS with debootstrap. `chroot.sh` installs
and configures the SbeamOS system, kernel, GNOME desktop, Google Chrome Stable
and dedicated Dracut Live initramfs. `build-iso.sh` creates a SquashFS root
image and invokes GRUB to produce a hybrid BIOS/UEFI ISO.

The Chrome build module downloads Google's official amd64 DEB package during
the chroot stage. It configures Chrome as the default browser and uses the
Google APT repository for subsequent stable-channel updates. Chrome is
proprietary software; it is not part of the Ubuntu archive.

The ISO builder requires host packages:

```bash
sudo apt-get update
sudo apt-get install debootstrap squashfs-tools grub-common grub-pc-bin \
  grub-efi-amd64-bin xorriso mtools
```

See [`scripts/iso/BUILD.md`](scripts/iso/BUILD.md) for details.

## Current status

This repository contains the build scripts and Live boot configuration. The
full RootFS installation, ISO generation and UEFI/BIOS boot tests are still
required before this can be considered a boot-verified release.

## Wallpaper assets

The WIP12 wallpaper images are not included in this repository because their
redistribution terms have not been verified. To build with the bundled wallpaper
step enabled, obtain the images under terms that permit redistribution and place
the PNG files in `scripts/chroot/wallpapers/` before running `chroot.sh`.

## License

No repository-wide license has been declared yet. Unless a file states
otherwise, do not assume that the contents are available for unrestricted
reuse or redistribution.
