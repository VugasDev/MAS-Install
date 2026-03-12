# MAS-Install — Multi-Agent System Installer

Reproduzierbares Installationspaket fuer das **homelab-ai** Multi-Agent System.
Auf einem blanken Ubuntu-System: `git clone` + `./install.sh` — fertig.

## Quick Start

```bash
git clone git@github.com:VugasDev/MAS-Install.git
cd MAS-Install
./install.sh
```

## Voraussetzungen

- **Ubuntu 22.04+** oder Debian-basiertes System (WSL2 funktioniert)
- **Benutzer mit sudo-Rechten** (nicht als root ausfuehren)
- **Internetverbindung** fuer Downloads

## Was wird installiert?

| Modul | Beschreibung |
|---|---|
| `01-system-base` | Build-Tools, curl, git, jq, etc. + sudo NOPASSWD |
| `02-nvm-node` | NVM + Node.js LTS (>= 20) |
| `03-claude-code` | Claude Code CLI (nativer Installer) + Settings-Template |
| `04-github-cli` | GitHub CLI (gh) via offiziellem apt-Repo |
| `05-gemini-cli` | Google Gemini CLI (npm, braucht Node >= 20) |
| `06-python-tools` | Python3, pip, pipx, aider-chat |
| `07-git-config` | Git Name/E-Mail (interaktiv), default branch, credential helper |
| `08-bashrc-setup` | NVM, PATH, shell/aliases.sh Source, API-Key-Platzhalter in ~/.bashrc |

Alle Module sind **idempotent** — sie erkennen bereits installierte Tools und ueberspringen sie.

## Optionen

```bash
./install.sh                          # Alles installieren
./install.sh --skip 05-gemini-cli     # Ohne Gemini CLI
./install.sh --only 02-nvm-node       # Nur NVM + Node
./install.sh --dry-run                # Zeigt was installiert wuerde
./install.sh --list                   # Verfuegbare Module auflisten
```

### Einzelne Module ausfuehren

Jedes Skript kann auch direkt ausgefuehrt werden:

```bash
./scripts/05-gemini-cli.sh
```

## Post-Install Schritte

Nach der Installation muessen die Tools manuell authentifiziert werden:

1. **Shell neu laden:** `source ~/.bashrc`
2. **GitHub:** `gh auth login` — Browser-Flow empfohlen
3. **Claude Code:** `claude` starten — authentifiziert ueber Anthropic-Account
4. **Gemini CLI:** `gemini` starten — OAuth-Flow oder API-Key
5. **API-Keys:** In `~/.bashrc` die auskommentierten `export`-Zeilen aktivieren
6. **SSH-Key:** `ssh-keygen -t ed25519` (falls noch keiner existiert)
7. **homelab-ai Repo:** `git clone` oder Schema-Dateien nach `~/homelab-ai/` kopieren

## Schema-Dateien

Unter `schemas/` liegen die Agent-Definitionen und Templates fuer das homelab-ai System:

```
schemas/
├── homelab-ai-structure.md     # Dokumentation der Zielstruktur
├── CLAUDE.md.template          # Orchestrator-Regeln
├── gitignore                   # .gitignore Template
├── gitattributes               # .gitattributes Template (LF enforcement)
├── context/
│   └── INDEX.md.template       # Inhaltsverzeichnis
├── agents/
│   ├── code.md                 # @code Agent (verbatim)
│   ├── sysadmin.md.template    # @sysadmin (IPs als Platzhalter)
│   ├── research.md             # @research Agent (verbatim)
│   └── git-manager.md.template # @git-manager (Projekte als Platzhalter)
├── claude-agents/
│   └── homelab-guru.md         # Claude Agent (verbatim)
├── shell/
│   └── aliases.sh              # Shell-Aliases Template
└── projects/
    └── _template/
        └── README.md           # Projekt-Template (verbatim)
```

### Shell-Integration

Die `.bashrc` wird per MAS-Install um einen Block erweitert, der u.a. `~/homelab-ai/shell/aliases.sh` per `source` einbindet. Aliases werden dadurch im homelab-ai Repo versioniert und bei jedem Shell-Start geladen.

### Platzhalter

Templates verwenden `__PLATZHALTER__`-Syntax. Nach dem Kopieren ersetzen:

| Platzhalter | Beschreibung | Beispiel |
|---|---|---|
| `__PROXMOX_IP__` | IP des Proxmox-Hosts | `192.168.0.191` |
| `__CC_IP__` | IP der command-center VM | `192.168.0.142` |
| `__SSH_USER__` | SSH-Benutzername | `vugas` |
| `__GIT_USER__` | GitHub-Benutzername | `VugasDev` |

## Troubleshooting

### Node-Version zu alt

```bash
# NVM laden und LTS installieren
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'
node --version  # Sollte >= 20 sein
```

### NVM nicht gefunden nach Installation

NVM wird erst nach einem Shell-Neustart verfuegbar:

```bash
source ~/.bashrc
# oder
exec bash
```

### npm: Permission denied

**Niemals** `sudo npm install -g` verwenden! NVM installiert Node in `$HOME/.nvm`,
daher braucht `npm install -g` kein sudo. Falls Probleme auftreten:

```bash
# NVM-Node verwenden (nicht System-Node)
which node    # Sollte ~/.nvm/... zeigen
which npm     # Sollte ~/.nvm/... zeigen
```

### pipx: Command not found

```bash
# PATH aktualisieren
source ~/.bashrc
# oder manuell
export PATH="$HOME/.local/bin:$PATH"
```

## Projektstruktur

```
MAS-Install/
├── install.sh              # Haupt-Orchestrator
├── README.md               # Diese Datei
├── .gitignore
├── lib/
│   └── common.sh           # Shared Functions
├── scripts/
│   ├── 01-system-base.sh
│   ├── 02-nvm-node.sh
│   ├── 03-claude-code.sh   # Nutzt nativen Installer (nicht npm)
│   ├── 04-github-cli.sh
│   ├── 05-gemini-cli.sh
│   ├── 06-python-tools.sh
│   ├── 07-git-config.sh
│   └── 08-bashrc-setup.sh
├── configs/
│   ├── claude-settings.json
│   └── bashrc-additions.sh # Inkl. source auf ~/homelab-ai/shell/aliases.sh
└── schemas/
    └── ...                 # Agent-Definitionen und Templates
```

## Lizenz

Privates Repository — nur fuer persoenlichen Gebrauch.
