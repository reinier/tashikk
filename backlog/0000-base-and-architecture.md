# Base + architecture: additive on Fedora Silverblue

- **Status:** accepted
- **Created:** 2026-08-05
- **Area:** image (`Containerfile` `FROM` + overall shape)
- **Depends:** —
- **Related:** [Steen](https://github.com/reinier/steen) (the subtractive counterpart);
  Steen's `0000` (base-image choice); Silverblue
  ([atomic desktops](https://fedoraproject.org/atomic-desktops/silverblue/)).

## Decision

Tashikk builds **`FROM quay.io/fedora-ostree-desktops/silverblue:44`** and is **additive**:
keep the full GNOME desktop and GDM, add **niri + Noctalia v5** as an alternative Wayland
session, and layer a personal app stack on top. **No subtraction layer.**

## Why additive on Silverblue (not Steen's approach)

Steen strips a Sway Atomic base down to a niri-only desktop — which means a subtraction layer
(remove sway/waybar/…) that proved to be its biggest source of complexity and regressions
(double-bar, cascade removals, leftover sweeps). Tashikk wants **both** desktops, so:

- **Keep GNOME/GDM** → no subtraction at all. GDM gains a "Niri" session entry automatically
  once niri is installed (niri ships `/usr/share/wayland-sessions/niri.desktop`).
- **Inherit Silverblue's plumbing** → PipeWire, portals (incl. `xdg-desktop-portal-gnome`,
  which niri uses for screencast), polkit, gnome-keyring/gcr, NetworkManager, fwupd/fprintd/
  bolt, cups + the GNOME printer panel, GNOME Software + flatpak, fonts. Nothing to add there.
- **Noctalia v5 is in Fedora's official repos (F44+)** — `dnf install noctalia` — and bundles
  its own Quickshell fork (`noctalia-qs`), so there's no COPR and no quickshell-provenance
  guard like Steen's DMS needed. `matugen` (theming) is in Fedora too. This is materially
  simpler than Steen's desktop layer.

## What niri needs that GNOME doesn't cover

- `niri` (Fedora), installed **weak-deps-off** so its Recommends (waybar/fuzzel/swaylock/
  alacritty) don't tag along — Noctalia provides the bar/launcher/lock.
- `xwayland-satellite` — niri has no built-in Xwayland; it drives the base's Xwayland server.
- `kitty` — terminal.
- Noctalia is launched from **niri's config** (dotfiles: `spawn-at-startup "noctalia-qs" "-c"
  "noctalia-shell"`), not from the image.

## /opt on Silverblue

Silverblue is ostree, so `/opt` is a symlink to `/var/opt` (image `/opt` content is masked at
runtime). So 1Password/Synology use the **relocation dance** (payload → `/usr/lib/opt`,
restore the symlink, tmpfiles recreates `/opt/...` at boot) — the same as Steen's sway-atomic
build, **not** the simpler fedora-bootc handling from Steen's build-up spike.

## Consequences

- Drops from the Steen port: greetd + dms-greeter (keep GDM), printer GUI (GNOME panel),
  Bazaar (GNOME Software), the whole Sway-removal layer.
- Firefox stays (Silverblue default); Chromium is *added* (for 1Password native-messaging +
  web-app launchers), not swapped in.

## Verification

- Builds green + `bootc container lint` clean.
- Rebase from Silverblue; GDM offers **GNOME** and **Niri**; both sessions come up; the
  personal apps work (see [0003](0003-first-boot-checklist.md)).
