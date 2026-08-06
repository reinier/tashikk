# Tashikk — Fedora Silverblue + niri + Noctalia, GNOME kept.
#
# Unlike Steen (which strips a Sway desktop down to niri), Tashikk is ADDITIVE: it keeps
# the full Silverblue GNOME desktop and adds niri + Noctalia as an ALTERNATIVE session you
# pick at GDM. So there is no subtraction layer — Silverblue already ships the plumbing
# (PipeWire, portals incl. xdg-desktop-portal-gnome, polkit, gnome-keyring/gcr,
# NetworkManager, fwupd/fprintd/bolt, cups + the GNOME printer panel, GNOME Software +
# flatpak, fonts). We only layer the niri/Noctalia session and the personal app stack
# carried over from Steen.
#
# Ported from Steen; see that repo's backlog for the reasoning behind each app layer.

# --- keyd: built from source, pinned to an upstream release tag ---
# keyd isn't in Fedora; a pinned source build beats tracking a COPR. Built in a throwaway
# stage so the toolchain (git/make/gcc) never ships — only the artifacts are COPYed in.
# FORCE_SYSTEMD=1: keyd's Makefile only installs keyd.service when /run/systemd exists (or
# this is set); there's no running systemd in a container build.
FROM registry.fedoraproject.org/fedora:44 AS keyd-build
ARG KEYD_VERSION=v2.6.0
RUN dnf5 -y install git make gcc kernel-headers \
 && git clone --depth 1 --branch "$KEYD_VERSION" https://github.com/rvaiya/keyd /src \
 && make -C /src PREFIX=/usr \
 && make -C /src PREFIX=/usr DESTDIR=/out FORCE_SYSTEMD=1 install

# --- wlr-which-key: leader-menu for the niri session, built from source (pinned) ---
# A layer-shell "which-key" popup spawned from a niri keybind (the dank-lader replacement
# lost in the DMS -> Noctalia move). Not in Fedora/Terra, so build the crate in a throwaway
# stage (same keyd pattern) and ship only the binary. Runtime libs (cairo/pango/
# libxkbcommon) are already in the Silverblue base. Config + keybind live in the dotfiles.
FROM registry.fedoraproject.org/fedora:44 AS wlrwhichkey-build
ARG WLR_WHICH_KEY_VERSION=1.3.0
RUN dnf5 -y install cargo gcc pkgconf cairo-devel pango-devel libxkbcommon-devel wayland-devel \
 && cargo install --locked --version "$WLR_WHICH_KEY_VERSION" --root /out wlr-which-key

# Silverblue base — the full GNOME atomic desktop. GNOME stays; GDM stays (it gains a
# "Niri" session entry once niri is installed below).
FROM quay.io/fedora-ostree-desktops/silverblue:44

# --- niri + Noctalia session (added alongside GNOME) ---
# niri Recommends waybar/fuzzel/swaylock/alacritty — install with weak deps OFF so those
# don't come along (Noctalia provides the bar/launcher/lock; GNOME provides the rest).
# niri's *wanted* recommends (gnome-keyring, wireplumber, the portals) are already present
# from Silverblue, so nothing is lost.
#
# Noctalia v5 + matugen come straight from Fedora's official repos (F44+) — no COPR, and
# Noctalia bundles its own Quickshell fork (noctalia-qs), so there's no quickshell
# provenance dance like Steen's DMS. niri has NO built-in Xwayland, so xwayland-satellite
# drives the Xwayland server already present in the base. kitty is the terminal.
# Noctalia is launched from niri's config (dotfiles: spawn-at-startup noctalia-qs), not here.
#
# kanshi: auto-applies output profiles on dock/undock (via wlr-output-management, which niri
# implements). It's the set-and-forget display layer for a laptop. Neither Noctalia nor niri
# ships a display-arrangement GUI — display config is a niri/dotfiles concern; see
# backlog/0004. Enabled per-user from the dotfiles, not here.
# brightnessctl + playerctl: the niri session's brightness/media keybinds (dotfiles) call
# these directly (Noctalia's IPC covers panels, not media/brightness). wpctl comes from
# wireplumber (already in the base). GNOME's own daemons handle these in the GNOME session,
# but not under niri, so name them explicitly.
RUN dnf5 -y install --setopt=install_weak_deps=False \
      niri kitty xwayland-satellite kanshi brightnessctl playerctl \
 && dnf5 -y install noctalia matugen \
 && dnf5 clean all

# Guard: the niri/Noctalia session landed AND GNOME/GDM/plumbing survived (additive build —
# nothing should have been removed). Also assert niri ships its GDM session file so the
# "Niri" entry actually appears at login; if a future niri drops it, fail loudly here so we
# know to bake our own /usr/share/wayland-sessions/niri.desktop.
RUN set -e; \
    rpm -q niri noctalia matugen kitty xwayland-satellite kanshi brightnessctl playerctl >/dev/null; \
    command -v niri >/dev/null    || { echo "ERROR: niri binary missing" >&2; exit 1; }; \
    command -v noctalia >/dev/null || command -v noctalia-qs >/dev/null \
      || { echo "ERROR: noctalia launcher missing" >&2; exit 1; }; \
    test -f /usr/share/wayland-sessions/niri.desktop \
      || { echo "ERROR: niri GDM session file missing — GDM won't offer a Niri session; bake one" >&2; exit 1; }; \
    rpm -q gnome-shell gdm xdg-desktop-portal-gnome gnome-keyring \
           pipewire wireplumber NetworkManager >/dev/null \
      || { echo "ERROR: GNOME/plumbing was disturbed by the niri layer (should be additive)" >&2; exit 1; }; \
    echo "session OK: niri $(rpm -q --qf '%{VERSION}' niri) + noctalia $(rpm -q --qf '%{VERSION}' noctalia); GNOME/GDM intact"

# --- JetBrainsMono Nerd Font ---
# Silverblue ships no Nerd Font (icon glyphs kitty/Noctalia use). Bake the patched font from
# the upstream release — pinned, no Homebrew, no extra repo.
ARG NERD_FONT_VERSION=v3.4.0
RUN curl -fsSL -o /tmp/JetBrainsMono.tar.xz \
      "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/JetBrainsMono.tar.xz" \
 && mkdir -p /usr/share/fonts/jetbrainsmono-nerd \
 && tar -xJf /tmp/JetBrainsMono.tar.xz -C /usr/share/fonts/jetbrainsmono-nerd \
 && rm -f /tmp/JetBrainsMono.tar.xz \
 && fc-cache -f /usr/share/fonts/jetbrainsmono-nerd

# --- Native Chromium + free codecs ---
# Native (non-Flatpak) so 1Password native-messaging works with no wrappers and the
# chrome-* app_ids web-app launchers rely on stay intact. Fedora's chromium links the
# system ffmpeg (H.264/AAC stripped), so libavcodec-freeworld from RPM Fusion free supplies
# those codecs additively. Firefox (Silverblue's default) is left in place — Tashikk is
# additive, not a browser swap.
RUN dnf5 -y install "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
 && dnf5 -y install chromium libavcodec-freeworld \
 && rm -f /etc/yum.repos.d/rpmfusion-*.repo \
 && dnf5 clean all

# --- 1Password: desktop app + CLI ---
# Silverblue is ostree, so /opt is a symlink to /var/opt (which would mask image /opt
# content at runtime). So relocate the payload into /usr/lib/opt, restore the symlink, and
# let tmpfiles.d recreate /opt/1Password at boot. setuid/setgid baked here (/usr is
# read-only at runtime); groups via sysusers.d at FIXED GIDs >=1000 (the RPM's imperative
# groupadd doesn't survive a bootc switch, and 1Password rejects a GID <1000).
COPY files/1password.repo /etc/yum.repos.d/1password.repo
COPY files/1password-sysusers.conf /usr/lib/sysusers.d/1password-tashikk.conf
RUN rpm --import https://downloads.1password.com/linux/keys/1password.asc \
 && systemd-sysusers /usr/lib/sysusers.d/1password-tashikk.conf \
 && opt_link="$(readlink /opt)" \
 && rm /opt && mkdir /opt \
 && mkdir -p "$(realpath -m /usr/local)" \
 && dnf5 -y install 1password 1password-cli \
 && rm -f /etc/yum.repos.d/1password.repo \
 && mkdir -p /usr/lib/opt \
 && mv /opt/1Password /usr/lib/opt/1Password \
 && rmdir /opt \
 && ln -s "$opt_link" /opt \
 && chmod 4755 /usr/lib/opt/1Password/chrome-sandbox \
 && chgrp onepassword /usr/lib/opt/1Password/1Password-BrowserSupport \
 && chmod 2755 /usr/lib/opt/1Password/1Password-BrowserSupport \
 && chgrp onepassword-cli /usr/bin/op \
 && chmod 2755 /usr/bin/op \
 && dnf5 clean all
COPY files/1password-opt.conf /usr/lib/tmpfiles.d/1password-opt.conf
COPY files/60-1password-ptrace.conf /usr/lib/sysctl.d/60-1password-ptrace.conf

# --- CLI toolkit ---
# Silverblue ships none of these. git is explicit (chezmoi's dotfiles bootstrap needs it;
# noctalia also Requires git-core). chezmoi bootstraps the dotfiles. lazygit is deliberately
# NOT baked — it lives in the `apps` distrobox (dotfiles), like Steen.
RUN dnf5 -y install fish eza bat jq zip fuse-sshfs fzf xdg-terminal-exec ripgrep chezmoi git \
 && dnf5 clean all
# Terra only for what Fedora lacks (starship, yazi); added then removed so no third-party
# repo is left enabled in the shipped image.
COPY files/terra.repo /etc/yum.repos.d/terra.repo
RUN dnf5 -y install starship yazi \
 && rm -f /etc/yum.repos.d/terra.repo \
 && dnf5 clean all

# --- Synology Drive ---
# -noextra keeps the Nautilus extension, drops the GNOME-Shell appindicator weak deps.
# Same /opt relocation as 1Password (ostree base).
COPY files/synology-drive.repo /etc/yum.repos.d/synology-drive.repo
RUN opt_link="$(readlink /opt)" \
 && rm /opt && mkdir /opt \
 && dnf5 -y install synology-drive-noextra \
 && rm -f /etc/yum.repos.d/synology-drive.repo \
 && mkdir -p /usr/lib/opt \
 && mv /opt/Synology /usr/lib/opt/Synology \
 && rmdir /opt \
 && ln -s "$opt_link" /opt \
 && dnf5 clean all
COPY files/synology-drive-opt.conf /usr/lib/tmpfiles.d/synology-drive-opt.conf

# --- keyd artifacts ---
# Binary + unit + man pages from the throwaway builder. NOT enabled here; the mapping +
# `systemctl enable keyd` live in the dotfiles.
COPY --from=keyd-build /out/ /

# --- wlr-which-key (leader menu) ---
# Just the binary from the throwaway Rust builder; config + niri keybind live in dotfiles.
COPY --from=wlrwhichkey-build /out/bin/wlr-which-key /usr/bin/wlr-which-key

# --- Tailscale ---
# From Fedora. Enabled at boot so the daemon socket exists and `tailscale set --operator`
# works from the dotfiles; only `tailscale up` is left interactive.
RUN dnf5 -y install tailscale \
 && systemctl enable tailscaled.service \
 && dnf5 clean all

# --- Flathub remote ---
# Via /etc/flatpak/remotes.d so it ships in the image (flatpak remote-add writes to
# machine-local /var). GNOME Software (Silverblue OOTB) is the flatpak store — no Bazaar.
RUN mkdir -p /etc/flatpak/remotes.d \
 && curl -fsSL -o /etc/flatpak/remotes.d/flathub.flatpakrepo \
      https://dl.flathub.org/repo/flathub.flatpakrepo

# --- Dev containers ---
# distrobox is the ad-hoc CLI-tooling path (no Homebrew). Silverblue ships toolbox + podman
# but not distrobox.
RUN dnf5 -y install distrobox \
 && dnf5 clean all

# Guard for the whole app layer. The /opt relocations and setuid bits are the fragile parts:
# a silent failure gives an app that never launches, or a 1Password that fails its own
# integrity check at runtime.
RUN set -e; \
    rpm -q chromium libavcodec-freeworld 1password 1password-cli \
           fish eza bat jq zip fuse-sshfs fzf xdg-terminal-exec ripgrep chezmoi git starship yazi \
           synology-drive-noextra tailscale distrobox >/dev/null; \
    ! command -v lazygit >/dev/null || { echo "ERROR: lazygit is in the image — it belongs in the apps distrobox (dotfiles)" >&2; exit 1; }; \
    test -L /opt || { echo "ERROR: /opt is no longer a symlink — ostree layout broken" >&2; exit 1; }; \
    test -d /usr/lib/opt/1Password || { echo "ERROR: 1Password payload not relocated into /usr" >&2; exit 1; }; \
    test -d /usr/lib/opt/Synology  || { echo "ERROR: Synology payload not relocated into /usr" >&2; exit 1; }; \
    test -u /usr/lib/opt/1Password/chrome-sandbox || { echo "ERROR: chrome-sandbox lost its setuid bit" >&2; exit 1; }; \
    test -g /usr/lib/opt/1Password/1Password-BrowserSupport || { echo "ERROR: 1Password-BrowserSupport lost its setgid bit" >&2; exit 1; }; \
    test -g /usr/bin/op || { echo "ERROR: op lost its setgid bit" >&2; exit 1; }; \
    test -f /usr/lib/sysusers.d/1password-tashikk.conf || { echo "ERROR: 1password sysusers drop-in missing" >&2; exit 1; }; \
    getent group onepassword     | grep -q ':1500:' || { echo "ERROR: onepassword group not at fixed gid 1500 (must be >=1000)" >&2; exit 1; }; \
    getent group onepassword-cli | grep -q ':1501:' || { echo "ERROR: onepassword-cli group not at fixed gid 1501" >&2; exit 1; }; \
    [ "$(stat -c %g /usr/lib/opt/1Password/1Password-BrowserSupport)" = 1500 ] || { echo "ERROR: BrowserSupport setgid not onepassword(1500)" >&2; exit 1; }; \
    [ "$(stat -c %g /usr/bin/op)" = 1501 ] || { echo "ERROR: op setgid not onepassword-cli(1501)" >&2; exit 1; }; \
    test -f /usr/lib/sysctl.d/60-1password-ptrace.conf || { echo "ERROR: ptrace_scope drop-in missing" >&2; exit 1; }; \
    command -v keyd >/dev/null || { echo "ERROR: keyd binary missing" >&2; exit 1; }; \
    command -v wlr-which-key >/dev/null || { echo "ERROR: wlr-which-key binary missing" >&2; exit 1; }; \
    test -f /usr/lib/systemd/system/keyd.service || { echo "ERROR: keyd.service missing — FORCE_SYSTEMD did not take" >&2; exit 1; }; \
    test -s /etc/flatpak/remotes.d/flathub.flatpakrepo || { echo "ERROR: Flathub remote missing" >&2; exit 1; }; \
    systemctl is-enabled tailscaled.service >/dev/null || { echo "ERROR: tailscaled is not enabled" >&2; exit 1; }; \
    echo "apps OK: chromium $(rpm -q --qf '%{VERSION}' chromium), 1password $(rpm -q --qf '%{VERSION}' 1password), synology $(rpm -q --qf '%{VERSION}' synology-drive-noextra), tailscale $(rpm -q --qf '%{VERSION}' tailscale)"

# --- Update policy: manual only ---
# Two manual streams (bootc + flatpak); nothing updates unattended. Mask both OS auto-update
# timers (mask is stronger than disable — symlinked to /dev/null, can't be started).
# rpm-ostree-countme.timer is left alone (privacy-respecting install telemetry, not updates).
RUN systemctl mask bootc-fetch-apply-updates.timer rpm-ostreed-automatic.timer \
 && for t in bootc-fetch-apply-updates.timer rpm-ostreed-automatic.timer; do \
      [ "$(readlink -f "/etc/systemd/system/$t")" = /dev/null ] \
        || { echo "ERROR: $t not masked" >&2; exit 1; }; \
    done \
 && echo "update timers masked: bootc-fetch-apply-updates + rpm-ostreed-automatic"

# --- Image-update trust (backlog/0001) ---
# Tashikk boots this image, so it must verify its own update stream
# (ghcr.io/reinier/tashikk). The Silverblue base ships only Fedora's default container
# policy, so establish the ghcr.io/reinier trust chain from scratch: bake the public key
# and add a sigstoreSigned policy.json entry. The key is SHARED with Steen (same
# SIGNING_SECRET), but signedIdentity=matchRepository binds each signature to its own repo,
# so cross-repo authorization is impossible.
COPY cosign.pub /usr/share/pki/containers/cosign.pub
COPY patch-policy.py /tmp/patch-policy.py
RUN python3 /tmp/patch-policy.py && rm -f /tmp/patch-policy.py

# sigstoreSigned only takes effect if the reader is told to fetch sigstore *attachment*
# signatures for this namespace — otherwise verification looks in the wrong place. Write to
# both the factory template and /etc (whichever the system reads).
COPY files/tashikk-registries.yaml /usr/share/factory/etc/containers/registries.d/tashikk.yaml
RUN mkdir -p /etc/containers/registries.d \
 && cp /usr/share/factory/etc/containers/registries.d/tashikk.yaml \
       /etc/containers/registries.d/tashikk.yaml

# Fail the build on real bootc issues (warnings are fine).
RUN bootc container lint
