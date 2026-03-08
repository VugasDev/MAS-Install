#!/usr/bin/env bash
# MAS-Install — Interaktiver Setup-Wizard
# Reines Bash, kein dialog/whiptail erforderlich.
# Wird von install.sh gesourced.

# ── Hilfsfunktionen für den Wizard ──────────────────────────────────────────

_wizard_banner() {
    echo -e "${BOLD}"
    cat <<'BANNER'

  ╔══════════════════════════════════════════╗
  ║   MAS-Install — Multi-Agent System      ║
  ║   Homelab AI Development Environment    ║
  ╚══════════════════════════════════════════╝

BANNER
    echo -e "${NC}"
}

# Mehrfachauswahl: User tippt Nummern getrennt durch Leerzeichen, "all" oder "none"
# Gibt gewählte Indizes (1-basiert) als Space-separierte Liste zurück (in $_WIZARD_SELECTION)
_wizard_multiselect() {
    local prompt="$1"
    shift
    local -a options=("$@")
    local count=${#options[@]}

    echo ""
    echo -e "${BOLD}${prompt}${NC}"
    echo "  (Nummern eingeben, z.B. '1 3', oder 'all' / 'none')"
    echo ""

    local i=1
    for opt in "${options[@]}"; do
        echo "  [$i] $opt"
        ((i++))
    done
    echo ""

    local input
    read -rp "  Auswahl: " input
    input="${input,,}"  # lowercase

    _WIZARD_SELECTION=""

    if [[ "$input" == "all" ]]; then
        for ((i=1; i<=count; i++)); do
            _WIZARD_SELECTION="$_WIZARD_SELECTION $i"
        done
    elif [[ "$input" == "none" || -z "$input" ]]; then
        _WIZARD_SELECTION=""
    else
        # Validiere und sammle die Nummern
        for num in $input; do
            if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= count )); then
                _WIZARD_SELECTION="$_WIZARD_SELECTION $num"
            else
                warn "Ungültige Auswahl '$num' ignoriert."
            fi
        done
    fi

    _WIZARD_SELECTION="${_WIZARD_SELECTION# }"  # führendes Leerzeichen entfernen
}

# Prüft ob eine Nummer in der Selektion enthalten ist
_wizard_selected() {
    local num="$1"
    [[ " $_WIZARD_SELECTION " == *" $num "* ]]
}

# Fragt nach einem Wert mit Default
_wizard_ask() {
    local key="$1"
    local prompt="$2"
    local default="$3"
    local secret="${4:-false}"

    local display_default=""
    [[ -n "$default" ]] && display_default=" [${default}]"

    local value
    if [[ "$secret" == "true" ]]; then
        read -rsp "  ${prompt}${display_default}: " value
        echo ""
    else
        read -rp "  ${prompt}${display_default}: " value
    fi

    [[ -z "$value" ]] && value="$default"
    config_set "$key" "$value"
}

# ── Wizard-Hauptfunktion ─────────────────────────────────────────────────────

wizard_run() {
    _wizard_banner

    echo -e "${BOLD}  Setup-Wizard${NC}"
    echo "  Konfiguriere deine Homelab AI Umgebung."
    echo "  Du kannst jederzeit Enter drücken um den Default-Wert zu übernehmen."
    echo ""

    # Installationsverzeichnis in Config speichern
    config_set "INSTALL_DIR" "$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"

    # ────────────────────────────────────────────────────
    # Schritt 1: CLI-Tools auswählen
    # ────────────────────────────────────────────────────
    _wizard_multiselect \
        "Schritt 1/4 — CLI-Tools (welche KI-Assistenten installieren?)" \
        "Claude Code" \
        "Gemini CLI" \
        "Aider (Python)"

    local CLI_SEL="$_WIZARD_SELECTION"

    local CLI_CLAUDE=false CLI_GEMINI=false CLI_AIDER=false
    _WIZARD_SELECTION="$CLI_SEL"
    _wizard_selected 1 && CLI_CLAUDE=true
    _wizard_selected 2 && CLI_GEMINI=true
    _wizard_selected 3 && CLI_AIDER=true

    config_set "CLI_CLAUDE" "$CLI_CLAUDE"
    config_set "CLI_GEMINI" "$CLI_GEMINI"
    config_set "CLI_AIDER"  "$CLI_AIDER"

    # ────────────────────────────────────────────────────
    # Schritt 2: Features aktivieren
    # ────────────────────────────────────────────────────
    _wizard_multiselect \
        "Schritt 2/4 — Features (was soll eingerichtet werden?)" \
        "GitHub CLI" \
        "Python-Tools (pip, pipx)" \
        "Git-Konfiguration" \
        "Docker (für WSL2)" \
        "MCP-Server (mcp-proxmox via Docker)" \
        "Agenten deployen"

    local FEAT_SEL="$_WIZARD_SELECTION"

    local FEATURE_GITHUB=false FEATURE_PYTHON=false FEATURE_GIT=false
    local FEATURE_DOCKER=false FEATURE_MCP=false FEATURE_AGENTS=false
    _WIZARD_SELECTION="$FEAT_SEL"
    _wizard_selected 1 && FEATURE_GITHUB=true
    _wizard_selected 2 && FEATURE_PYTHON=true
    _wizard_selected 3 && FEATURE_GIT=true
    _wizard_selected 4 && FEATURE_DOCKER=true
    _wizard_selected 5 && FEATURE_MCP=true
    _wizard_selected 6 && FEATURE_AGENTS=true

    config_set "FEATURE_GITHUB"  "$FEATURE_GITHUB"
    config_set "FEATURE_PYTHON"  "$FEATURE_PYTHON"
    config_set "FEATURE_GIT"     "$FEATURE_GIT"
    config_set "FEATURE_DOCKER"  "$FEATURE_DOCKER"
    config_set "FEATURE_MCP"     "$FEATURE_MCP"
    config_set "FEATURE_AGENTS"  "$FEATURE_AGENTS"

    # MCP braucht Docker
    if [[ "$FEATURE_MCP" == "true" && "$FEATURE_DOCKER" == "false" ]]; then
        warn "MCP-Server erfordert Docker. Docker wird automatisch aktiviert."
        FEATURE_DOCKER=true
        config_set "FEATURE_DOCKER" "true"
    fi

    # ────────────────────────────────────────────────────
    # Schritt 3: Konfigurationsabfragen
    # ────────────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}Schritt 3/4 — Konfiguration${NC}"
    echo ""

    # Allgemein
    _wizard_ask "PROJECT_DIR"    "Projektverzeichnis"       "$HOME/projects"
    _wizard_ask "HOMELAB_AI_DIR" "homelab-ai Verzeichnis"   "$HOME/homelab-ai"

    # Git
    if [[ "$FEATURE_GIT" == "true" ]]; then
        echo ""
        echo -e "  ${BLUE}[Git-Konfiguration]${NC}"
        _wizard_ask "GIT_NAME"  "Git Name"   ""
        _wizard_ask "GIT_EMAIL" "Git E-Mail" ""
    fi

    # GitHub
    if [[ "$FEATURE_GITHUB" == "true" ]]; then
        echo ""
        echo -e "  ${BLUE}[GitHub]${NC}"
        _wizard_ask "GITHUB_USER" "GitHub-Benutzername" ""
    fi

    # MCP-Server
    if [[ "$FEATURE_MCP" == "true" ]]; then
        echo ""
        echo -e "  ${BLUE}[MCP-Server / Proxmox]${NC}"
        _wizard_ask "PROXMOX_HOST"        "Proxmox IP:Port"    "192.168.0.191:8006"
        _wizard_ask "PROXMOX_USER"        "Proxmox User"       "root@pam"
        _wizard_ask "PROXMOX_TOKEN_NAME"  "Proxmox Token-Name" "claude"
        _wizard_ask "PROXMOX_TOKEN_VALUE" "Proxmox Token-Wert" "" "true"
        _wizard_ask "PROXMOX_VERIFY_SSL"  "SSL verifizieren"   "false"
        _wizard_ask "MCP_DIR"             "MCP-Server Verzeichnis" "$HOME/mcp-proxmox"
    fi

    # ────────────────────────────────────────────────────
    # Schritt 4: Zusammenfassung
    # ────────────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════${NC}"
    echo -e "${BOLD}Schritt 4/4 — Zusammenfassung${NC}"
    echo -e "${BOLD}══════════════════════════════════════════${NC}"
    echo ""

    echo -e "  ${BOLD}CLI-Tools:${NC}"
    echo "    Claude Code : $CLI_CLAUDE"
    echo "    Gemini CLI  : $CLI_GEMINI"
    echo "    Aider       : $CLI_AIDER"
    echo ""
    echo -e "  ${BOLD}Features:${NC}"
    echo "    GitHub CLI  : $FEATURE_GITHUB"
    echo "    Python-Tools: $FEATURE_PYTHON"
    echo "    Git-Konfig  : $FEATURE_GIT"
    echo "    Docker      : $FEATURE_DOCKER"
    echo "    MCP-Server  : $FEATURE_MCP"
    echo "    Agenten     : $FEATURE_AGENTS"
    echo ""
    echo -e "  ${BOLD}Verzeichnisse:${NC}"
    echo "    Projekte    : $(config_get PROJECT_DIR)"
    echo "    homelab-ai  : $(config_get HOMELAB_AI_DIR)"

    if [[ "$FEATURE_GIT" == "true" ]]; then
        echo ""
        echo -e "  ${BOLD}Git:${NC}"
        echo "    Name  : $(config_get GIT_NAME)"
        echo "    E-Mail: $(config_get GIT_EMAIL)"
    fi

    if [[ "$FEATURE_MCP" == "true" ]]; then
        echo ""
        echo -e "  ${BOLD}Proxmox:${NC}"
        echo "    Host      : $(config_get PROXMOX_HOST)"
        echo "    User      : $(config_get PROXMOX_USER)"
        echo "    Token     : $(config_get PROXMOX_TOKEN_NAME)"
        echo "    SSL-Verify: $(config_get PROXMOX_VERIFY_SSL)"
        echo "    MCP-Dir   : $(config_get MCP_DIR)"
    fi

    echo ""
    local confirm
    read -rp "  Jetzt installieren? [j/N]: " confirm
    confirm="${confirm,,}"

    if [[ "$confirm" != "j" && "$confirm" != "ja" && "$confirm" != "y" && "$confirm" != "yes" ]]; then
        echo ""
        warn "Installation abgebrochen."
        exit 0
    fi

    echo ""
    success "Starte Installation ..."
    echo ""
}
