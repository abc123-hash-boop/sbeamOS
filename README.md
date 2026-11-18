# SbeamOS

SbeamOS alpha-3 is an Ubuntu 26.04 (Resolute)-based Linux desktop distribution project.
The SbeamOS release identifier is maintained in the root `VERSION` file; the
current release candidate is alpha-3.
The current build targets amd64 PCs and uses GNOME, systemd, Dracut, SquashFS,
OverlayFS and GRUB for its Live environment. Casper is not part of the Live
boot design. A first GTK 3 graphical installer prototype is included and is
installed into the Live image by the chroot build stage.

## Desktop appearance

SbeamOS uses its own Aurora visual system: a crisp light surface palette, deep slate typography, a blue accent, custom GTK 3 and GTK 4/libadwaita styling, a matching GNOME Shell theme, and original SbeamOS folder and app icons. GNOME Tweaks and Extension Manager remain available for user customization. Blur my Shell and Kiwi Menu are optional desktop extensions that provide translucent surfaces and an alternate top-bar menu; they are not the source of the SbeamOS theme.

The visual style is implemented with GNOME Shell extensions and GTK themes; it does not replace GNOME with KDE or use proprietary macOS system files. See [docs/THEMING.md](docs/THEMING.md) for components, pinned source revisions and license details.

## Build stages

Run the scripts from the repository root; they resolve their own paths, so the
current working directory does not need to be the project directory.

```bash
./download.sh
./chroot.sh
sudo ./build-iso.sh
```

`download.sh` creates the Ubuntu RootFS with debootstrap. `chroot.sh` installs
and configures the SbeamOS system, kernel, GNOME desktop, Google Chrome Stable,
everyday desktop applications and dedicated Dracut Live initramfs.
`build-iso.sh` creates a SquashFS root image and invokes GRUB to produce a
hybrid BIOS/UEFI ISO.

### Included desktop applications

- **Web:** Google Chrome Stable (official Google DEB and APT repository).
- **Office:** LibreOffice Writer, Calc and Impress.
- **PDF:** Papers.
- **Video and music:** Showtime and Rhythmbox.
- **Files and screenshots:** File Roller and GNOME Screenshot.
- **Scanning and credentials:** Document Scanner (Simple Scan) and Seahorse.
- **Calendar:** GNOME Calendar.
- **Downloads:** Transmission GTK.
- **Existing GNOME utilities:** Calculator, Text Editor, Loupe, Disks and
  System Monitor.

The application modules use Ubuntu's Resolute APT archive wherever possible.
Google Chrome is downloaded from Google's official Debian package endpoint.
Optional creative, development and gaming software is intentionally not part
of the base image.

The ISO builder requires host packages:

```bash
sudo apt-get update
sudo apt-get install debootstrap squashfs-tools grub-common grub-pc-bin \
  grub-efi-amd64-bin xorriso mtools
```

See [`scripts/iso/BUILD.md`](scripts/iso/BUILD.md) for details.

## Current status

This repository contains the build scripts, Live boot configuration and an
early GTK 3 system installer. The installer currently supports fresh installs
to a whole disk using GPT, an EFI System Partition and ext4 root. It does not
support dual boot, manual partitioning, encryption, RAID, LVM or Btrfs.

The installer and full RootFS/ISO flow have not yet been validated end-to-end
on physical hardware or under both BIOS and UEFI QEMU firmware. Treat the
installer as experimental and use disposable virtual disks for installation
tests. A successful Python test run does not establish that disk installation
or booting works.

## Wallpaper assets

The WIP12 wallpaper images are not included in this repository because their
redistribution terms have not been verified. To build with the bundled wallpaper
step enabled, obtain the images under terms that permit redistribution and place
the PNG files in `scripts/chroot/wallpapers/` before running `chroot.sh`.

## License

No repository-wide license has been declared yet. Unless a file states
otherwise, do not assume that the contents are available for unrestricted
reuse or redistribution.
