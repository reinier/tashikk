# Umbriel session (third GDM entry, alongside GNOME + Niri)

- **Status:** implemented (Containerfile stanza + guard written 2026-08-27; unverified on
  hardware — see 0003)
- **Created:** 2026-08-27
- **Area:** image (`Containerfile`)
- **Depends:** 0005
- **Related:** 0002 (niri + Noctalia v5 — Umbriel is additive *on top of* that, niri stays
  exactly as-is); Azir `0000` (the "spawn the shell from the compositor config, not
  `--global`" pattern — apply here too if Umbriel's startup mechanism allows it)

## What

Mirrors 0002's shape, using 0005's confirmed package names. Noctalia itself needs no
reinstall — it's already on the image for the Niri session — this just adds Umbriel and points
it at the same `noctalia` binary. Terra is enabled **transiently**, matching Tashikk's own
existing precedent (the CLI toolkit's starship/yazi install already does exactly this,
`files/terra.repo` COPYed in and `rm -f`'d in the same layer) — resolves 0005's open question
in favor of the pattern already in the codebase, no new repo left in the shipped image:

```sh
dnf5 -y install --setopt=install_weak_deps=False umbriel-nightly
```

- **Only `umbriel-nightly` needs installing explicitly** — it `Requires:
  xdg-desktop-portal-umbriel-nightly` and `Requires: xwayland-satellite`, so both come along
  automatically (confirmed from the actual spec in 0005, not guessed).
- **`-nightly` is the real package name, not a placeholder** — Terra has no stable Umbriel
  release yet, only git-snapshot builds tracking upstream HEAD. **Decision: track HEAD
  unpinned for now** — every image rebuild picks up whatever Terra has built most recently.
  Revisit pinning (`umbriel-nightly-<version>`) once Umbriel ships a proper beta or 1.0.
- **weak-deps-off on Umbriel**, for the same reason as niri: don't let it pull in a bar/
  launcher/lock Noctalia already provides.
- **Noctalia launched from Umbriel's own config** (`~/.config/umbriel/config.toml` — an
  exec-at-startup-equivalent directive, exact key name TBD from Umbriel's config-reference
  docs), the same way niri's dotfiles use `spawn-at-startup "noctalia-qs" "-c" "noctalia-shell"`
  today. This is a **dotfiles-tashikk** change, not an image one — same split as niri's.
- **Session is systemd-user-unit managed** (`umbriel.service`, `umbriel-session.target`,
  `umbriel-shutdown.target`, per the spec's `%post`/`%preun`/`%postun`), a different startup
  mechanism than niri's bare-compositor-from-GDM approach — confirm on hardware this doesn't
  need anything extra enabled beyond what the package's `%post` already does.

## GDM session entry

**Confirmed shipped**: the package installs `%{_datadir}/wayland-sessions/umbriel.desktop`
(0005). No hand-baked `.desktop` needed — guard its presence the way `niri.desktop` is already
guarded.

## Guard

Implemented as a standalone `RUN` guard (not a rewrite of the existing niri guard, to avoid
touching already-working, already-tested code — a second self-contained check, same idiom the
apps-layer guard already uses further down the `Containerfile`). Three-way check:

- `umbriel-nightly`, `xdg-desktop-portal-umbriel-nightly`, `xwayland-satellite` present (rpm).
- `umbriel` and `start-umbriel` binaries present.
- `wayland-sessions/umbriel.desktop`, `systemd/user/umbriel.service`,
  `xdg-desktop-portal/portals/umbriel.portal`, `xdg-desktop-portal/umbriel-portals.conf` all
  present (the shipped-file list confirmed in 0005).
- `terra.repo` is gone from `/etc/yum.repos.d` (transient-repo-left-behind check).
- **niri re-checked here too** (binary + `niri.desktop` GDM entry) — not just relying on the
  earlier niri guard — so a regression this later layer introduces doesn't slip through.
- GNOME/GDM/plumbing (`gnome-shell`, `gdm`, `xdg-desktop-portal-gnome`, `gnome-keyring`,
  `pipewire`, `wireplumber`, `NetworkManager`) still present.

**Not covered by the guard, deliberately** — can only be proven on hardware, not at build
time: whether `xdg-desktop-portal-gnome` and `xdg-desktop-portal-umbriel` actually coexist
without fighting over the same portal interfaces (screencast in particular). See 0003.

## Verification (hardware — see 0003)

GDM shows **GNOME**, **Niri**, and **Umbriel**. Logging into Umbriel brings up Umbriel +
Noctalia (bar, launcher, notifications). Screencast works. Logging into Niri still works
exactly as before — Umbriel's arrival changed nothing there. GNOME session still works
unchanged.
