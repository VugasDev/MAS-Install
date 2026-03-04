# homelab-ai — Zielstruktur

Dieses Dokument beschreibt die Verzeichnisstruktur, die das MAS-Install-Paket
auf einem neuen System anlegen soll (unter `/home/homelab-ai/`).

## Verzeichnisbaum

```
/home/homelab-ai/
├── CLAUDE.md                      # Orchestrator-Regeln (aus CLAUDE.md.template)
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
│       ├── server.md              # Manuell ausfüllen
│       ├── network.md             # Manuell ausfüllen
│       └── services.md            # Manuell ausfüllen
└── projects/
    └── _template/
        └── README.md              # Projekt-Template — verbatim
```

## Einrichtungsablauf

1. `install.sh` installiert die Tools (Claude Code, gh, Gemini, etc.)
2. Der Benutzer authentifiziert sich (`claude`, `gh auth login`, etc.)
3. Der Benutzer erstellt `/home/homelab-ai/` und kopiert die Schema-Dateien
4. Claude liest `CLAUDE.md` und `context/INDEX.md` und versteht die Struktur
5. Claude hilft beim Ausfüllen der Platzhalter (IPs, Projekte, Services)

## Platzhalter-Konvention

Templates verwenden `__PLATZHALTER__`-Syntax:
- `__PROXMOX_IP__` — IP des Proxmox-Hosts
- `__CC_IP__` — IP der command-center VM
- `__SSH_USER__` — SSH-Benutzername
- `__GIT_USER__` — GitHub-Benutzername
