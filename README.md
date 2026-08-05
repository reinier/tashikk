# Tashikk

Tashikk is a personal Fedora **Silverblue**-based atomic desktop that keeps the full GNOME
desktop and adds **[niri](https://github.com/YaLTeR/niri)** (a scrollable-tiling Wayland
compositor) driven by **[Noctalia](https://noctalia.dev/)** (a Quickshell desktop shell:
bar, launcher, notifications, lock) as an **alternative session** — picked at the login
screen. Log in as GNOME or as Niri; both are there.

**What "atomic" means, in plain terms:** the whole OS is a single image. Updates swap in a
new image; if one breaks, `bootc rollback` returns to the previous one in a single step. Every
machine runs the exact same thing.

Tashikk is *additive* — it layers niri/Noctalia and a personal app set on top of stock
Silverblue, without removing GNOME. It's the counterpart to
[Steen](https://github.com/reinier/steen) (which instead strips a Sway base down to a
niri-only desktop).

> ## 🚧 Work in progress
>
> Early scaffolding. The image builds and is **signed** (verified update stream — see
> [`backlog/0001`](backlog/0001-signing.md)); it hasn't been hardware-verified yet. Personal
> project, no support.

## Install

Start from a [Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/)
install, then rebase onto Tashikk:

```sh
sudo bootc switch ghcr.io/reinier/tashikk:latest
sudo systemctl reboot
```

At the GDM login screen, use the session picker (gear icon) to choose **GNOME** or **Niri**.

## What you get

On top of everything Silverblue already provides (GNOME, GDM, GNOME Software, PipeWire,
printing, firmware updates, keyring):

- **Second desktop** — niri + Noctalia (kitty terminal, xwayland-satellite for X11 apps).
- **Browser** — Chromium with full media codecs (Firefox stays too).
- **Apps** — 1Password (+ CLI), Synology Drive, Tailscale.
- **Input** — keyd (for tap-hold key remaps; enabled via your dotfiles).
- **Terminal toolkit** — fish, starship, eza, bat, yazi, and friends; distrobox for ad-hoc
  tooling.

## Updating

Two manual streams, nothing unattended:

```sh
sudo bootc upgrade     # the OS image
flatpak update         # your apps
```

`sudo bootc rollback` returns to the previous image.

## Configuration

Tashikk provides the desktop and apps, not a personal setup. Bring your own dotfiles — niri
keybinds (including the `spawn-at-startup noctalia-qs` that launches Noctalia), Noctalia
config, shell config, keyd remaps.

## Notes

Personal project, not an official Fedora product. niri and Noctalia are independent upstream
projects. Named for a region of Roshar.
