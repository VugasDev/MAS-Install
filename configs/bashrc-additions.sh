# >>> MAS-Install >>>
# Automatisch hinzugefügt von MAS-Install — nicht manuell bearbeiten.

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# pipx
export PATH="$HOME/.local/bin:$PATH"

# API Keys (auskommentiert — nach Bedarf aktivieren)
# export ANTHROPIC_API_KEY="sk-ant-..."
# export GEMINI_API_KEY="..."
# export OPENAI_API_KEY="sk-..."

# Aliases
alias ll='ls -alF'
alias cls='clear'
alias gs='git status'
alias gl='git log --oneline -10'
alias gp='git push'

# MCP-Server sicherstellen vor CLI-Nutzung
# (Nur aktiv wenn MCP_SERVER_ENABLED=true gesetzt)
_mas_ensure_mcp() {
    [[ "${MCP_SERVER_ENABLED:-false}" != "true" ]] && return 0
    if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^mcp-proxmox$'; then
        echo "[MAS] MCP-Server wird gestartet..."
        if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^mcp-proxmox$'; then
            docker start mcp-proxmox
        else
            local mcp_dir="${MCP_SERVER_DIR:-$HOME/mcp-proxmox}"
            (cd "$mcp_dir" && docker compose -f docker/docker-compose.yml up -d 2>/dev/null)
        fi
        sleep 1
    fi
}

# <<< MAS-Install <<<
