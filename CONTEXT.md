# Mova Development Coordination

This repository coordinates development across multiple repos for the Mova mobile app ecosystem. It does **not** contain detailed documentation for each component - get that context by exploring the repos themselves when working in them.

## Important Reminder

When you `cd` into a component repo (via the symlinks), gather fresh context from that repo's files, tests, and structure. This document is for **coordination and cross-repo workflows only** - component-specific details here may be stale.

## Components at a Glance

| Symlink | What it is | When to touch it |
|---------|------------|------------------|
| `mova` | React Native app (iOS/Android/Web) | UI changes, mobile features |
| `org-agenda-api` | Elisp HTTP API + container | API changes, deployment, backend logic |
| `org-window-habit` | Elisp habit tracking | Habit calculation logic |
| `org-wild-notifier` | Elisp notifications | Notification timing logic |
| `dotfiles` | Nix configs, Emacs setup, deployment scripts | Container config, deployment |

## Dependencies

**mova** depends on org-agenda-api for integration testing. org-agenda-api's container includes mova's web build as its frontend. This creates a circular flake dependency.

**org-agenda-api** loads org-window-habit and org-wild-notifier as elisp dependencies at runtime.

**The container build** (in dotfiles/org-agenda-api/container.nix) combines: the org-agenda-api flake input, tangled elisp from dotfiles/emacs.d/org-config.org, and instance-specific custom-config.el.

## Propagating Changes to Production

Production URL: `https://colonelpanic-org-agenda.fly.dev/`

### Change to org-window-habit or org-wild-notifier

1. Make change in the elisp repo
2. Commit and push
3. Update `dotfiles/nixos/flake.nix` input to new commit
4. Run `./dotfiles/org-agenda-api/deploy.sh colonelpanic`

### Change to org-agenda-api

1. Make change in org-agenda-api repo
2. Commit and push
3. Update `dotfiles/nixos/flake.nix` org-agenda-api input
4. Run `./dotfiles/org-agenda-api/deploy.sh colonelpanic`

### Change to mova

1. Make change in mova repo, commit and push
2. In the org-agenda-api repo: update its flake.nix mova input, bump version, commit and push
3. Update `dotfiles/nixos/flake.nix` org-agenda-api input
4. Run `./dotfiles/org-agenda-api/deploy.sh colonelpanic`

### Change to Emacs/container configuration

1. Edit in `dotfiles/dotfiles/emacs.d/org-config.org` or `dotfiles/org-agenda-api/configs/colonelpanic/custom-config.el`
2. Commit and push dotfiles
3. Run `./dotfiles/org-agenda-api/deploy.sh colonelpanic`

## Container Build Overview

The container is built from `dotfiles/org-agenda-api/container.nix`:

1. **Inputs combined:**
   - org-agenda-api elisp (from flake input)
   - Tangled elisp from `dotfiles/emacs.d/org-config.org`
   - Instance config from `dotfiles/org-agenda-api/configs/<instance>/custom-config.el`
   - Mova web build (bundled in org-agenda-api)

2. **Container contents:**
   - Emacs with simple-httpd (API on port 2025)
   - Nginx (reverse proxy, serves static mova web assets)
   - git-sync-rs (syncs org files from git)
   - supervisord (process management)

3. **Tag format:** `api-{orgApiRev}-cfg-{dotfilesRev}`

4. **Deploy script:** `./dotfiles/org-agenda-api/deploy.sh <instance>`
   - Extracts revisions from flake.lock
   - Builds container via nix
   - Decrypts secrets (git SSH key, auth password) via agenix
   - Pushes to Fly.io registry and deploys

## Deployments

**Fly.io instances:**
- colonelpanic: `https://colonelpanic-org-agenda.fly.dev/` - org files from github.com/colonelpanic8/org
- kat: `https://kat-org-agenda-api.fly.dev/` - org files from dev.railbird.ai gitea

Deploy to Fly.io with: `./dotfiles/org-agenda-api/deploy.sh <instance>`

**Self-hosted (railbird-sf):**
- URL: `https://rbsf.tplinkdns.com/`
- SSH: `ssh rbsf.tplinkdns.com -p 1123`
- Runs as a NixOS service via podman container
- Update by SSHing in and running `sudo nixos-rebuild switch --flake /path/to/dotfiles/nixos`

## Key Paths in dotfiles

- `nixos/flake.nix` - Flake inputs for org-agenda-api and elisp packages
- `org-agenda-api/deploy.sh` - Deployment script
- `org-agenda-api/configs/<instance>/` - Per-instance configs and secrets
- `dotfiles/emacs.d/org-config.org` - Main Emacs config (tangles to elisp)
