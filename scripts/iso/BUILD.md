# Building the SbeamOS Live ISO

Run the stages in order from any working directory:

```bash
./download.sh
./chroot.sh
sudo ./build-iso.sh
```

The ISO stage requires these host tools:

- `squashfs-tools` (`mksquashfs`)
- `grub-common` / GRUB BIOS and EFI platform utilities (`grub-mkrescue`)
- `xorriso`

Install them on Ubuntu with:

```bash
sudo apt-get update
sudo apt-get install squashfs-tools grub-common grub-pc-bin grub-efi-amd64-bin xorriso mtools
```

The builder does not install host packages automatically. It checks that the
RootFS has a kernel and `/boot/sbeamos-live-initrd.img`, creates
`LiveOS/rootfs.squashfs`, stages the kernel and initrd, and invokes
`grub-mkrescue` to produce a hybrid BIOS/UEFI ISO with volume label `SBEAMOS`.

Default output:

```text
build/SbeamOS-26.04-amd64.iso
```

An alternate output path can be supplied as the first argument:

```bash
sudo ./build-iso.sh /path/to/SbeamOS.iso
```

The build is intentionally separate from `chroot.sh`: it never re-runs package
installation or modifies the prepared RootFS. It excludes transient contents
under `/dev`, `/proc`, `/sys`, `/run`, and `/tmp` from SquashFS.

A successful ISO build is not a substitute for boot testing. Test the image in
both UEFI and legacy BIOS modes (for example, with QEMU) before distributing it.
