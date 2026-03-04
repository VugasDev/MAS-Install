#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

ensure_not_root

step "Git-Konfiguration"

# Name
CURRENT_NAME=$(git config --global user.name 2>/dev/null || true)
if [[ -z "$CURRENT_NAME" ]]; then
    read -rp "Git Name (Vor- und Nachname): " GIT_NAME
    git config --global user.name "$GIT_NAME"
    success "Git Name gesetzt: $GIT_NAME"
else
    success "Git Name bereits gesetzt: $CURRENT_NAME"
fi

# E-Mail
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || true)
if [[ -z "$CURRENT_EMAIL" ]]; then
    read -rp "Git E-Mail: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
    success "Git E-Mail gesetzt: $GIT_EMAIL"
else
    success "Git E-Mail bereits gesetzt: $CURRENT_EMAIL"
fi

# Default Branch
CURRENT_BRANCH=$(git config --global init.defaultBranch 2>/dev/null || true)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    git config --global init.defaultBranch main
    success "Default Branch auf 'main' gesetzt."
else
    success "Default Branch bereits 'main'."
fi

# Credential Helper für GitHub CLI
if is_installed gh; then
    git config --global credential.helper '!gh auth git-credential'
    success "Git Credential Helper auf GitHub CLI gesetzt."
else
    warn "GitHub CLI (gh) nicht installiert — Credential Helper übersprungen."
    warn "Nach Installation von gh: git config --global credential.helper '!gh auth git-credential'"
fi

success "07-git-config abgeschlossen."
