#!/usr/bin/env bash
# MAS-Install — Config-Verwaltung
# Speichert/liest Konfiguration als KEY=VALUE Datei.
# Datei: /tmp/mas-install-config.sh während der Installation

CONFIG_FILE="${MAS_CONFIG_FILE:-/tmp/mas-install-config.sh}"

# Setzt einen Konfigurationswert (überschreibt vorhandene Einträge)
config_set() {
    local key="$1"
    local value="$2"

    # Datei erstellen falls nicht vorhanden
    if [[ ! -f "$CONFIG_FILE" ]]; then
        touch "$CONFIG_FILE"
    fi

    # Vorhandenen Eintrag entfernen und neu schreiben
    local tmpfile
    tmpfile=$(mktemp)
    grep -v "^${key}=" "$CONFIG_FILE" > "$tmpfile" 2>/dev/null || true
    echo "${key}=$(printf '%q' "$value")" >> "$tmpfile"
    mv "$tmpfile" "$CONFIG_FILE"
}

# Liest einen Konfigurationswert (mit optionalem Default)
config_get() {
    local key="$1"
    local default="${2:-}"

    if [[ -f "$CONFIG_FILE" ]]; then
        local line
        line=$(grep "^${key}=" "$CONFIG_FILE" 2>/dev/null || true)
        if [[ -n "$line" ]]; then
            # Wert extrahieren und evaluieren (printf %q encoding rückgängig)
            local raw="${line#"${key}"=}"
            eval "echo $raw"
            return
        fi
    fi

    echo "$default"
}

# Lädt alle Konfigurationswerte in die aktuelle Shell (als export)
config_load() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        set -o allexport
        source "$CONFIG_FILE"
        set +o allexport
    fi
}
