#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

ensure_not_root

step "Gemini CLI installieren"

# NVM laden (braucht Node >= 20)
load_nvm || exit 1

# Node-Version prüfen
NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
if [[ "$NODE_VERSION" -lt 20 ]]; then
    error "Node.js $(node --version) ist zu alt! Gemini CLI braucht mindestens Node >= 20."
    error "Bitte zuerst 02-nvm-node.sh ausführen."
    exit 1
fi
info "Node.js $(node --version) — OK (>= 20)"

if npm list -g @google/gemini-cli &>/dev/null; then
    success "Gemini CLI bereits installiert."
else
    info "Installiere @google/gemini-cli via npm ..."
    npm install -g @google/gemini-cli
    success "Gemini CLI installiert."
fi

echo ""
warn "Nächster Schritt: GEMINI_API_KEY in ~/.bashrc setzen oder 'gemini' starten für OAuth."

success "05-gemini-cli abgeschlossen."
