<#
.SYNOPSIS
    Copies the plugins-directory README template into the configured APC_PLUGINS_DIR.

.DESCRIPTION
    Idempotent: skips if README.md already exists (does not overwrite user customizations).
    Use -Force to overwrite an existing README.md.

.PARAMETER Force
    Overwrite an existing README.md in APC_PLUGINS_DIR.

.EXAMPLE
    .\scripts\init-plugins-dir.ps1
.EXAMPLE
    .\scripts\init-plugins-dir.ps1 -Force
#>
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# --- PATH RESOLUTION ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = Split-Path -Parent $ScriptDir
$Template = Join-Path $RootPath "templates\plugins-dir-readme.md"

# --- RESOLVE APC_PLUGINS_DIR ---
$ApcPluginsDir = & "$ScriptDir\apc-config.ps1" plugins-dir
if ($LASTEXITCODE -ne 0) {
    Write-Error "APC_PLUGINS_DIR not configured. Run /setup first."
    exit 1
}

# --- VALIDATE PLUGINS DIR EXISTS ---
if (-not (Test-Path $ApcPluginsDir -PathType Container)) {
    Write-Error "Plugins directory does not exist: $ApcPluginsDir. Run /setup first (it creates the directory)."
    exit 1
}

# --- VALIDATE TEMPLATE EXISTS ---
if (-not (Test-Path $Template -PathType Leaf)) {
    Write-Error "README template not found: $Template"
    exit 1
}

# --- CHECK EXISTING README ---
$Target = Join-Path $ApcPluginsDir "README.md"
if ((Test-Path $Target -PathType Leaf) -and -not $Force) {
    Write-Host "README.md already exists at $Target (skipping). Use -Force to overwrite."
    exit 0
}

# --- COMPUTE PLACEHOLDERS ---
$DirName = Split-Path $ApcPluginsDir -Leaf
$RepoUrl = "https://github.com/noizefield/audio-plugin-coder"

# --- COPY + SUBSTITUTE (literal .Replace to handle Windows backslashes) ---
$content = (Get-Content $Template -Raw).
    Replace('{{PLUGINS_DIR_NAME}}', $DirName).
    Replace('{{PLUGINS_DIR_PATH}}', $ApcPluginsDir).
    Replace('{{APC_REPO_URL}}', $RepoUrl)

Set-Content -Path $Target -Value $content -NoNewline

Write-Host "Created README.md at $Target"
