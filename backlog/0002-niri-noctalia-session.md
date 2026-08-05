# niri + Noctalia v5 session

- **Status:** done (CI-green; real-boot checks in [0003](0003-first-boot-checklist.md))
- **Created:** 2026-08-05
- **Area:** image (`Containerfile`)
- **Depends:** 0000
- **Related:** Steen's `0003` (niri + DankMaterialShell) — the analogue, but Noctalia here
  instead of DMS, and from Fedora instead of a COPR.

## What

Add the niri/Noctalia session alongside GNOME:

```
dnf5 -y install --setopt=install_weak_deps=False niri kitty xwayland-satellite
dnf5 -y install noctalia matugen
```

- **niri weak-deps-off** — niri Recommends waybar/fuzzel/swaylock/alacritty; Noctalia
  provides the bar/launcher/lock, so those are excluded. niri's wanted recommends
  (gnome-keyring, wireplumber, portals) are already present from Silverblue.
- **Noctalia v5 from Fedora** (`5.0.0~beta.7` in F44 `updates`) — bundles its own Quickshell
  fork (`noctalia-qs`), so no COPR and **no quickshell-provenance guard** (the thing Steen's
  DMS needed). `matugen` (Material-You theming) is in Fedora too.
- **xwayland-satellite** — niri has no built-in Xwayland; drives the base's Xwayland server.
- Noctalia is launched from **niri's config** (dotfiles: `spawn-at-startup "noctalia-qs" "-c"
  "noctalia-shell"`), not the image.

## GDM session entry

niri's Fedora package ships `/usr/share/wayland-sessions/niri.desktop`, so GDM offers a
**Niri** session with no extra work. The build **guards** that this file exists — if a future
niri drops it, the build fails loudly and we bake our own session file.

## Guard

Asserts the session landed **and** GNOME/GDM/plumbing survived (additive build — nothing
should have been removed): `niri`, `noctalia`, `matugen`, `kitty`, `xwayland-satellite`
present; the niri session file present; `gnome-shell`, `gdm`, `xdg-desktop-portal-gnome`,
`gnome-keyring`, `pipewire`, `wireplumber`, `NetworkManager` all still present.

## Verification (hardware — see 0003)

- GDM shows **GNOME** and **Niri**; logging into Niri brings up niri + Noctalia (bar,
  launcher, notifications). Screencast works (via `xdg-desktop-portal-gnome`). GNOME session
  still works unchanged.
