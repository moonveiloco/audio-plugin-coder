# APC JIVE Preview (Windows)
# Builds (cached) and launches jive-preview on a plugin's JIVE layout markup.
#
# Usage:
#   .\scripts\preview-jive.ps1 -PluginName <Name> [-Version v2]
#
# NOTE: this script is strictly opt-in. It is only meant for plugins whose
# ui_framework is "jive"; every other framework keeps its own preview path
# (Visage -> preview-design.ps1, WebView -> browser). Nothing here modifies
# the build system or any other plugin.

param(
    [Parameter(Mandatory = $true)]
    [string]$PluginName,
    [Parameter(Mandatory = $false)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

# --- PATH RESOLUTION ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = Resolve-Path (Join-Path $ScriptDir "..")
$ApcPluginsDir = & (Join-Path $ScriptDir "apc-config.ps1") plugins-dir
if (-not $ApcPluginsDir) {
    Write-Error "Run /setup first."
    exit 1
}
$PluginDir = Join-Path $ApcPluginsDir $PluginName

if (-not (Test-Path $PluginDir)) {
    Write-Error "Plugin '$PluginName' not found in APC_PLUGINS_DIR ($ApcPluginsDir). Run /setup or create the plugin with /dream."
    exit 1
}

# --- NON-BINDING GUARD: only act on JIVE plugins ---
$StatusJson = Join-Path $PluginDir "status.json"
if (Test-Path $StatusJson) {
    $State = Get-Content $StatusJson -Raw | ConvertFrom-Json
    $Framework = if ($State.ui_framework) { $State.ui_framework } else { "pending" }
    if ($Framework -ne "jive") {
        Write-Host "Plugin '$PluginName' has ui_framework='$Framework': not a JIVE plugin." -ForegroundColor Yellow
        Write-Host "preview-jive is opt-in and does nothing for other frameworks."
        switch ($Framework) {
            "visage"  { Write-Host "Hint: use preview-design.ps1 for Visage plugins." }
            "webview" { Write-Host "Hint: open Design\index.html in a browser for WebView plugins." }
        }
        exit 1
    }
}

# --- LOCATE LAYOUT MARKUP ---
if ($Version) {
    $Layout = Join-Path $PluginDir "Design\$Version-layout.xml"
} else {
    $Layout = Get-ChildItem -Path (Join-Path $PluginDir "Design") -Filter "v*-layout.xml" -ErrorAction SilentlyContinue |
        Sort-Object Name -Version |
        Select-Object -Last 1 -ExpandProperty FullName
}

if (-not $Layout -or -not (Test-Path $Layout)) {
    Write-Error "No JIVE layout markup found for '$PluginName'. Expected Design\v<N>-layout.xml (created by the /design phase)."
    exit 1
}

Write-Host "--- APC JIVE PREVIEW: $PluginName ---"
Write-Host "Layout: $Layout"

# --- BUILD (cached; build dir lives inside the tool, not the repo root) ---
$BuildDir = Join-Path $RootPath "tools\jive-preview\build"
$Cache = Join-Path $BuildDir "CMakeCache.txt"
$NeedsConfigure = -not (Test-Path $Cache)

if (-not $NeedsConfigure) {
    $ScanPaths = @((Join-Path $RootPath "tools\jive-preview\CMakeLists.txt"), (Join-Path $RootPath "tools\jive-preview\Source"))
    $NewestSource = Get-ChildItem -Path $ScanPaths -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -gt (Get-Item $Cache).LastWriteTime } |
        Select-Object -First 1
    if ($NewestSource) { $NeedsConfigure = $true }
}

if ($NeedsConfigure) {
    Write-Host "Configuring jive-preview..."
    cmake -S (Join-Path $RootPath "tools\jive-preview") -B $BuildDir -DAPC_TOOLS_DIR="$RootPath" -DCMAKE_BUILD_TYPE=Release
}

Write-Host "Building jive-preview..."
cmake --build $BuildDir --config Release --target jive-preview

# --- LAUNCH ---
$Bin = Get-ChildItem -Path $BuildDir -Recurse -Filter "jive-preview.exe" |
    Sort-Object FullName |
    Select-Object -Last 1 -ExpandProperty FullName

if (-not $Bin) {
    Write-Error "jive-preview.exe not found under $BuildDir."
    exit 1
}

Write-Host "Launching (close the window to stop)..."
& $Bin $Layout
