# ACP Config Manager (Windows / PowerShell)
# Reads/writes the global ACP configuration.
# Single source of truth for plugins_dir, juce_dir, and setup state.
#
# Usage:
#   .\scripts\acp-config.ps1 path
#   .\scripts\acp-config.ps1 get <key>
#   .\scripts\acp-config.ps1 set <key> <value>
#   .\scripts\acp-config.ps1 is-setup
#   .\scripts\acp-config.ps1 plugins-dir
#   .\scripts\acp-config.ps1 juce-dir
#   .\scripts\acp-config.ps1 init

param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1)]
    [string]$Key,

    [Parameter(Position = 2)]
    [string]$Value
)

function Get-AcpConfigPath {
    $base = if ($env:APPDATA) { $env:APPDATA } else { $env:USERPROFILE }
    Join-Path $base "acp\config.json"
}

function Ensure-AcpConfigDir {
    $dir = Split-Path (Get-AcpConfigPath) -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Initialize-AcpConfig {
    $cfg = Get-AcpConfigPath
    if (-not (Test-Path $cfg)) {
        Ensure-AcpConfigDir
        $default = @{
            version           = 1
            setup_complete    = $false
            setup_at          = $null
            plugins_dir       = $null
            plugins_folder_name = $null
            juce_dir          = $null
        }
        $default | ConvertTo-Json -Depth 3 | Set-Content -Path $cfg -Encoding UTF8
        Write-Host "Created default config at $cfg" -ForegroundColor Green
    }
}

function Get-AcpConfigValue {
    param([string]$k)
    $cfg = Get-AcpConfigPath
    if (-not (Test-Path $cfg)) { return "" }
    try {
        $data = Get-Content $cfg -Raw | ConvertFrom-Json
        $v = $data.$k
        if ($null -eq $v) { return "" }
        return $v.ToString()
    } catch {
        return ""
    }
}

function Set-AcpConfigValue {
    param([string]$k, [string]$v)
    $cfg = Get-AcpConfigPath
    if (-not (Test-Path $cfg)) { Initialize-AcpConfig }
    $data = Get-Content $cfg -Raw | ConvertFrom-Json
    if ($data.PSObject.Properties.Name -contains $k) {
        $data.$k = $v
    } else {
        $data | Add-Member -NotePropertyName $k -NotePropertyValue $v
    }
    $data | ConvertTo-Json -Depth 3 | Set-Content -Path $cfg -Encoding UTF8
}

function Test-AcpSetup {
    $val = Get-AcpConfigValue "setup_complete"
    return ($val -eq "True")
}

switch ($Command) {
    "path"         { Get-AcpConfigPath }
    "get"          {
        if (-not $Key) { Write-Error "Usage: acp-config.ps1 get <key>"; exit 1 }
        Get-AcpConfigValue -k $Key
    }
    "set"          {
        if (-not $Key -or -not $PSBoundParameters.ContainsKey('Value')) {
            Write-Error "Usage: acp-config.ps1 set <key> <value>"; exit 1
        }
        Set-AcpConfigValue -k $Key -v $Value
    }
    "is-setup"     {
        if (Test-AcpSetup) { exit 0 } else { exit 1 }
    }
    "plugins-dir"  { Get-AcpConfigValue -k "plugins_dir" }
    "juce-dir"     { Get-AcpConfigValue -k "juce_dir" }
    "init"         { Initialize-AcpConfig }
    default        {
        Write-Host @"
ACP Config Manager

Commands:
  path           Print the config file path
  get <key>      Get a config value
  set <key> <v>  Set a config value
  is-setup       Exit 0 if setup_complete=true, else exit 1
  plugins-dir    Print plugins_dir (empty if not set)
  juce-dir       Print juce_dir (empty if not set)
  init           Create default config if missing
"@
    }
}
