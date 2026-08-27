# Display management under Umbriel (does it need niri's kanshi/wdisplays layer?)

- **Status:** open
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
