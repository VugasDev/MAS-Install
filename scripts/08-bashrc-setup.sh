#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/config.sh"

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

# ── MCP-spezifische Variablen (nur wenn MCP aktiviert) ──────

FEATURE_MCP=$(config_get "FEATURE_MCP" "false")
MCP_DIR=$(config_get "MCP_DIR" "$HOME/mcp-proxmox")
MCP_DIR="${MCP_DIR/#\~/$HOME}"

if [[ "$FEATURE_MCP" == "true" ]]; then
    step "MCP-Server Aliases und Umgebungsvariablen einrichten"

    MCP_BASHRC_BLOCK="
# >>> MAS-Install MCP >>>
# MCP-Server Konfiguration
export MCP_SERVER_ENABLED=true
export MCP_SERVER_DIR=\"${MCP_DIR}\"

# MCP-Aliases
alias mcp-start='docker compose -f \"\${MCP_SERVER_DIR}/docker/docker-compose.yml\" up -d'
alias mcp-stop='docker compose -f \"\${MCP_SERVER_DIR}/docker/docker-compose.yml\" down'
alias mcp-logs='docker compose -f \"\${MCP_SERVER_DIR}/docker/docker-compose.yml\" logs -f'
alias mcp-status='docker ps --filter name=mcp-proxmox'
# <<< MAS-Install MCP <<<"

    if grep -q '# >>> MAS-Install MCP >>>' "$BASHRC" 2>/dev/null; then
        success "MCP-Block bereits in ~/.bashrc vorhanden."
    else
        echo "$MCP_BASHRC_BLOCK" >> "$BASHRC"
        success "MCP-Aliases und Variablen zu ~/.bashrc hinzugefügt."
        info "  mcp-start  – Server starten"
        info "  mcp-stop   – Server stoppen"
        info "  mcp-logs   – Live-Logs anzeigen"
        info "  mcp-status – Container-Status prüfen"
    fi
else
    info "MCP-Server nicht aktiviert — MCP-Aliases werden nicht hinzugefügt."
fi

echo ""
info "Führe 'source ~/.bashrc' aus oder starte eine neue Shell."

success "08-bashrc-setup abgeschlossen."
