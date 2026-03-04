#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

ensure_not_root
require_ubuntu

step "System-Basispakete installieren"

PACKAGES=(
    build-essential
    curl
    wget
    git
    jq
    unzip
    ca-certificates
    gnupg
    rsync
    openssh-client
)

info "apt update & upgrade ..."
sudo apt update -qq
sudo apt upgrade -y -qq

info "Installiere Pakete: ${PACKAGES[*]}"
sudo apt install -y -qq "${PACKAGES[@]}"
success "Basispakete installiert."

# Sudoers NOPASSWD
step "Sudoers NOPASSWD konfigurieren"
SUDOERS_FILE="/etc/sudoers.d/$USER"
if [[ -f "$SUDOERS_FILE" ]]; then
    success "Sudoers-Datei existiert bereits: $SUDOERS_FILE"
else
    info "Erstelle $SUDOERS_FILE ..."
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 0440 "$SUDOERS_FILE"
    success "NOPASSWD für $USER konfiguriert."
fi

success "01-system-base abgeschlossen."
