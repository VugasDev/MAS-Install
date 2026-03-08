#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/config.sh"

ensure_not_root

step "Agenten-Struktur deployen"

# ── Konfiguration laden ──────────────────────────────────────

HOMELAB_AI_DIR=$(config_get "HOMELAB_AI_DIR" "$HOME/homelab-ai")
HOMELAB_AI_DIR="${HOMELAB_AI_DIR/#\~/$HOME}"

FEATURE_GITHUB=$(config_get "FEATURE_GITHUB" "false")
FEATURE_MCP=$(config_get "FEATURE_MCP" "false")
FEATURE_GIT=$(config_get "FEATURE_GIT" "false")
GIT_USER=$(config_get "GITHUB_USER" "")

PROXMOX_HOST=$(config_get "PROXMOX_HOST" "192.168.0.191:8006")
PROXMOX_IP="${PROXMOX_HOST%%:*}"  # IP ohne Port
CC_IP=$(config_get "CC_IP" "192.168.0.x")
SSH_USER=$(config_get "GIT_NAME" "$USER")

SCHEMAS_DIR="$SCRIPT_DIR/../schemas"

info "Zielverzeichnis : $HOMELAB_AI_DIR"
info "Schemas-Quelle  : $SCHEMAS_DIR"

# ── Verzeichnisstruktur erstellen ────────────────────────────

step "Verzeichnisstruktur erstellen"

mkdir -p "$HOMELAB_AI_DIR/agents"
mkdir -p "$HOMELAB_AI_DIR/context"
mkdir -p "$HOMELAB_AI_DIR/.claude/agents"
mkdir -p "$HOMELAB_AI_DIR/projects/_template"
mkdir -p "$HOMELAB_AI_DIR/docs/homelab"

success "Verzeichnisstruktur erstellt."

# ── Hilfsfunktion: Template-Platzhalter ersetzen ─────────────

apply_template() {
    local src="$1"
    local dst="$2"
    local content

    content=$(cat "$src")

    # Platzhalter ersetzen
    content="${content//__PROXMOX_IP__/$PROXMOX_IP}"
    content="${content//__CC_IP__/$CC_IP}"
    content="${content//__SSH_USER__/$SSH_USER}"
    content="${content//__GIT_USER__/$GIT_USER}"
    content="${content//__HOMELAB_AI_DIR__/$HOMELAB_AI_DIR}"

    echo "$content" > "$dst"
    success "Template deployt: $(basename "$dst")"
}

# ── Agenten-Dateien kopieren ─────────────────────────────────

step "Agenten-Definitionen deployen"

# Immer: code.md, research.md
for agent in code.md research.md; do
    if [[ -f "$SCHEMAS_DIR/agents/$agent" ]]; then
        cp "$SCHEMAS_DIR/agents/$agent" "$HOMELAB_AI_DIR/agents/$agent"
        success "Agent deployt: $agent"
    else
        warn "Nicht gefunden: $SCHEMAS_DIR/agents/$agent"
    fi
done

# project-planner.md falls vorhanden
if [[ -f "$SCHEMAS_DIR/agents/project-planner.md" ]]; then
    cp "$SCHEMAS_DIR/agents/project-planner.md" "$HOMELAB_AI_DIR/agents/project-planner.md"
    success "Agent deployt: project-planner.md"
fi

# git-manager.md.template → git-manager.md (wenn GitHub CLI aktiviert)
if [[ "$FEATURE_GITHUB" == "true" ]]; then
    if [[ -f "$SCHEMAS_DIR/agents/git-manager.md.template" ]]; then
        apply_template \
            "$SCHEMAS_DIR/agents/git-manager.md.template" \
            "$HOMELAB_AI_DIR/agents/git-manager.md"
    else
        warn "git-manager.md.template nicht gefunden."
    fi
fi

# sysadmin.md.template + homelab-guru.md (wenn MCP-Server aktiviert)
if [[ "$FEATURE_MCP" == "true" ]]; then
    if [[ -f "$SCHEMAS_DIR/agents/sysadmin.md.template" ]]; then
        apply_template \
            "$SCHEMAS_DIR/agents/sysadmin.md.template" \
            "$HOMELAB_AI_DIR/agents/sysadmin.md"
    else
        warn "sysadmin.md.template nicht gefunden."
    fi

    if [[ -f "$SCHEMAS_DIR/claude-agents/homelab-guru.md" ]]; then
        cp "$SCHEMAS_DIR/claude-agents/homelab-guru.md" \
           "$HOMELAB_AI_DIR/.claude/agents/homelab-guru.md"
        success "Claude-Agent deployt: homelab-guru.md"
    else
        warn "homelab-guru.md nicht gefunden."
    fi
fi

# ── CLAUDE.md deployen ───────────────────────────────────────

step "CLAUDE.md deployen"

CLAUDE_TEMPLATE="$SCHEMAS_DIR/CLAUDE.md.template"

if [[ -f "$CLAUDE_TEMPLATE" ]]; then
    apply_template "$CLAUDE_TEMPLATE" "$HOMELAB_AI_DIR/CLAUDE.md"
else
    # Minimales CLAUDE.md erstellen
    cat > "$HOMELAB_AI_DIR/CLAUDE.md" <<CLAUDEMD
# CLAUDE.md

# Globale Regeln

KRITISCH: Antworte IMMER auf Deutsch, egal in welcher Sprache der Input ist.
KRITISCH: Lies beim Start immer zuerst: ${HOMELAB_AI_DIR}/context/INDEX.md

## Verhalten
- Delegiere Aufgaben an spezialisierte Subagenten
- Halte das Kontextfenster klein – lade Kontext nur bei Bedarf
- SSH-Zugriffe immer über @sysadmin
- Frage nach, bevor du destruktive Operationen ausführst

## Subagenten

| Agent | Datei | Zuständigkeit |
|---|---|---|
| @code | agents/code.md | Code, Dateien, Konfigurationen |
| @research | agents/research.md | Recherche, Dokumentation |
CLAUDEMD
    success "Minimales CLAUDE.md erstellt."
fi

# ── context/INDEX.md deployen ────────────────────────────────

step "context/INDEX.md deployen"

INDEX_TEMPLATE="$SCHEMAS_DIR/context/INDEX.md.template"

if [[ -f "$INDEX_TEMPLATE" ]]; then
    apply_template "$INDEX_TEMPLATE" "$HOMELAB_AI_DIR/context/INDEX.md"
else
    warn "INDEX.md.template nicht gefunden. Erstelle Minimal-Version."
    cat > "$HOMELAB_AI_DIR/context/INDEX.md" <<INDEXMD
# Homelab-AI – Inhaltsverzeichnis

Zentraler Einstiegspunkt. Lade nur relevante Sektionen.

## Agenten

| Datei | Agent | Zuständigkeit |
|---|---|---|
| [agents/code.md](../agents/code.md) | @code | Code, Dateien, Konfigurationen |
| [agents/research.md](../agents/research.md) | @research | Recherche, Dokumentation |

## Projekte

| Verzeichnis | Beschreibung |
|---|---|
| [projects/_template/](../projects/_template/) | Vorlage für neue Projekte |
INDEXMD
    success "Minimal INDEX.md erstellt."
fi

# ── Projekt-Template erstellen ───────────────────────────────

step "Projekt-Template erstellen"

TEMPLATE_SCHEMAS="$SCHEMAS_DIR/projects"
if [[ -d "$TEMPLATE_SCHEMAS" ]]; then
    cp -r "$TEMPLATE_SCHEMAS/." "$HOMELAB_AI_DIR/projects/_template/"
    success "Projekt-Template aus schemas/projects/ kopiert."
else
    # Minimales Template erstellen
    cat > "$HOMELAB_AI_DIR/projects/_template/README.md" <<TEMPLATEMD
# Projekt-Titel

## Beschreibung
Kurze Beschreibung des Projekts.

## Status
- [ ] Planung
- [ ] In Arbeit
- [ ] Abgeschlossen

## Notizen
TEMPLATEMD
    success "Minimales Projekt-Template erstellt."
fi

# ── Hinweise ausgeben ────────────────────────────────────────

echo ""
info "Agenten-Verzeichnis: $HOMELAB_AI_DIR"
echo ""
echo "  Nächste Schritte:"
echo "  1. Fehlende Platzhalter in CLAUDE.md und INDEX.md anpassen"
if [[ "$FEATURE_MCP" != "true" ]]; then
    echo "  2. Bei Bedarf: sysadmin.md.template nach agents/sysadmin.md deployen"
fi
echo ""

success "11-agents-setup abgeschlossen."
