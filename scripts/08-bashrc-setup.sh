#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

ensure_not_root

step "~/.bashrc konfigurieren"

BASHRC="$HOME/.bashrc"
ADDITIONS="$SCRIPT_DIR/../configs/bashrc-additions.sh"

if [[ ! -f "$ADDITIONS" ]]; then
    error "bashrc-additions.sh nicht gefunden: $ADDITIONS"
    exit 1
fi

if marker_exists "$BASHRC"; then
    success "MAS-Install Block bereits in ~/.bashrc vorhanden."
else
    info "Füge MAS-Install Block zu ~/.bashrc hinzu ..."
    echo "" >> "$BASHRC"
    cat "$ADDITIONS" >> "$BASHRC"
    success "MAS-Install Block hinzugefügt."
fi

echo ""
info "Führe 'source ~/.bashrc' aus oder starte eine neue Shell."

success "08-bashrc-setup abgeschlossen."
