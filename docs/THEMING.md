# SbeamOS Aurora theme

SbeamOS Aurora is the first-party visual identity for the SbeamOS GNOME desktop. The GTK theme, libadwaita overrides, GNOME Shell stylesheet, icon theme metadata, and branded SVG icons are maintained in this repository; no third-party desktop theme is downloaded or installed.

## Design language

- **Palette:** Aurora blue (`#2878e5`) for primary actions, pale cloud surfaces (`#f4f7fc`), white content cards, and deep slate text (`#17243a`).
- **GTK 3:** native CSS styling for headers, buttons, entries, sidebars, selections, menus, tooltips, and progress controls.
- **GTK 4 / libadwaita:** matching system color tokens and surface refinements seeded for new Live users.
- **GNOME Shell:** dark translucent top panel, blue interaction states, rounded popup surfaces, and a matching overview search field.
- **Icons:** SbeamOS icon theme inherits the complete Adwaita set and supplies original blue folder and SbeamOS app marks.
- **Desktop layout:** Ubuntu Dock remains at the bottom; DING provides desktop icons. Window controls are placed on the left.

## Optional extensions and tools

Blur my Shell provides configurable blur effects. Kiwi Menu provides an alternate top-bar menu. These are independent GNOME extensions, not the theme itself. GNOME Tweaks and Extension Manager are intentionally installed so users can customize the desktop and manage extensions.

## Source files

- `scripts/chroot/18-sbeamos-aurora-theme.sh` — installs the first-party Aurora theme and icon assets, then installs the pinned extensions.
- `scripts/chroot/09-gnome-desktop-defaults.sh` — enables the theme and configures the initial desktop layout.

The third-party extension license notices and source revisions are installed under `/usr/share/doc/sbeamos-theme-licenses/`.
