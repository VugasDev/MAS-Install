#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

ensure_not_root

step "Claude Code CLI installieren"

if is_installed claude; then
    success "Claude Code bereits installiert: $(claude --version 2>/dev/null || echo 'Version unbekannt')"
else
    info "Installiere Claude Code via offiziellem Installer ..."
    curl -fsSL https://claude.ai/install.sh | sh
    success "Claude Code installiert."
fi

# Settings-Template kopieren
step "Claude Settings konfigurieren"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

if [[ -f "$SETTINGS_FILE" ]]; then
    success "Claude Settings existieren bereits: $SETTINGS_FILE"
else
    info "Kopiere Template nach $SETTINGS_FILE ..."
    mkdir -p "$CLAUDE_DIR"
    cp "$SCRIPT_DIR/../configs/claude-settings.json" "$SETTINGS_FILE"
    success "Claude Settings installiert."
fi

echo ""
warn "Naechster Schritt: 'claude' starten und mit Anthropic-Account authentifizieren."

success "03-claude-code abgeschlossen."
