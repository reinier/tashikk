# Display management under Umbriel (does it need niri's kanshi/wdisplays layer?)

- **Status:** mostly resolved 2026-08-27 (Noctalia panel + config mechanism confirmed;
  kanshi-on-dock/undock still untested)
- **Created:** 2026-08-27
- **Area:** image (`Containerfile`) + dotfiles
- **Depends:** 0006
- **Related:** 0004 (niri had zero display story of its own; needed kanshi + wdisplays baked
  in — that stays exactly as-is for the Niri session regardless of what this item finds)

## Problem

0004 established that **niri has no display GUI or persistence beyond static config blocks**,
so the image bakes kanshi (auto-apply on dock/undock) + wdisplays (GUI, live-only). Whether
**Umbriel** needs the same layer is a separate, open question — it isn't known yet.

Umbriel's own config already has an `[outputs]` section (per its docs' config-reference
categories: general, appearance, layout, input, keybinds, scratchpads, **outputs**,
window/layer rules) — that's at least niri-`output`-block-equivalent declarative persistence
built into the compositor itself, which niri never had (0004 had to reach for kanshi/wdisplays
specifically *because* niri's own output config was that thin). Whether Noctalia v5 adds a
live arrangement panel on top of that is unconfirmed — check its widget/settings-panel list
when this item is actually worked.

## What to do

Once 0006 is booting: read Umbriel's `outputs` config-reference page for real, check whether
Noctalia v5 ships a display panel under Umbriel specifically, and decide between reusing the
already-baked kanshi+wdisplays (works via `wlr-output-management`, so it may already work
under Umbriel with zero extra image changes — worth checking before assuming anything new is
needed), or something Umbriel-native. Don't bake anything extra speculatively.

## Verification

Multi-monitor test machine: outputs come up correctly under Umbriel, whether from its own
`[outputs]` config or the existing kanshi/wdisplays layer; if kanshi is reused, it re-applies
on dock/undock same as it does under niri. Niri and GNOME sessions' display behavior
unaffected either way.

## Findings (2026-08-27, checked against real docs, not summaries)

**Noctalia has no display-arrangement panel under Umbriel either** — confirmed from
`docs.noctalia.dev/noctalia/control-center/`. The Control Center's **Monitor** tab is
brightness-only ("Brightness controls for displays that expose writable backlight devices");
no resolution, position, scale, or output enable/disable anywhere in the Control Center. Same
gap as niri, not Umbriel-specific.

**Umbriel's own `[output."<name>"]` blocks are the real mechanism** (`dotfiles-tashikk`
already uses this for `eDP-1` HiDPI: `scale = 2`) — and they're richer than niri's `output {}`
ever was: `mode`, `position`, `scale`, `vrr` (`disabled`/`always`/`fullscreen`), `tearing`,
`direct_scanout`, `hdr` (`off`/`on`/`auto`/`fullscreen`), `sdr_white`, `workspaces`
(per-output dynamic/static), `transform`. niri needed kanshi partly to cover ground its own
output blocks left empty (VRR wasn't one of niri's config options at all) — Umbriel's own
config already covers most of that natively.

**`wdisplays` should work unmodified under Umbriel** — confirmed Umbriel implements
`wlr-output-management-unstable-v1` (`protocols/wlr-output-management-unstable-v1.xml` in
`noctalia-dev/umbriel`), the exact protocol `wdisplays` uses for live drag-to-arrange under
niri. Same caveat as niri: live-only, doesn't persist — read the numbers off, copy them into
`[output."<name>"]` in `dotfiles-tashikk`'s `dot_config/umbriel/config.toml`. Not yet
hardware-verified that `wdisplays` actually launches correctly under Umbriel, just that the
protocol dependency it needs is present.

**Still open:** whether `kanshi` (auto-reapply on dock/undock) is needed under Umbriel, or
whether something about Umbriel's own output handling covers that case — no doc evidence
either way, needs an actual dock/undock test. If needed, it should work unmodified (same
`wlr-output-management` dependency, confirmed present) — the only image change would be
spawning it from `[general] autostart` in the Umbriel dotfiles config instead of niri's
`spawn-at-startup`, mirroring the split already used there.
