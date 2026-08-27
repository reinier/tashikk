# Packaging spike: how do umbriel / xdg-desktop-portal-umbriel actually reach Fedora 44

- **Status:** resolved — verified against real `dnf5` 2026-08-27
- **Created:** 2026-08-27
- **Area:** image (`Containerfile` — decides the install stanza for 0006)
- **Depends:** —
- **Related:** 0000, 0002 (niri + Noctalia v5 — Noctalia itself is **not** in question here,
  it's already installed and working; this item is only about Umbriel); Azir `0000` (the
  avengemedia-COPR + quickshell-provenance-guard precedent — same shape of problem if Umbriel
  also ends up needing a third-party repo + a guard)

## Problem

Umbriel — Noctalia's own wlroots 0.20 + SceneFX compositor (C++23), scrolling *and* dwindle
layouts — is going to be added as a **third** GDM session alongside GNOME and Niri (both kept,
unchanged). Conflicting information turned up researching where it actually comes from, none
of it verified against real `dnf5`:

- Umbriel was seen documented as installed via the **Terra** repo
  (`repos.fyralabs.com/terra`) rather than Fedora's own repos or a COPR.
- `xdg-desktop-portal-umbriel` is confirmed to exist as a package name somewhere but its exact
  repo (Fedora / Terra / COPR) is not.

Don't trust either claim until it's been run for real — the disagreement itself is the
finding: this needs a `dnf5 repoquery`, not another docs page.

## What to do

On a Fedora 44 box (a plain `fedora:44` container is cheaper than a Silverblue VM for this
check):

```sh
dnf5 repoquery umbriel xdg-desktop-portal-umbriel 2>&1
# if empty, try Terra:
dnf5 -y install --nogpgcheck \
  --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
dnf5 repoquery umbriel xdg-desktop-portal-umbriel --repo='terra*'
```

Record, per package: which repo satisfies it, the version, and whether Umbriel pulls in
anything Noctalia-adjacent via weak deps (`rpm -q --requires umbriel`) that would double up
with what niri's session already installs. If nothing resolves from either Fedora or Terra,
the fallback is building Umbriel from source (Meson + `just release`, per its own README) as
its own multi-stage `Containerfile` build, the way Azir builds keyd from source — a materially
bigger lift, so worth ruling out the easy paths first.

Also check while here: does Umbriel's package ship a `wayland-sessions/umbriel.desktop` (niri's
does; that's what let this session skip baking a session file by hand)? Feeds directly into
0006's implementation.

## Verification

A short-lived scratch build (`FROM fedora:44`, the repoquery/install lines above, nothing
else) resolves both packages and reports their `from_repo`. That output becomes the actual
install stanza in 0006 — this item is done when that stanza is known, not guessed.

## Findings (verified 2026-08-27, real `dnf5 repoquery` against Terra, `--releasever=44`)

Both packages resolve from **Terra**, `fc44`-tagged, `x86_64` + `aarch64`, right now:

| Package | Version | Repo |
|---|---|---|
| `umbriel-nightly` | `0^20260827git.7327c92-1.fc44` | Terra |
| `xdg-desktop-portal-umbriel-nightly` | `0^20260824git.515c9f7-1.fc44` | Terra |

**No stable release package exists yet — only `-nightly` (git-snapshot, built from
upstream HEAD via Terra's `anda` build system).** There is no plain `umbriel` /
`xdg-desktop-portal-umbriel` name in Terra to fall back to; the `-nightly` names are the
actual package names for 0006's install stanza. Both spec sources checked directly
(`terrapkg/packages` monorepo, `anda/desktops/umbriel/`):

- **`umbriel-nightly` `Requires: xwayland-satellite, xdg-desktop-portal-umbriel-nightly`** —
  installing `umbriel-nightly` alone pulls the portal in automatically; no separate install
  line needed for it.
- **Ships `%{_datadir}/wayland-sessions/umbriel.desktop`** — confirmed, resolves 0006's open
  GDM-session-entry question. No hand-baked `.desktop` needed, same as niri.
- Session is systemd-user-unit managed: `umbriel.service`, `umbriel-session.target`,
  `umbriel-shutdown.target` (from `%post`/`%preun`/`%postun` `%systemd_user_*` macros) — a
  different startup mechanism than niri's bare-compositor-from-GDM approach, worth confirming
  on hardware in 0006's verification.
- Portal registers the standard way: `org.freedesktop.impl.portal.desktop.umbriel.service` +
  `umbriel.portal` + `%config %{_datadir}/xdg-desktop-portal/umbriel-portals.conf` — same
  shape niri/hyprland-style portal backends use to scope themselves to their own session
  (usually via `XDG_CURRENT_DESKTOP` matching in the `.portal` file), which is why it likely
  coexists with `xdg-desktop-portal-gnome` rather than fighting it — but the actual `.conf`
  contents weren't inspected, so 0006's guard should still verify this on hardware rather than
  assume it.

**Not yet checked:** `noctalia-greeter` (irrelevant — GDM stays, not in scope) and whether
Terra needs to be added permanently to the image or can be used transiently-then-dropped the
way Azir does for ghostty/starship/yazi (0006's call, since it affects update cadence: Terra
"nightly" packages mean Tashikk's Umbriel session tracks upstream HEAD on every rebuild unless
pinned).
