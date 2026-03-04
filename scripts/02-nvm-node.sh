#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

ensure_not_root

step "NVM (Node Version Manager) installieren"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    success "NVM bereits installiert: $NVM_DIR"
else
    info "Installiere NVM ..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    success "NVM installiert."
fi

# NVM in aktuelle Shell laden
info "Lade NVM in aktuelle Shell ..."
# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh"

step "Node.js LTS installieren"

if is_installed node; then
    CURRENT_NODE=$(node --version)
    info "Node.js bereits vorhanden: $CURRENT_NODE"
fi

nvm install --lts
nvm alias default 'lts/*'

# Verifizierung
NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
if [[ "$NODE_VERSION" -ge 20 ]]; then
    success "Node.js $(node --version) installiert (>= 20 ✓)"
else
    error "Node.js Version $(node --version) ist zu alt! Mindestens v20 benötigt."
    exit 1
fi

success "02-nvm-node abgeschlossen."
