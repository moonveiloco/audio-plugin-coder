# sync-agent-pointers.ps1 — rigenera le case nascoste degli agent partendo da agents/
# (single source of truth). Le case contengono SOLO puntatori: mai modificare i file
# puntatore a mano — modifica agents/ e rilancia questo script.
#
# Usage:
#   .\scripts\sync-agent-pointers.ps1            # rigenera i puntatori
#   .\scripts\sync-agent-pointers.ps1 -DryRun    # mostra cosa farebbe, non scrive
#
# Configurazione case: scripts/agent-homes.json

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ManifestPath = Join-Path $ScriptDir "agent-homes.json"

if (-not (Test-Path $ManifestPath)) {
    Write-Error "Manifest non trovato: $ManifestPath"
}

$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
$Canonical = Join-Path $ProjectRoot $Manifest.canonical_dir

if (-not (Test-Path $Canonical)) {
    Write-Error "Cartella canonica mancante: $Canonical"
}

function Read-Frontmatter([string]$Path) {
    $txt = Get-Content $Path -Raw
    $fields = @{}
    if ($txt -match "(?s)^---\r?\n(.*?)\r?\n---\r?\n") {
        foreach ($line in ($Matches[1] -split "\r?\n")) {
            if ($line -match "^(\w+):\s*(.*)$") {
                $val = $Matches[2].Trim().Trim('"')
                $fields[$Matches[1]] = $val
            }
        }
    }
    return $fields
}

function Write-Pointer([string]$Path, [string]$Content) {
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
}

$SkillsDir    = Join-Path $Canonical "skills"
$Skills       = Get-ChildItem $SkillsDir -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | Sort-Object Name
$Workflows    = Get-ChildItem (Join-Path $Canonical "workflows") -Filter "*.md" | Sort-Object Name
$Rules        = Get-ChildItem (Join-Path $Canonical "rules") -Filter "*.md" | Sort-Object Name

foreach ($home_ in $Manifest.homes) {
    $HDir = Join-Path $ProjectRoot $home_.dir
    Write-Host "== $($home_.dir) =="

    if ($home_.skills) {
        $SDir = Join-Path $HDir "skills"
        if (Test-Path $SDir) { Remove-Item $SDir -Recurse -Force }
        foreach ($s in $Skills) {
            $fm  = Read-Frontmatter (Join-Path $s.FullName "SKILL.md")
            $name = if ($fm.name) { $fm.name } else { $s.Name }
            $desc = if ($fm.description) { $fm.description } else { "" }
            $escapedDesc = $desc -replace '\', '\\' -replace '"', '\"'
            $body = @"
---
name: $name
description: "$escapedDesc"
---

# Skill: $name (puntatore)

Carica ed esegui **esattamente** ``agents/skills/$($s.Name)/SKILL.md`` (single source of truth). Non improvisare il contenuto della skill.
"@
            $out = Join-Path $SDir "$($s.Name)\SKILL.md"
            Write-Host "  skill: $($home_.dir)/skills/$($s.Name)/SKILL.md"
            if (-not $DryRun) { Write-Pointer $out $body }
        }
    }

    if ($home_.workflows) {
        $WDir = Join-Path $HDir "workflows"
        if (Test-Path $WDir) { Remove-Item $WDir -Recurse -Force }
        foreach ($wf in $Workflows) {
            $fm  = Read-Frontmatter $wf.FullName
            $desc = if ($fm.description) { $fm.description } else { "" }
            $escapedDesc = $desc -replace '\', '\\' -replace '"', '\"'
            $body = @"
---
description: "$escapedDesc"
---

Carica ed esegui **esattamente** ``agents/workflows/$($wf.Name)`` (single source of truth). Non improvisare il contenuto del workflow.
"@
            $out = Join-Path $WDir $wf.Name
            Write-Host "  workflow: $($home_.dir)/workflows/$($wf.Name)"
            if (-not $DryRun) { Write-Pointer $out $body }
        }
    }

    if ($home_.rules) {
        $RDir = Join-Path $HDir "rules"
        if (Test-Path $RDir) { Remove-Item $RDir -Recurse -Force }
        foreach ($rf in $Rules) {
            $body = @"
# $($rf.Name) (puntatore)

**Single source of truth:** leggi e segui ``agents/rules/$($rf.Name)`` prima di procedere con qualsiasi operazione.
"@
            $out = Join-Path $RDir $rf.Name
            Write-Host "  rule: $($home_.dir)/rules/$($rf.Name)"
            if (-not $DryRun) { Write-Pointer $out $body }
        }
    }
}

if ($DryRun) { Write-Host "DRY RUN (nessun file scritto)" } else { Write-Host "OK" }
