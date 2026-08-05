# First-boot checklist — verify on real hardware

- **Status:** open (living document)
- **Created:** 2026-08-05
- **Area:** verification (no image changes)
- **Depends:** everything

CI proves packages resolve and the image lints — not that both sessions come up or 1Password
unlocks. Rebase a test machine and work top-to-bottom; open an item for anything that fails.

```sh
sudo bootc switch ghcr.io/reinier/tashikk:latest && sudo systemctl reboot
```

## A. Both sessions (0000, 0002)

- [ ] GDM login screen offers **GNOME** and **Niri** (session picker / gear icon).
- [ ] **GNOME** session still logs in and works normally (additive build didn't disturb it).
- [ ] **Niri** session logs in → niri + **Noctalia** come up (bar, launcher, notifications).
- [ ] `niri msg version` responds; Noctalia is running (`pgrep -af noctalia`).
- [ ] Noctalia launched by the dotfiles' `spawn-at-startup "noctalia-qs"` (not by the image).
- [ ] **X11 apps run** under niri (`pgrep -af xwayland-satellite`; launch an X11 app).
- [ ] **Screencast** works under niri (Chromium → share screen; uses `xdg-desktop-portal-gnome`).
- [ ] kitty opens; Nerd Font glyphs render (`fc-list | grep -i jetbrainsmono`).
- [ ] **Displays** configured via niri `output` blocks (dotfiles); `niri msg outputs` lists
      them; kanshi re-applies on dock/undock (0004). GNOME session's display panel unaffected.

## B. Apps ported from Steen (already proven on Steen; re-verify on this base)

- [ ] 1Password unlocks, browser integration works, `op` works, 1PUX export opens a dialog
      (the `/opt`-relocation + gid≥1000 + ptrace checks — all identical to Steen).
- [ ] Chromium plays H.264 (`libavcodec-freeworld`); Firefox also still present.
- [ ] Synology Drive syncs; Nautilus emblems show.
- [ ] `tailscale up` joins the tailnet (`tailscaled` enabled).
- [ ] keyd tap-hold works after the dotfiles enable step.
- [ ] CLI toolkit works (fish/starship/eza/bat/yazi/…); `distrobox create` works.
- [ ] Flathub present; GNOME Software installs a Flatpak.

## C. Silverblue plumbing (should be untouched — sanity check)

- [ ] Audio, WiFi/DNS, Bluetooth, printing (GNOME panel), fingerprint, fwupd — all still work
      (inherited from Silverblue; the additive layer shouldn't have touched them).

## D. Updates + trust

- [ ] No OS auto-update timer active (`bootc-fetch-apply-updates` / `rpm-ostreed-automatic`
      masked); updates are manual.
- [ ] `bootc upgrade` → `bootc rollback` both work.
- [ ] **Signing:** currently UNSIGNED (0001) — first rebase is trust-on-first-use. Revisit
      once 0001 lands.

## Findings log

| Date | Check | Result | Follow-up |
|---|---|---|---|
| | | | |
