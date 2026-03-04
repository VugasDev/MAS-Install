#!/usr/bin/env bash
# MAS-Install — Shared Functions
# Wird von allen Installer-Skripten gesourced.

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging-Funktionen
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
step()    { echo -e "\n${BOLD}▶ $*${NC}"; }

# Prüft ob ein Befehl verfügbar ist
is_installed() {
    command -v "$1" &>/dev/null
}

# Bricht ab wenn als root ausgeführt
ensure_not_root() {
    if [[ "$EUID" -eq 0 ]]; then
        error "Bitte NICHT als root ausführen. Das Skript nutzt sudo wo nötig."
        exit 1
    fi
}

# Prüft ob Ubuntu/Debian
require_ubuntu() {
    if [[ ! -f /etc/os-release ]]; then
        error "Kein /etc/os-release gefunden — nur Ubuntu/Debian wird unterstützt."
        exit 1
    fi
    local id
    id=$(. /etc/os-release && echo "$ID")
    if [[ "$id" != "ubuntu" && "$id" != "debian" ]]; then
        warn "Erkanntes OS: $id — Skripte sind für Ubuntu optimiert."
    fi
}

# Prüft ob ein MAS-Install-Marker-Block in einer Datei existiert
marker_exists() {
    local file="$1"
    grep -q '# >>> MAS-Install >>>' "$file" 2>/dev/null
}

# NVM in die aktuelle Shell laden (wird von mehreren Skripten gebraucht)
load_nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # shellcheck source=/dev/null
        source "$NVM_DIR/nvm.sh"
    else
        error "NVM nicht gefunden unter $NVM_DIR/nvm.sh"
        error "Bitte zuerst 02-nvm-node.sh ausführen."
        return 1
    fi
}
