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

# <<< MAS-Install <<<
