# homelab-ai — Zielstruktur

Dieses Dokument beschreibt die Verzeichnisstruktur, die das MAS-Install-Paket
auf einem neuen System anlegen soll (unter `~/homelab-ai/`).

## Verzeichnisbaum

```
~/homelab-ai/
├── CLAUDE.md                      # Orchestrator-Regeln (aus CLAUDE.md.template)
├── .gitignore                     # Ignoriert projects/* (separat verwaltet)
├── .gitattributes                 # LF-Zeilenumbrueche fuer .sh, .bash, .md
├── agents/
│   ├── code.md                    # @code Agent — verbatim
│   ├── sysadmin.md                # @sysadmin Agent — IPs als Platzhalter
│   ├── research.md                # @research Agent — verbatim
│   └── git-manager.md             # @git-manager Agent — Projekte als Platzhalter
├── .claude/
│   └── agents/
│       └── homelab-guru.md        # Claude Agent — verbatim
├── context/
│   └── INDEX.md                   # Inhaltsverzeichnis (aus INDEX.md.template)
├── docs/
│   └── homelab/
│       ├── server.md              # Manuell ausfuellen
│       ├── network.md             # Manuell ausfuellen
│       ├── services.md            # Manuell ausfuellen
│       └── users.md               # Manuell ausfuellen
├── shell/
│   └── aliases.sh                 # Shell-Aliases, per source in .bashrc eingebunden
└── projects/
    └── _template/
        └── README.md              # Projekt-Template — verbatim
```

## Einrichtungsablauf

1. `install.sh` installiert die Tools (Claude Code, gh, Gemini, etc.)
2. Der Benutzer authentifiziert sich (`claude`, `gh auth login`, etc.)
3. Der Benutzer klont oder erstellt `~/homelab-ai/` und kopiert die Schema-Dateien
4. Claude liest `CLAUDE.md` und `context/INDEX.md` und versteht die Struktur
5. Claude hilft beim Ausfuellen der Platzhalter (IPs, Projekte, Services)

## Platzhalter-Konvention

Templates verwenden `__PLATZHALTER__`-Syntax:
- `__PROXMOX_IP__` — IP des Proxmox-Hosts
- `__CC_IP__` — IP der command-center VM
- `__SSH_USER__` — SSH-Benutzername
- `__GIT_USER__` — GitHub-Benutzername

## Shell-Integration

Die `.bashrc` wird per MAS-Install um einen Block erweitert, der:
- NVM initialisiert
- pipx PATH setzt
- API-Key Platzhalter bereitstellt (auskommentiert)
- `~/homelab-ai/shell/aliases.sh` per source einbindet

Die Aliases werden im homelab-ai Repo verwaltet und per Git versioniert.
