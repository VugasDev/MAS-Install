#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/config.sh"

ensure_not_root

step "Installations-Cleanup"

# ── Konfiguration laden ──────────────────────────────────────

INSTALL_DIR=$(config_get "INSTALL_DIR" "$SCRIPT_DIR/..")
INSTALL_DIR="$(cd "$INSTALL_DIR" && pwd)"  # absoluten Pfad normalisieren

HOMELAB_AI_DIR=$(config_get "HOMELAB_AI_DIR" "$HOME/homelab-ai")
HOMELAB_AI_DIR="${HOMELAB_AI_DIR/#\~/$HOME}"

info "Install-Dir    : $INSTALL_DIR"
info "homelab-ai Dir : $HOMELAB_AI_DIR"

# ── Cleanup-Strategie bestimmen ──────────────────────────────

if [[ "$INSTALL_DIR" != "$HOMELAB_AI_DIR" ]]; then
    # Repo liegt an anderem Ort → komplett löschen
    step "Geklontes Repo entfernen"
    info "INSTALL_DIR != HOMELAB_AI_DIR — entferne $INSTALL_DIR komplett"

    # Sicherheitscheck: Nicht Home-Verzeichnis löschen
    if [[ "$INSTALL_DIR" == "$HOME" || "$INSTALL_DIR" == "/" ]]; then
        warn "Sicherheitscheck: Würde Home/Root löschen — überspringe Cleanup."
    else
        rm -rf "$INSTALL_DIR"
        success "Repo entfernt: $INSTALL_DIR"
    fi

else
    # Repo ist das homelab-ai Verzeichnis selbst → nur Installer-Dateien löschen
    step "Installer-Dateien aus homelab-ai entfernen"
    info "INSTALL_DIR == HOMELAB_AI_DIR — entferne nur Installer-Komponenten"

    # install.sh entfernen
    if [[ -f "$INSTALL_DIR/install.sh" ]]; then
        rm -f "$INSTALL_DIR/install.sh"
        success "install.sh entfernt."
    fi

    # scripts/ Verzeichnis entfernen
    if [[ -d "$INSTALL_DIR/scripts" ]]; then
        rm -rf "$INSTALL_DIR/scripts"
        success "scripts/ entfernt."
    fi

    # lib/ Verzeichnis entfernen
    if [[ -d "$INSTALL_DIR/lib" ]]; then
        rm -rf "$INSTALL_DIR/lib"
        success "lib/ entfernt."
    fi

    # configs/ Verzeichnis entfernen
    if [[ -d "$INSTALL_DIR/configs" ]]; then
        rm -rf "$INSTALL_DIR/configs"
        success "configs/ entfernt."
    fi

    # schemas/ wird behalten (Agent-Definitionen)
    if [[ -d "$INSTALL_DIR/schemas" ]]; then
        info "schemas/ wird behalten (Agent-Definitionen)."
    fi
fi

# ── Config-Datei löschen ─────────────────────────────────────

step "Temporäre Config-Datei löschen"

if [[ -f "$CONFIG_FILE" ]]; then
    rm -f "$CONFIG_FILE"
    success "Config-Datei gelöscht: $CONFIG_FILE"
else
    info "Config-Datei nicht vorhanden (bereits gelöscht oder nie erstellt)."
fi

# ── Abschlussmeldung ─────────────────────────────────────────

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  MAS-Install erfolgreich abgeschlossen!${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo "  Deine Homelab AI Umgebung ist bereit."
echo ""
echo -e "  ${BOLD}Nächste Schritte:${NC}"
echo ""
echo "  1.  Shell neu laden:"
echo "        source ~/.bashrc"
echo ""
echo "  2.  Authentifizierung:"
echo "        claude          (Claude Code Login)"
echo "        gh auth login   (GitHub CLI)"
echo "        gemini          (Gemini OAuth, falls installiert)"
echo ""
echo "  3.  API-Keys (optional):"
echo "        nano ~/.bashrc"
echo "        # ANTHROPIC_API_KEY, GEMINI_API_KEY auskommentieren"
echo ""
echo "  4.  SSH-Key erstellen:"
echo "        ssh-keygen -t ed25519 -C 'deine@email.de'"
echo "        ssh-add ~/.ssh/id_ed25519"
echo ""
if [[ -d "$HOMELAB_AI_DIR" ]]; then
echo "  5.  homelab-ai Verzeichnis:"
echo "        cd $HOMELAB_AI_DIR"
echo "        # CLAUDE.md Platzhalter anpassen"
echo ""
fi
echo -e "  ${GREEN}Viel Erfolg!${NC}"
echo ""

success "99-cleanup abgeschlossen."
