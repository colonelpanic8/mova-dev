#!/usr/bin/env bash
set -euo pipefail

# Mova-dev repository setup script
# Creates symlinks to component repositories for local development

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up mova-dev symlinks..."
echo ""

# Function to create symlink with user prompt
create_symlink() {
    local name="$1"
    local default_path="$2"
    local description="$3"

    local target_link="$SCRIPT_DIR/$name"

    if [[ -L "$target_link" ]]; then
        local existing_target
        existing_target=$(readlink "$target_link")
        echo "✓ $name already linked to: $existing_target"
        return 0
    elif [[ -e "$target_link" ]]; then
        echo "⚠ $name exists but is not a symlink. Skipping."
        return 1
    fi

    echo "$description"
    read -r -p "Path to $name [$default_path]: " user_path
    local repo_path="${user_path:-$default_path}"

    # Expand ~
    repo_path="${repo_path/#\~/$HOME}"

    if [[ ! -d "$repo_path" ]]; then
        echo "⚠ Directory not found: $repo_path"
        read -r -p "Create symlink anyway? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Skipping $name"
            return 1
        fi
    fi

    ln -s "$repo_path" "$target_link"
    echo "✓ Created symlink: $name -> $repo_path"
    echo ""
}

echo "This script will create symlinks to your local copies of the component repositories."
echo "Press Enter to accept the default path, or type a custom path."
echo ""

# Mova mobile app
create_symlink "mova" \
    "$HOME/Projects/mova" \
    "Mova: React Native mobile app for org-mode"

# org-agenda-api
create_symlink "org-agenda-api" \
    "$HOME/dotfiles/dotfiles/emacs.d/straight/repos/org-agenda-api" \
    "org-agenda-api: HTTP API for org-mode data"

# org-window-habit
create_symlink "org-window-habit" \
    "$HOME/dotfiles/dotfiles/emacs.d/straight/repos/org-window-habit" \
    "org-window-habit: Advanced habit tracking"

# org-wild-notifier
create_symlink "org-wild-notifier" \
    "$HOME/dotfiles/dotfiles/emacs.d/straight/repos/org-wild-notifier.el" \
    "org-wild-notifier: Desktop notifications for org events"

# dotfiles
create_symlink "dotfiles" \
    "$HOME/dotfiles" \
    "dotfiles: Nix configs, deployment, Emacs setup"

echo ""
echo "Setup complete! Current symlinks:"
echo ""
for link in mova org-agenda-api org-window-habit org-wild-notifier dotfiles; do
    if [[ -L "$SCRIPT_DIR/$link" ]]; then
        target=$(readlink "$SCRIPT_DIR/$link")
        echo "  $link -> $target"
    fi
done
echo ""
echo "See CONTEXT.md for an overview of how these components work together."
