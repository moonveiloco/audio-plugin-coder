# validate-agent-config.ps1 — contract test per la configurazione agent-agnostic di APC.
# Controparte Windows di scripts/validate-agent-config.sh (stessi controlli).
#
# Usage: .\scripts\validate-agent-config.ps1   (exit 0 = OK, 1 = violazioni)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir

$script:Errors = New-Object System.Collections.Generic.List[string]
$script:Warnings = New-Object System.Collections.Generic.List[string]
$script:PointerCount = 0

function Add-Err([string]$m) { $script:Errors.Add($m) | Out-Null }
function Add-Warn([string]$m) { $script:Warnings.Add($m) | Out-Null }

# ---------- 1. struttura canonica ----------
$Canonical = Join-Path $Root "agents"
foreach ($sub in @("rules", "skills", "workflows", "guides", "troubleshooting")) {
    if (-not (Test-Path (Join-Path $Canonical $sub) -PathType Container)) {
        Add-Err "agents/$sub/ mancante"
    }
}

# ---------- 2/3. frontmatter skill ----------
$SkillsDir = Join-Path $Canonical "skills"
$NameExceptions = @("skill_design_webview")
$CanonicalNames = @{}

if (Test-Path $SkillsDir) {
    foreach ($d in (Get-ChildItem $SkillsDir -Directory | Sort-Object Name)) {
        $p = Join-Path $d.FullName "SKILL.md"
        if (-not (Test-Path $p)) { continue }
        $txt = Get-Content $p -Raw
        if ($txt -notmatch "(?s)^---\r?\n(.*?)\r?\n---\r?\n") {
            Add-Err "agents/skills/$($d.Name)/SKILL.md: frontmatter mancante"
            continue
        }
        $name = $null; $desc = $null
        foreach ($line in ($Matches[1] -split "\r?\n")) {
            if ($line -match "^name:\s*(.*)$")   { $name = $Matches[1].Trim().Trim('"') }
            if ($line -match "^description:\s*(.*)$") { $desc = $Matches[1].Trim().Trim('"') }
        }
        if (-not $name -or -not $desc) {
            Add-Err "agents/skills/$($d.Name)/SKILL.md: frontmatter incompleto (richiesti name + description)"
            continue
        }
        $CanonicalNames[$name] = $d.Name
        if ($name -ne $d.Name -and $NameExceptions -notcontains $d.Name) {
            Add-Err "agents/skills/$($d.Name)/SKILL.md: name '$name' != nome cartella '$($d.Name)'"
        }
    }
}

# ---------- 4. duplicati per scope di discovery ----------
# (la canonica agents/ e' esclusa: nessun tool la scopre direttamente)
$Scopes = @{
    ".claude/skills"   = @(".opencode/skills", ".claude/skills")  # opencode scopre entrambe
    ".kilocode/skills" = @(".kilocode/skills")
}
foreach ($scope in $Scopes.Keys) {
    $names = @{}
    foreach ($sd in $Scopes[$scope]) {
        $base = Join-Path $Root ($sd -replace "/", "\")
        if (-not (Test-Path $base)) { continue }
        foreach ($d in (Get-ChildItem $base -Directory)) {
            $p = Join-Path $d.FullName "SKILL.md"
            if (-not (Test-Path $p)) { continue }
            $line = (Get-Content $p | Select-String -Pattern "^name:\s*(\S+)").Matches
            if ($line) {
                $n = $line[0].Groups[1].Value.Trim('"')
                if ($names.ContainsKey($n)) { Add-Err "nome skill duplicato in $scope : '$n'" }
                else { $names[$n] = "$sd/$($d.Name)" }
            }
        }
    }
}

# ---------- 5. puntatori risolti ----------
$AgentRef = [regex]"agents/(?:skills/[\w.-]+/SKILL\.md|workflows/[\w.-]+\.md|rules/[\w.-]+\.md|troubleshooting/[\w./-]+|guides/[\w.-]+\.md)"
foreach ($home in @(".claude", ".kilocode")) {
    foreach ($sub in @("skills", "workflows", "rules")) {
        $base = Join-Path $Root ($home + "\" + $sub)
        if (-not (Test-Path $base)) { continue }
        foreach ($f in (Get-ChildItem $base -Recurse -Filter "*.md")) {
            $txt = Get-Content $f.FullName -Raw
            $refs = $AgentRef.Matches($txt) | ForEach-Object { $_.Value }
            if (-not $refs -or $refs.Count -eq 0) {
                Add-Err "$($f.FullName): puntatore senza riferimento a agents/"
                continue
            }
            $script:PointerCount++
            foreach ($r in $refs) {
                if (-not (Test-Path (Join-Path $Root ($r -replace "/", "\")))) {
                    Add-Err "$($f.FullName): target inesistente $r"
                }
            }
        }
    }
}

# ---------- 6/7. riferimenti stanti ----------
$ConfigFiles = @()
foreach ($base in @("agents", ".claude", ".kilocode", ".opencode", "scripts")) {
    if (Test-Path (Join-Path $Root $base)) {
        $ConfigFiles += Get-ChildItem (Join-Path $Root $base) -Recurse -File |
            Where-Object { $_.Extension -in ".md", ".yaml", ".yml", ".json", ".jsonc" -and $_.FullName -notmatch "node_modules" } |
            Select-Object -ExpandProperty FullName
    }
}
foreach ($extra in @("AGENTS.md", "CLAUDE.md", "opencode.jsonc")) {
    $p = Join-Path $Root $extra
    if (Test-Path $p) { $ConfigFiles += $p }
}

foreach ($f in $ConfigFiles) {
    $txt = Get-Content $f -Raw -ErrorAction SilentlyContinue
    if (-not $txt) { continue }
    $r = $f.Substring($Root.Length + 1)
    if ($txt -match "R:\\")      { Add-Err "${r}: riferimento macchina 'R:\'" }
    if ($txt -match "_VST_Development") { Add-Err "${r}: riferimento macchina '_VST_Development'" }
    if ($txt -match "C:\\Users\\") { Add-Err "${r}: riferimento macchina 'C:\Users\'" }
    $hist = ($r -match "troubleshooting[/\\]resolutions") -and ($txt.Substring(0, [Math]::Min(400, $txt.Length)) -match "HISTORICAL")
    $i = 0
    foreach ($line in ($txt -split "\r?\n")) {
        $i++
        if ($line -match "~/JUCE" -and $line -notmatch "(?i)(non\b|never|not\b|mai|vietato|forbidden)") {
            Add-Err "${r}:${i}: riferimento '~/JUCE' senza negazione"
        }
        if ($line -match "JUCE 8" -and -not $hist -and
            $line -notmatch "JUCE 8(→|\+)|Da JUCE 8|since JUCE 8" -and
            $line -notmatch "(?i)(storico|storici|historical)") {
            Add-Err "${r}:${i}: 'JUCE 8' attivo fuori dai documenti HISTORICAL"
        }
    }
}

# ---------- 8. entry points ----------
foreach ($f in @("AGENTS.md", "CLAUDE.md", "opencode.jsonc", "scripts\agent-homes.json")) {
    if (-not (Test-Path (Join-Path $Root $f))) { Add-Err "$f mancante" }
}

$ClaudeMd = Join-Path $Root "CLAUDE.md"
if (Test-Path $ClaudeMd) {
    foreach ($imp in (Select-String -Path $ClaudeMd -Pattern "^@(\S+)" -AllMatches).Matches) {
        $target = Join-Path $Root ($imp.Groups[1].Value -replace "/", "\")
        if (-not (Test-Path $target)) { Add-Err "CLAUDE.md: import @$($imp.Groups[1].Value) inesistente" }
    }
}

$Oc = Join-Path $Root "opencode.jsonc"
if (Test-Path $Oc) {
    $txt = (Get-Content $Oc -Raw) -replace "(?<!:)//[^\n]*", ""
    try {
        $cfg = $txt | ConvertFrom-Json
        foreach ($inst in $cfg.instructions) {
            if (-not (Test-Path (Join-Path $Root ($inst -replace "/", "\")))) {
                Add-Err "opencode.jsonc: instruction '$inst' inesistente"
            }
        }
        if ($cfg.PSObject.Properties["skills"]) {
            Add-Warn "opencode.jsonc contiene ancora 'skills.paths' (rimuoverla)"
        }
    } catch {
        Add-Err "opencode.jsonc: JSON non valido ($($_.Exception.Message))"
    }
}

# ---------- 9. .gitignore ----------
$Gi = Join-Path $Root ".gitignore"
if (Test-Path $Gi) {
    foreach ($line in (Get-Content $Gi)) {
        $s = $line.Trim()
        if ($s -in @("agents", "agents/", "/agents", "AGENTS.md", "CLAUDE.md", "/AGENTS.md", "/CLAUDE.md")) {
            Add-Err ".gitignore: esclude '$s'"
        }
    }
}

# ---------- 10. manifest ----------
$Mf = Join-Path $Root "scripts\agent-homes.json"
if (Test-Path $Mf) {
    $manifest = Get-Content $Mf -Raw | ConvertFrom-Json
    if (-not (Test-Path (Join-Path $Root $manifest.canonical_dir))) {
        Add-Err "manifest: canonical_dir '$($manifest.canonical_dir)' inesistente"
    }
    foreach ($h in $manifest.homes) {
        if (-not (Test-Path (Join-Path $Root $h.dir))) { Add-Err "manifest: home '$($h.dir)' inesistente" }
    }
}

# ---------- report ----------
Write-Host "Puntatori verificati: $script:PointerCount"
Write-Host "Skill canoniche: $($CanonicalNames.Count)"
if ($script:Warnings.Count -gt 0) {
    Write-Host "`nWARNING:"
    foreach ($w in $script:Warnings) { Write-Host "  WARN $w" }
}
if ($script:Errors.Count -gt 0) {
    Write-Host "`nFAIL ($($script:Errors.Count) violazioni):"
    foreach ($e in $script:Errors) { Write-Host "  FAIL $e" }
    exit 1
}
Write-Host "`nOK — configurazione agent valida"
