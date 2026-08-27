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

As of 0005–0007, Tashikk is growing a **third** session the same additive way: **Umbriel**
(Noctalia's own compositor) alongside GNOME and Niri — not a replacement for either. GDM ends
up offering all three; Noctalia is shared across both niri and Umbriel.

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
5. [0005-umbriel-packaging-spike.md](0005-umbriel-packaging-spike.md) — **resolved.**
   `umbriel-nightly` + `xdg-desktop-portal-umbriel-nightly` confirmed live on Terra
   (`fc44`, both arches) via real `dnf5 repoquery`; no stable release yet, nightly only.
6. [0006-umbriel-session.md](0006-umbriel-session.md) — **implemented**, unverified on
   hardware. Adds Umbriel as a third GDM session using 0005's confirmed package names
   (unpinned, tracks Terra's `-nightly` HEAD until a beta/1.0 lands); Noctalia shared with the
   existing niri session, launched from Umbriel's own config.
7. [0007-umbriel-display-management.md](0007-umbriel-display-management.md) — depends on
   0006. Whether Umbriel's own `[outputs]` config (or the existing kanshi/wdisplays bake)
   already covers displays, or something new is needed.

## Ported wholesale from Steen (no separate item needed)

1Password (+CLI, /opt relocation, sysusers GIDs, ptrace), Synology Drive, Chromium+codecs,
keyd (source build), Tailscale, the CLI toolkit (Fedora + Terra), the Nerd Font, distrobox,
Flathub remote, and the manual-update timer masking. See Steen's backlog for the reasoning;
Tashikk's `Containerfile` carries the same stanzas.

## Deliberately NOT ported (Silverblue provides it)

greetd + dms-greeter (keep GDM), the printer GUI (GNOME printer panel), Bazaar (GNOME
Software), and the entire Sway-subtraction layer (nothing to subtract — GNOME stays).
