# backlog

The build plan for **Tashikk** — one Markdown item per piece of work. Same convention as
[Steen's backlog](https://github.com/reinier/steen/tree/main/backlog); much of Tashikk is a
straight port of Steen's app layers, so many items are short "ported from Steen" notes.

## Conventions

- One item per file, `NNNN-kebab-case.md`. The prefix is rough build order, not a hard
  dependency graph — read `Depends`.
- Frontmatter block: `Status` / `Created` / `Area` / `Depends` / `Related`, then
  Problem → Options → Recommendation → Implementation → Verification.

## The shape of Tashikk (vs Steen)

Tashikk is **additive on Silverblue**: keep GNOME + GDM, add niri + Noctalia as an alternate
session, layer the personal app stack. There is **no subtraction layer** (Steen's biggest
source of complexity), and most plumbing is inherited from Silverblue, so the port drops
Steen's greetd/dms-greeter, printer GUI, and Sway-removal items entirely.

## Items

0. [0000-base-and-architecture.md](0000-base-and-architecture.md) — decision record: why
   `FROM silverblue`, additive, GNOME kept, niri+Noctalia as a GDM session.
1. [0001-signing.md](0001-signing.md) — **done**: signed update stream (baked `cosign.pub` +
   sigstoreSigned policy; CI signs with `SIGNING_SECRET`). Key shared with Steen, but
   `matchRepository` keeps signatures per-repo.
2. [0002-niri-noctalia-session.md](0002-niri-noctalia-session.md) — niri + Noctalia v5 +
   matugen + kitty + xwayland-satellite; the GDM "Niri" session entry.
3. [0003-first-boot-checklist.md](0003-first-boot-checklist.md) — living hardware/boot
   verification (the parts CI can't prove).
4. [0004-display-management.md](0004-display-management.md) — displays under niri (Noctalia
   has no panel): niri `output` blocks + kanshi (baked) + nwg-displays (Flatpak, optional).

## Ported wholesale from Steen (no separate item needed)

1Password (+CLI, /opt relocation, sysusers GIDs, ptrace), Synology Drive, Chromium+codecs,
keyd (source build), Tailscale, the CLI toolkit (Fedora + Terra), the Nerd Font, distrobox,
Flathub remote, and the manual-update timer masking. See Steen's backlog for the reasoning;
Tashikk's `Containerfile` carries the same stanzas.

## Deliberately NOT ported (Silverblue provides it)

greetd + dms-greeter (keep GDM), the printer GUI (GNOME printer panel), Bazaar (GNOME
Software), and the entire Sway-subtraction layer (nothing to subtract — GNOME stays).
