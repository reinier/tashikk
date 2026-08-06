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
3. **GUI (optional, NOT in the image): nwg-displays.** The community-standard niri display GUI
   — it's niri-aware and **persists** the arrangement (arrange → save), which is the whole
   point. It's **not in Fedora**, so it goes in the `apps` distrobox or as a Flatpak, exactly
   the ad-hoc-tooling path that exists for this.

## Why not wdisplays (even though it's in Fedora)

`wdisplays` drives outputs live through `wlr-output-management` but **doesn't write niri's
config** — niri doesn't persist runtime output changes, so a wdisplays arrangement is lost on
restart. It's a "nudge now" tool, not a "set up my monitors" tool. Persistence (nwg-displays)
beats packaging convenience here, so wdisplays is deliberately **not** baked.

## Implementation

- **Image:** `kanshi` added to the niri session install (done).
- **Dotfiles (done):** kanshi is **spawned from niri** (`local/startup.kdl`, not the systemd
  user unit — so it inherits the session's `WAYLAND_DISPLAY` and only runs under niri) with a
  starter `~/.config/kanshi/config`; `output {}` blocks go in `local/settings.kdl`.
- **User choice:** install `nwg-displays` via Flatpak / the `apps` distrobox if a GUI is wanted.

## Verification

- niri session: displays come up per the dotfiles' `output` blocks; `niri msg outputs` lists
  them; docking/undocking re-applies via kanshi. GNOME session's own display panel unaffected.
