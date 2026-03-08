# MAS-Install — Windows Setup Launcher
# Wird als Administrator auf einem frischen Windows-PC ausgefuehrt.
# Installiert WSL2 + Ubuntu 22.04, optionale Windows-Apps, und startet install.sh in WSL.

#Requires -Version 5.1

param(
    [switch]$SkipWindowsApps,
    [switch]$SkipWizard,
    [string]$RepoUrl = "https://github.com/VugasDev/MAS-Install.git",
    [string]$InstallPath = "~/MAS-Install"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Farben / Logging ────────────────────────────────────────

function Write-Info  { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host "[OK]    $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Step  { param($msg) Write-Host "`n>>> $msg" -ForegroundColor White }

# ── Banner ──────────────────────────────────────────────────

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   MAS-Install — Windows Setup Launcher  ║" -ForegroundColor Cyan
Write-Host "  ║   Multi-Agent System Installer v2.0     ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Admin-Prüfung ────────────────────────────────────────────

$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

if (-not $isAdmin) {
    Write-Err "Dieses Skript muss als Administrator ausgefuehrt werden."
    Write-Err "Rechtsklick auf PowerShell -> 'Als Administrator ausfuehren'"
    exit 1
}

Write-Ok "Administrator-Rechte vorhanden."

# ── WSL2 prüfen / installieren ───────────────────────────────

Write-Step "WSL2-Status prüfen"

$wslInstalled = $false
try {
    $wslStatus = wsl --status 2>&1
    if ($LASTEXITCODE -eq 0) {
        $wslInstalled = $true
        Write-Ok "WSL2 ist bereits installiert."
    }
} catch {
    $wslInstalled = $false
}

if (-not $wslInstalled) {
    Write-Info "WSL2 wird installiert (Ubuntu 22.04)..."
    Write-Warn "Das System muss nach der WSL2-Installation neu gestartet werden."
    Write-Warn "Fuehre das Skript nach dem Neustart erneut aus."
    echo ""

    $confirm = Read-Host "WSL2 jetzt installieren? [j/N]"
    if ($confirm -notin @("j", "J", "ja", "Ja", "y", "Y", "yes")) {
        Write-Warn "Abgebrochen."
        exit 0
    }

    wsl --install -d Ubuntu-22.04
    if ($LASTEXITCODE -ne 0) {
        Write-Err "WSL2 Installation fehlgeschlagen (Exit-Code: $LASTEXITCODE)"
        Write-Info "Bitte manuell installieren: https://aka.ms/wsl"
        exit 1
    }

    Write-Ok "WSL2 + Ubuntu 22.04 installiert."
    Write-Warn "Neustart erforderlich. Nach dem Neustart dieses Skript erneut ausfuehren."
    Read-Host "Enter druecken zum Neustart..."
    Restart-Computer -Force
    exit 0
}

# ── Ubuntu 22.04 Distribution prüfen ────────────────────────

Write-Step "Ubuntu 22.04 Distribution prüfen"

$distros = wsl --list --quiet 2>&1
$ubuntuInstalled = $distros | Where-Object { $_ -match "Ubuntu-22.04" }

if (-not $ubuntuInstalled) {
    Write-Info "Ubuntu 22.04 wird installiert..."
    wsl --install -d Ubuntu-22.04
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Ubuntu 22.04 Installation fehlgeschlagen."
        exit 1
    }
    Write-Ok "Ubuntu 22.04 installiert."

    # Warten bis Ubuntu initialisiert ist
    Write-Info "Warte auf Ubuntu-Initialisierung (30 Sekunden)..."
    Start-Sleep -Seconds 30
} else {
    Write-Ok "Ubuntu 22.04 bereits vorhanden."
}

# ── Erster Start / Initialisierung prüfen ────────────────────

Write-Step "Ubuntu-Verfügbarkeit prüfen"

$testResult = wsl -d Ubuntu-22.04 -- echo "OK" 2>&1
if ($testResult -notmatch "OK") {
    Write-Warn "Ubuntu reagiert noch nicht. Warte weitere 15 Sekunden..."
    Start-Sleep -Seconds 15
    $testResult = wsl -d Ubuntu-22.04 -- echo "OK" 2>&1
    if ($testResult -notmatch "OK") {
        Write-Err "Ubuntu 22.04 antwortet nicht. Bitte manuell starten und dann erneut versuchen:"
        Write-Info "  wsl -d Ubuntu-22.04"
        exit 1
    }
}

Write-Ok "Ubuntu 22.04 erreichbar."

# ── Windows-Apps optional installieren ──────────────────────

if (-not $SkipWindowsApps) {
    Write-Step "Windows-Apps (optional)"
    echo ""
    Write-Host "  Folgende Apps koennen per winget installiert werden:" -ForegroundColor White
    Write-Host "    [1] Windows Terminal (empfohlen)" -ForegroundColor Gray
    Write-Host "    [2] Visual Studio Code" -ForegroundColor Gray
    Write-Host "    [3] Docker Desktop" -ForegroundColor Gray
    Write-Host ""

    $appInput = Read-Host "  Auswahl (z.B. '1 2', 'all', 'none')"
    $appInput = $appInput.ToLower().Trim()

    $installTerminal = $false
    $installVSCode   = $false
    $installDocker   = $false

    if ($appInput -eq "all") {
        $installTerminal = $true
        $installVSCode   = $true
        $installDocker   = $true
    } elseif ($appInput -ne "none" -and $appInput -ne "") {
        $nums = $appInput -split '\s+'
        if ($nums -contains "1") { $installTerminal = $true }
        if ($nums -contains "2") { $installVSCode   = $true }
        if ($nums -contains "3") { $installDocker   = $true }
    }

    # winget verfügbar?
    $wingetAvailable = $false
    try {
        $null = Get-Command winget -ErrorAction Stop
        $wingetAvailable = $true
    } catch {
        Write-Warn "winget nicht gefunden. Windows-Apps werden uebersprungen."
        Write-Info "winget ist ab Windows 10 21H2 verfuegbar (App Installer aus dem Microsoft Store)."
    }

    if ($wingetAvailable) {
        if ($installTerminal) {
            Write-Info "Installiere Windows Terminal..."
            winget install --id Microsoft.WindowsTerminal -e --accept-package-agreements --accept-source-agreements --silent
            if ($LASTEXITCODE -eq 0) { Write-Ok "Windows Terminal installiert." }
            else { Write-Warn "Windows Terminal Installation fehlgeschlagen (moeglicherweise bereits vorhanden)." }
        }

        if ($installVSCode) {
            Write-Info "Installiere Visual Studio Code..."
            winget install --id Microsoft.VisualStudioCode -e --accept-package-agreements --accept-source-agreements --silent
            if ($LASTEXITCODE -eq 0) { Write-Ok "VS Code installiert." }
            else { Write-Warn "VS Code Installation fehlgeschlagen (moeglicherweise bereits vorhanden)." }
        }

        if ($installDocker) {
            Write-Info "Installiere Docker Desktop..."
            winget install --id Docker.DockerDesktop -e --accept-package-agreements --accept-source-agreements --silent
            if ($LASTEXITCODE -eq 0) { Write-Ok "Docker Desktop installiert." }
            else { Write-Warn "Docker Desktop Installation fehlgeschlagen (moeglicherweise bereits vorhanden)." }
        }
    }
}

# ── MAS-Install in WSL klonen ────────────────────────────────

Write-Step "MAS-Install Repository in WSL vorbereiten"

# Git in WSL verfügbar?
$gitCheck = wsl -d Ubuntu-22.04 -- bash -c "command -v git && echo OK" 2>&1
if ($gitCheck -notmatch "OK") {
    Write-Info "Git in Ubuntu wird installiert..."
    wsl -d Ubuntu-22.04 -- bash -c "sudo apt update -qq && sudo apt install -y git"
}

# Prüfen ob Repo bereits geklont
$repoCheck = wsl -d Ubuntu-22.04 -- bash -c "test -d ~/MAS-Install/.git && echo EXISTS" 2>&1
if ($repoCheck -match "EXISTS") {
    Write-Ok "MAS-Install bereits vorhanden. Aktualisiere..."
    wsl -d Ubuntu-22.04 -- bash -c "cd ~/MAS-Install && git pull --ff-only" 2>&1
} else {
    Write-Info "Klone $RepoUrl nach ~/MAS-Install ..."
    wsl -d Ubuntu-22.04 -- bash -c "git clone $RepoUrl ~/MAS-Install"
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Clone fehlgeschlagen."
        exit 1
    }
    Write-Ok "Repository geklont."
}

# Ausführbar machen
wsl -d Ubuntu-22.04 -- bash -c "chmod +x ~/MAS-Install/install.sh ~/MAS-Install/scripts/*.sh 2>/dev/null || true"

# ── install.sh in WSL starten ────────────────────────────────

Write-Step "install.sh in WSL starten"
echo ""

$extraFlags = ""
if ($SkipWizard) { $extraFlags = "--skip-wizard" }

Write-Info "Starte: bash ~/MAS-Install/install.sh $extraFlags"
Write-Info "WSL-Terminal wird geoeffnet..."
echo ""

# In neuem Windows Terminal Tab starten (falls verfügbar), sonst direkt
$wtAvailable = $false
try {
    $null = Get-Command wt -ErrorAction Stop
    $wtAvailable = $true
} catch {}

if ($wtAvailable) {
    wt -d "." wsl -d Ubuntu-22.04 -- bash -c "cd ~/MAS-Install && bash install.sh $extraFlags; exec bash"
} else {
    # Direkt in dieser Session
    wsl -d Ubuntu-22.04 -- bash -c "cd ~/MAS-Install && bash install.sh $extraFlags"
}

Write-Ok "Setup-Launcher abgeschlossen."
