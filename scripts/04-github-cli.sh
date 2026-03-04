#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

ensure_not_root
require_ubuntu

step "GitHub CLI (gh) installieren"

if is_installed gh; then
    success "GitHub CLI bereits installiert: $(gh --version | head -1)"
else
    info "Füge GitHub CLI apt-Repository hinzu ..."

    # GPG Key
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

    # Repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    sudo apt update -qq
    sudo apt install -y -qq gh
    success "GitHub CLI installiert: $(gh --version | head -1)"
fi

echo ""
warn "Nächster Schritt: 'gh auth login' ausführen und mit GitHub authentifizieren."

success "04-github-cli abgeschlossen."
