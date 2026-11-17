# SbeamOS Golden Gate desktop theme

SbeamOS keeps GNOME Shell as its desktop environment and layers a macOS 27 Golden Gate-inspired appearance on top of it.

## Components

- **GTK and GNOME Shell theme:** MacTahoe GTK, built and installed as `SbeamOS-Light-blue` with the light-blue accent, left-side window controls, rounded maximized windows and translucent styling.
- **Libadwaita:** matching GTK 4 CSS and assets are seeded into `/etc/skel/.config/gtk-4.0` for the Live user. The CSS links are made relative so they remain valid after the temporary theme-build home is removed.
- **Icons:** MacTahoe icon theme, installed as `SbeamOS-blue`.
- **Liquid Glass effects:** Blur my Shell, enabled for the top panel and Dock.
- **Top-bar menu:** Kiwi Menu, using its Apple icon and macOS-style menu layout.
- **Desktop layout:** Ubuntu Dock remains at the bottom; DING provides desktop icons. Window controls are placed on the left.

The theme is applied through GNOME settings and extensions. No proprietary macOS system files are included.

## Pinned upstream sources

| Component | Repository | Commit | License |
|---|---|---|---|
| GTK theme | [MacTahoe-gtk-theme](https://github.com/vinceliuice/MacTahoe-gtk-theme) | `1e45e19f510edb8cde18fa84d6cd5319f60b086b` | MIT |
| Icon theme | [MacTahoe-icon-theme](https://github.com/vinceliuice/MacTahoe-icon-theme) | `839848b9a8a38a92a6936e30c4abe35cc6f2546d` | GPL-3.0 |
| Blur extension | [blur-my-shell](https://github.com/aunetx/blur-my-shell) | `3556b496cfdcd3303f9d56f8c828d94c39965660` | GPL-3.0-or-later |
| Menu extension | [kiwi-menu](https://github.com/kem-a/kiwi-menu) | `9cb445430b30f182fb2c7ec32cc4c027bc792c0e` | GPL-3.0 |

The build module `scripts/chroot/18-golden-gate-theme.sh` fetches these exact revisions and installs their license notices and source manifest into `/usr/share/doc/sbeamos-theme-licenses/` in the image.

## Customization

The Live desktop starts with the Golden Gate appearance enabled. Users can further adjust GTK and icon settings with **GNOME Tweaks**, and manage or configure Shell extensions with **Extension Manager**.
