# APC Config Manager (Windows / PowerShell)
# Reads/writes the global APC configuration.
# Single source of truth for plugins_dir, juce_dir, and setup state.
#
# Usage:
#   .\scripts\apc-config.ps1 path
#   .\scripts\apc-config.ps1 get <key>
#   .\scripts\apc-config.ps1 set <key> <value>
#   .\scripts\apc-config.ps1 is-setup
#   .\scripts\apc-config.ps1 plugins-dir    # exit 1 if unset
#   .\scripts\apc-config.ps1 juce-dir       # exit 1 if unset
#   .\scripts\apc-config.ps1 init

param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1)]
    [string]$Key,

    [Parameter(Position = 2)]
    [string]$Value
)

function Get-ApcConfigPath {
    $base = if ($env:APPDATA) { $env:APPDATA } else { $env:USERPROFILE }
    Join-Path $base "apc\config.json"
}

function Ensure-ApcConfigDir {
    $dir = Split-Path (Get-ApcConfigPath) -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Initialize-ApcConfig {
    $cfg = Get-ApcConfigPath
    if (-not (Test-Path $cfg)) {
        Ensure-ApcConfigDir
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

function Get-ApcConfigValue {
    param([string]$k)
    $cfg = Get-ApcConfigPath
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

function Set-ApcConfigValue {
    param([string]$k, [string]$v)
    $cfg = Get-ApcConfigPath
    if (-not (Test-Path $cfg)) { Initialize-ApcConfig }
    $data = Get-Content $cfg -Raw | ConvertFrom-Json
    if ($data.PSObject.Properties.Name -contains $k) {
        $data.$k = $v
    } else {
        $data | Add-Member -NotePropertyName $k -NotePropertyValue $v
    }
    $data | ConvertTo-Json -Depth 3 | Set-Content -Path $cfg -Encoding UTF8
}

function Test-ApcSetup {
    $val = Get-ApcConfigValue "setup_complete"
    return ($val -eq "True")
}

switch ($Command) {
    "path"         { Get-ApcConfigPath }
    "get"          {
        if (-not $Key) { Write-Error "Usage: apc-config.ps1 get <key>"; exit 1 }
        Get-ApcConfigValue -k $Key
    }
    "set"          {
        if (-not $Key -or -not $PSBoundParameters.ContainsKey('Value')) {
            Write-Error "Usage: apc-config.ps1 set <key> <value>"; exit 1
        }
        Set-ApcConfigValue -k $Key -v $Value
    }
    "is-setup"     {
        if (Test-ApcSetup) { exit 0 } else { exit 1 }
    }
    "plugins-dir"  {
        $v = Get-ApcConfigValue -k "plugins_dir"
        if ([string]::IsNullOrWhiteSpace($v)) {
            Write-Error "APC not configured: plugins_dir is null. Run /setup first."
            exit 1
        }
        $v
    }
    "juce-dir"     {
        $v = Get-ApcConfigValue -k "juce_dir"
        if ([string]::IsNullOrWhiteSpace($v)) {
            Write-Error "APC not configured: juce_dir is null. Run /setup first."
            exit 1
        }
        $v
    }
    "init"         { Initialize-ApcConfig }
    default        {
        Write-Host @"
APC Config Manager

Commands:
  path           Print the config file path
  get <key>      Get a config value
  set <key> <v>  Set a config value
  is-setup       Exit 0 if setup_complete=true, else exit 1
  plugins-dir    Print plugins_dir (exit 1 + stderr if unset)
  juce-dir       Print juce_dir (exit 1 + stderr if unset)
  init           Create default config if missing
"@
    }
}
