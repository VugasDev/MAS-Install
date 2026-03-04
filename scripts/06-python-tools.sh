#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

ensure_not_root
require_ubuntu

step "Python3, pip und pipx installieren"

PACKAGES=(python3 python3-pip python3-venv pipx)

info "Installiere: ${PACKAGES[*]}"
sudo apt install -y -qq "${PACKAGES[@]}"
success "Python-Pakete installiert."

# pipx PATH sicherstellen
info "pipx ensurepath ..."
pipx ensurepath 2>/dev/null || true

step "aider-chat via pipx installieren"

if pipx list 2>/dev/null | grep -q aider-chat; then
    success "aider-chat bereits installiert."
else
    info "Installiere aider-chat ..."
    pipx install aider-chat
    success "aider-chat installiert."
fi

success "06-python-tools abgeschlossen."
