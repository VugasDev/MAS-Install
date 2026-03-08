#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/config.sh"

ensure_not_root
require_ubuntu

step "Docker Engine installieren (WSL2)"

# ── WSL-Umgebung erkennen ────────────────────────────────────

is_wsl() {
    grep -qi "microsoft\|wsl" /proc/version 2>/dev/null || \
    [[ -n "${WSL_DISTRO_NAME:-}" ]]
}

if is_wsl; then
    info "WSL2-Umgebung erkannt."
else
    warn "Keine WSL2-Umgebung erkannt. Docker Engine wird trotzdem installiert."
fi

# ── Docker bereits installiert? ──────────────────────────────

if is_installed docker; then
    DOCKER_VERSION=$(docker --version 2>/dev/null || echo "unbekannt")
    success "Docker bereits installiert: $DOCKER_VERSION"
else
    info "Installiere Docker Engine via offizielles apt-Repository..."

    # Alte Versionen entfernen
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y "$pkg" 2>/dev/null || true
    done

    # Abhängigkeiten
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg

    # Docker GPG-Key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Docker apt-Repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    success "Docker Engine installiert."
fi

# ── User zur docker-Gruppe hinzufügen ────────────────────────

if groups "$USER" | grep -q docker; then
    success "User '$USER' ist bereits in der docker-Gruppe."
else
    info "Füge '$USER' zur docker-Gruppe hinzu..."
    sudo usermod -aG docker "$USER"
    success "User zur docker-Gruppe hinzugefügt. (Neustart der Shell erforderlich)"
fi

# ── Docker-Daemon starten ────────────────────────────────────

step "Docker-Daemon starten"

# In WSL2 kein systemd verfügbar (außer mit systemd-WSL)
if is_wsl; then
    # Prüfe ob systemd läuft
    if systemctl is-active --quiet docker 2>/dev/null; then
        success "Docker-Daemon läuft bereits (systemd)."
    else
        # Direktstart ohne systemd
        if ! pgrep -x "dockerd" > /dev/null 2>&1; then
            info "Starte Docker-Daemon direkt..."
            sudo dockerd > /tmp/dockerd.log 2>&1 &
            sleep 3

            if pgrep -x "dockerd" > /dev/null 2>&1; then
                success "Docker-Daemon gestartet."
            else
                warn "Docker-Daemon konnte nicht gestartet werden."
                warn "Starte manuell: sudo dockerd &"
                warn "Oder aktiviere systemd in /etc/wsl.conf:"
                warn "  [boot]"
                warn "  systemd=true"
            fi
        else
            success "Docker-Daemon läuft bereits."
        fi
    fi
else
    # Systemd-basiertes System
    sudo systemctl enable docker
    sudo systemctl start docker
    success "Docker-Daemon per systemd gestartet."
fi

# ── Verifikation ─────────────────────────────────────────────

step "Docker-Installation verifizieren"

# Gruppen-Kontext für docker-Befehle
if sg docker -c "docker info" > /dev/null 2>&1; then
    success "Docker funktioniert korrekt."
    sg docker -c "docker --version"
    sg docker -c "docker compose version"
elif sudo docker info > /dev/null 2>&1; then
    warn "Docker funktioniert nur mit sudo (Gruppe noch nicht aktiv — Shell neu starten)."
    sudo docker --version
else
    warn "Docker-Verifikation fehlgeschlagen. Prüfe manuell: docker info"
fi

success "09-docker-setup abgeschlossen."
