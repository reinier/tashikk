# Display management under niri (Noctalia has none)

- **Status:** accepted (kanshi baked; GUI is a dotfiles/Flatpak concern)
- **Created:** 2026-08-05
- **Area:** image (`Containerfile`) + dotfiles
- **Depends:** 0002
- **Related:** [niri Outputs wiki](https://github.com/niri-wm/niri/wiki/Configuration:-Outputs);
  [nwg-displays niri support](https://github.com/nwg-piotr/nwg-displays/issues/84)

## Problem

**Noctalia (v4 and v5) has no display-arrangement panel** — its "scaling" settings only affect
Noctalia's own shell UI (bar/panels/launcher), and the docs explicitly defer real display
config to the compositor. **niri has no built-in GUI either.** And in Tashikk specifically,
**GNOME Settings → Displays only works in the GNOME session** (it talks to mutter, not niri),
so it can't configure the niri session. So the niri/Noctalia session needs its own answer.

## Approach (three layers)

1. **niri `output {}` blocks in the dotfiles — the source of truth.** Declarative, persistent:
   ```kdl
   output "eDP-1" { mode "2256x1504@60"; scale 1.5; position x=0 y=0 }
   ```
   Live queries/tweaks without editing: `niri msg outputs`, `niri msg output eDP-1 scale 2`.
2. **kanshi — baked into the image.** Auto-applies output profiles on dock/undock (via
   `wlr-output-management`, which niri implements). Enabled as a **user service from the
   dotfiles**, not in the image. This is the set-and-forget laptop layer.
3. **GUI: `wdisplays` (baked).** A drag-to-arrange GUI that works under niri via
   `wlr-output-management`. It's **live-only** (doesn't write niri's config), so it's the
   "see the layout / read off the numbers" tool — you then persist those into the `output {}`
   blocks and/or the kanshi config above. In Fedora's repos, so it's a clean one-package bake.

## Why not nwg-displays (the niri-aware GUI that persists)

nwg-displays would be nicer (it writes the compositor's output config), but it is **not
packaged for Fedora atomic anywhere** — not Flathub, Fedora, Terra, PyPI, or the
`solopasha/hyprland` COPR (checked 2026-08). Upstream ships it only as a git/meson Python
build or via the AUR, and its niri support is not clearly released. Baking a Python app from
git for uncertain niri support isn't worth it when `wdisplays` + `output {}` + kanshi already
cover the need. Revisit if it lands in a Fedora-reachable repo.

## Implementation

- **Image:** `kanshi` + `wdisplays` added to the niri session install (done).
- **Dotfiles (done):** kanshi is **spawned from niri** (`local/startup.kdl`, not the systemd
  user unit — so it inherits the session's `WAYLAND_DISPLAY` and only runs under niri) with a
  starter `~/.config/kanshi/config`; `output {}` blocks go in `local/settings.kdl`.
- **GUI:** `wdisplays` (baked) for a visual arrange; copy the numbers into the output blocks /
  kanshi config to persist.

## Verification

- niri session: displays come up per the dotfiles' `output` blocks; `niri msg outputs` lists
  them; docking/undocking re-applies via kanshi. GNOME session's own display panel unaffected.
