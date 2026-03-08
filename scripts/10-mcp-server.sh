#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/config.sh"

ensure_not_root

step "MCP-Proxmox Server aufsetzen"

# ── Konfiguration laden ──────────────────────────────────────

PROXMOX_HOST=$(config_get "PROXMOX_HOST" "192.168.0.191:8006")
PROXMOX_USER=$(config_get "PROXMOX_USER" "root@pam")
PROXMOX_TOKEN_NAME=$(config_get "PROXMOX_TOKEN_NAME" "claude")
PROXMOX_TOKEN_VALUE=$(config_get "PROXMOX_TOKEN_VALUE" "")
PROXMOX_VERIFY_SSL=$(config_get "PROXMOX_VERIFY_SSL" "false")
MCP_DIR=$(config_get "MCP_DIR" "$HOME/mcp-proxmox")

# Expand tilde
MCP_DIR="${MCP_DIR/#\~/$HOME}"

info "Proxmox Host     : $PROXMOX_HOST"
info "Proxmox User     : $PROXMOX_USER"
info "Proxmox Token    : $PROXMOX_TOKEN_NAME"
info "SSL Verify       : $PROXMOX_VERIFY_SSL"
info "MCP Verzeichnis  : $MCP_DIR"

if [[ -z "$PROXMOX_TOKEN_VALUE" ]]; then
    warn "PROXMOX_TOKEN_VALUE ist leer."
    read -rsp "  Proxmox API Token-Wert eingeben: " PROXMOX_TOKEN_VALUE
    echo ""
    config_set "PROXMOX_TOKEN_VALUE" "$PROXMOX_TOKEN_VALUE"
fi

# ── Docker prüfen ────────────────────────────────────────────

if ! is_installed docker; then
    error "Docker ist nicht installiert. Bitte zuerst 09-docker-setup.sh ausführen."
    exit 1
fi

# Docker-Zugriff (mit oder ohne sudo)
DOCKER_CMD="docker"
if ! docker info > /dev/null 2>&1; then
    if sudo docker info > /dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
        warn "Docker nur mit sudo erreichbar (Gruppe noch nicht aktiv)."
    else
        error "Docker nicht erreichbar. Prüfe: docker info"
        exit 1
    fi
fi

# ── Repo klonen oder aktualisieren ──────────────────────────

step "mcp-proxmox Repository"

REPO_URL="https://github.com/VugasDev/mcp-proxmox.git"

if [[ -d "$MCP_DIR/.git" ]]; then
    info "mcp-proxmox bereits vorhanden. Aktualisiere..."
    git -C "$MCP_DIR" pull --ff-only || warn "Git pull fehlgeschlagen — fahre mit vorhandenem Stand fort."
    success "Repository aktualisiert: $MCP_DIR"
else
    info "Klone $REPO_URL nach $MCP_DIR ..."
    git clone "$REPO_URL" "$MCP_DIR"
    success "Repository geklont."
fi

# ── .env-Datei erstellen ─────────────────────────────────────

step ".env-Datei erstellen"

ENV_FILE="$MCP_DIR/.env"

cat > "$ENV_FILE" <<EOF
# Automatisch generiert von MAS-Install — $(date '+%Y-%m-%d %H:%M:%S')
PROXMOX_HOST=${PROXMOX_HOST}
PROXMOX_USER=${PROXMOX_USER}
PROXMOX_TOKEN_NAME=${PROXMOX_TOKEN_NAME}
PROXMOX_TOKEN_VALUE=${PROXMOX_TOKEN_VALUE}
PROXMOX_VERIFY_SSL=${PROXMOX_VERIFY_SSL}
EOF

chmod 600 "$ENV_FILE"
success ".env-Datei erstellt: $ENV_FILE"

# ── Docker-Image bauen ───────────────────────────────────────

step "Docker-Image bauen"

COMPOSE_FILE="$MCP_DIR/docker/docker-compose.yml"

if [[ ! -f "$COMPOSE_FILE" ]]; then
    error "docker-compose.yml nicht gefunden: $COMPOSE_FILE"
    exit 1
fi

info "Baue Docker-Image..."
$DOCKER_CMD compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build
success "Docker-Image gebaut."

# ── Container starten ────────────────────────────────────────

step "MCP-Server Container starten"

info "Starte Container..."
$DOCKER_CMD compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d
success "Container gestartet."

# ── Verifikation ─────────────────────────────────────────────

step "MCP-Server verifizieren"

sleep 2

if $DOCKER_CMD ps --format '{{.Names}}' | grep -q '^mcp-proxmox$'; then
    success "Container 'mcp-proxmox' läuft."
    $DOCKER_CMD ps --filter "name=mcp-proxmox" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
else
    # Prüfe ob Container mit anderem Namen läuft
    RUNNING=$($DOCKER_CMD compose -f "$COMPOSE_FILE" ps --status running --format json 2>/dev/null || echo "")
    if [[ -n "$RUNNING" ]]; then
        success "MCP-Server Container läuft."
    else
        warn "Container scheint nicht zu laufen. Prüfe Logs:"
        $DOCKER_CMD compose -f "$COMPOSE_FILE" logs --tail=20 || true
        warn "Manuell prüfen: docker compose -f $COMPOSE_FILE ps"
    fi
fi

# Config speichern für andere Skripte
config_set "MCP_DIR" "$MCP_DIR"
config_set "MCP_COMPOSE_FILE" "$COMPOSE_FILE"

success "10-mcp-server abgeschlossen."
