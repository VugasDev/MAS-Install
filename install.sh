#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ──────────────────────────────────────────────────────────────
# MAS-Install — Multi-Agent System Installer
# ──────────────────────────────────────────────────────────────

VERSION="1.0.0"

MODULES=(
    "01-system-base"
    "02-nvm-node"
    "03-claude-code"
    "04-github-cli"
    "05-gemini-cli"
    "06-python-tools"
    "07-git-config"
    "08-bashrc-setup"
)

# ── CLI Optionen parsen ──────────────────────────────────────

SKIP_MODULES=()
ONLY_MODULES=()
DRY_RUN=false

print_usage() {
    cat <<EOF
MAS-Install v${VERSION} — Multi-Agent System Installer

Verwendung:
    ./install.sh [OPTIONEN]

Optionen:
    --skip MODULE     Modul überspringen (mehrfach verwendbar)
    --only MODULE     Nur dieses Modul ausführen (mehrfach verwendbar)
    --dry-run         Zeigt was installiert würde, führt nichts aus
    --list            Verfügbare Module auflisten
    -h, --help        Diese Hilfe anzeigen

Module:
$(for m in "${MODULES[@]}"; do echo "    $m"; done)

Beispiele:
    ./install.sh                          # Alles installieren
    ./install.sh --skip 05-gemini-cli     # Ohne Gemini CLI
    ./install.sh --only 02-nvm-node       # Nur NVM + Node
    ./install.sh --dry-run                # Trockenlauf
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip)
            SKIP_MODULES+=("$2")
            shift 2
            ;;
        --only)
            ONLY_MODULES+=("$2")
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --list)
            for m in "${MODULES[@]}"; do echo "$m"; done
            exit 0
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            error "Unbekannte Option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# ── Hilfsfunktionen ─────────────────────────────────────────

should_run() {
    local module="$1"

    # --only Mode: nur ausgewählte Module
    if [[ ${#ONLY_MODULES[@]} -gt 0 ]]; then
        for only in "${ONLY_MODULES[@]}"; do
            [[ "$module" == "$only" ]] && return 0
        done
        return 1
    fi

    # --skip Mode: überspringe ausgewählte Module
    for skip in "${SKIP_MODULES[@]}"; do
        [[ "$module" == "$skip" ]] && return 1
    done

    return 0
}

# ── Banner ───────────────────────────────────────────────────

echo -e "${BOLD}"
cat <<'BANNER'

  ╔══════════════════════════════════════════╗
  ║   MAS-Install — Multi-Agent System      ║
  ║   Homelab AI Development Environment    ║
  ╚══════════════════════════════════════════╝

BANNER
echo -e "${NC}"

info "Version: $VERSION"
info "Datum: $(date '+%Y-%m-%d %H:%M:%S')"
info "Benutzer: $USER"
echo ""

# ── Checks ───────────────────────────────────────────────────

ensure_not_root
require_ubuntu

if $DRY_RUN; then
    warn "DRY-RUN Modus — es werden keine Änderungen vorgenommen."
    echo ""
fi

# ── Module ausführen ─────────────────────────────────────────

EXECUTED=()
SKIPPED=()

for module in "${MODULES[@]}"; do
    if should_run "$module"; then
        if $DRY_RUN; then
            info "[DRY-RUN] Würde ausführen: $module"
            EXECUTED+=("$module")
        else
            step "═══ $module ═══"
            if bash "$SCRIPT_DIR/scripts/${module}.sh"; then
                EXECUTED+=("$module")
            else
                error "Modul $module fehlgeschlagen!"
                error "Abbruch. Bereits ausgeführte Module: ${EXECUTED[*]:-keine}"
                exit 1
            fi
        fi
    else
        info "[SKIP] $module"
        SKIPPED+=("$module")
    fi
done

# ── Zusammenfassung ──────────────────────────────────────────

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  Zusammenfassung${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""

if [[ ${#EXECUTED[@]} -gt 0 ]]; then
    success "Ausgeführt: ${EXECUTED[*]}"
fi
if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    info "Übersprungen: ${SKIPPED[*]}"
fi

echo ""
echo -e "${BOLD}  Post-Install Checkliste:${NC}"
echo ""
echo "  1. Shell neu laden:     source ~/.bashrc"
echo "  2. GitHub Auth:         gh auth login"
echo "  3. Claude Auth:         claude (startet Login-Flow)"
echo "  4. Gemini Auth:         gemini (startet OAuth-Flow)"
echo "  5. API-Keys setzen:     ~/.bashrc editieren (auskommentierte Zeilen)"
echo "  6. SSH-Key erstellen:   ssh-keygen -t ed25519"
echo ""
echo -e "${BOLD}  Schema-Dateien:${NC}"
echo "  Die Agent-Definitionen liegen unter: $SCRIPT_DIR/schemas/"
echo "  Kopiere sie nach /home/homelab-ai/ und ersetze die __PLATZHALTER__."
echo ""

success "MAS-Install abgeschlossen!"
