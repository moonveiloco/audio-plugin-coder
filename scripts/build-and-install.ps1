<#
.SYNOPSIS
    APC Master Builder with Enhanced Error Detection and Testing
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$PluginName,
    [switch]$NoInstall,
    [switch]$SkipTests,
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

# Import required modules
. "$PSScriptRoot\state-management.ps1"
. "$PSScriptRoot\error-detection.ps1"
. "$PSScriptRoot\terminal-monitoring.ps1"
. "$PSScriptRoot\pluginval-integration.ps1"

$RootPath = (Get-Item "$PSScriptRoot\..").FullName
$BuildDir = "$RootPath\build"
$ApcPluginsDir = & "$PSScriptRoot\acp-config.ps1" plugins-dir
if ($LASTEXITCODE -ne 0) { Write-Error "Run /setup first."; exit 1 }
if (Test-Path "$ApcPluginsDir\$PluginName") {
    $PluginDir = "$ApcPluginsDir\$PluginName"
} else {
    $PluginDir = "$RootPath\plugins\$PluginName"
}
$StatusJson = "$PluginDir\status.json"
$UseVisage = $false
$BuildStart = Get-Date

if (Test-Path $StatusJson) {
    try {
        $state = Get-Content $StatusJson -Raw | ConvertFrom-Json
        if ($state.ui_framework -eq "visage") {
            $UseVisage = $true
        }
    } catch {
        Write-Warning "Could not read status.json; proceeding without framework hints."
    }
}

Write-Host "--- APC BUILDER: $PluginName ---" -ForegroundColor Cyan
if ($UseVisage) {
    Write-Host "Framework: visage" -ForegroundColor DarkGray
}

# Validate prerequisites
$state = Get-PluginState -PluginPath $PluginDir
if ($state.current_phase -ne "code_complete" -and -not $SkipTests) {
    Write-Warning "Plugin implementation not marked as complete. Use -SkipTests to override."
}

# 1. Configure with error monitoring
Write-Host "Configuring build..." -ForegroundColor Yellow
$visageFlag = if ($UseVisage) { "-DAPC_ENABLE_VISAGE:BOOL=ON" } else { "" }
$configureCommand = "cmake -S `"$RootPath`" -B `"$BuildDir`" -G `"Visual Studio 17 2022`" -A x64 --fresh $visageFlag"
$configResult = Invoke-MonitoredCommand -Command $configureCommand -ShowOutput -ThrowOnError

if ($configResult.Errors.Count -gt 0) {
    Write-Host "Configuration warnings detected" -ForegroundColor Yellow
    $knownIssue = Find-KnownIssue -Errors $configResult.Errors
    if ($knownIssue) {
        Write-Host "Known configuration issue detected: $($knownIssue.Title)" -ForegroundColor Cyan
        Apply-KnownSolution -Issue $knownIssue
        # Retry configuration
        $configResult = Invoke-MonitoredCommand -Command $configureCommand -ShowOutput -ThrowOnError
    }
}

# 2. Build VST3 with error monitoring
Write-Host "Compiling VST3..." -ForegroundColor Yellow
$buildVst3Command = "cmake --build `"$BuildDir`" --config Release --target `"$($PluginName)_VST3`""
$vst3Result = Invoke-MonitoredCommand -Command $buildVst3Command -ShowOutput -ThrowOnError

if ($vst3Result.Errors.Count -gt 0) {
    Write-Host "VST3 build errors detected" -ForegroundColor Red

    # Check for known issues
    $knownIssue = Find-KnownIssue -Errors $vst3Result.Errors
    if ($knownIssue) {
        Write-Host "Known issue detected: $($knownIssue.Title)" -ForegroundColor Cyan
        Apply-KnownSolution -Issue $knownIssue
        # Retry build
        $vst3Result = Invoke-MonitoredCommand -Command $buildVst3Command -ShowOutput -ThrowOnError
    }

    # If still failing, auto-capture new issue
    if ($vst3Result.Errors.Count -gt 0) {
        New-IssueFromError -Errors $vst3Result.Errors -BuildOutput $vst3Result.Output
        throw "VST3 build failed - issue logged for investigation"
    }
}

# 3. Build Standalone with error monitoring
Write-Host "Compiling Standalone..." -ForegroundColor Yellow
$buildStandaloneCommand = "cmake --build `"$BuildDir`" --config Release --target `"$($PluginName)_Standalone`""
$standaloneResult = Invoke-MonitoredCommand -Command $buildStandaloneCommand -ShowOutput -ThrowOnError

if ($standaloneResult.Errors.Count -gt 0) {
    Write-Host "Standalone build errors detected" -ForegroundColor Red

    # Check for known issues
    $knownIssue = Find-KnownIssue -Errors $standaloneResult.Errors
    if ($knownIssue) {
        Write-Host "Known issue detected: $($knownIssue.Title)" -ForegroundColor Cyan
        Apply-KnownSolution -Issue $knownIssue
        # Retry build
        $standaloneResult = Invoke-MonitoredCommand -Command $buildStandaloneCommand -ShowOutput -ThrowOnError
    }

    # If still failing, auto-capture new issue
    if ($standaloneResult.Errors.Count -gt 0) {
        New-IssueFromError -Errors $standaloneResult.Errors -BuildOutput $standaloneResult.Output
        throw "Standalone build failed - issue logged for investigation"
    }
}

# 4. Run PluginVal tests
if (-not $SkipTests) {
    Write-Host "Running PluginVal validation..." -ForegroundColor Yellow

    # Find the built VST3 plugin
    $vst3Path = Get-ChildItem -Path "$BuildDir" -Recurse -Filter "$PluginName.vst3" | Select-Object -First 1
    if ($vst3Path) {
        $pluginvalResult = Test-WithPluginVal -PluginPath $vst3Path.FullName -PluginName $PluginName -Strict:$Strict

        if (-not $pluginvalResult.Passed -and -not $pluginvalResult.Skipped) {
            Write-Host "PluginVal tests failed" -ForegroundColor Red
            if ($Strict) {
                throw "PluginVal validation failed in strict mode"
            } else {
                Write-Warning "PluginVal tests failed - proceeding with installation anyway"
            }
        }
    } else {
        Write-Warning "VST3 plugin not found for PluginVal testing"
    }
}

# 5. Install VST3
if (-not $NoInstall) {
    Write-Host "Installing VST3..." -ForegroundColor Yellow
    $Vst = Get-ChildItem -Path "$BuildDir" -Recurse -Filter "$($PluginName).vst3" | Select-Object -First 1
    if ($Vst) {
        $Dest = "C:\Program Files\Common Files\VST3\$($Vst.Name)"
        try {
            if (Test-Path $Dest) { Remove-Item -Path $Dest -Recurse -Force -ErrorAction SilentlyContinue }
            Copy-Item -Path $Vst.FullName -Destination $Dest -Recurse -Force
            Write-Host "INSTALLED VST3 to: $Dest" -ForegroundColor Green
        } catch {
            Write-Warning "Access Denied. Run as Admin to install VST3."
        }
    }

    # Locate Standalone
    $Exe = Get-ChildItem -Path "$BuildDir" -Recurse -Filter "$($PluginName).exe" | Select-Object -First 1
    if ($Exe) {
        Write-Host "STANDALONE built at: $($Exe.FullName)" -ForegroundColor Green

        # Add icon to standalone executable
        $IconPath = "$PluginDir\Assets\icon.ico"
        if (Test-Path $IconPath) {
            Write-Host "Adding icon to standalone executable..." -ForegroundColor Yellow
            try {
                & "$PSScriptRoot\add-icon-to-exe.ps1" -ExePath $Exe.FullName -IconPath $IconPath
                Write-Host "[OK] Icon embedded in executable" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to add icon to executable: $_"
            }
        } else {
            Write-Host "No icon found at $IconPath - skipping icon embedding" -ForegroundColor Gray
        }

        Write-Host "Tip: You can run this to bypass VST3 caching issues." -ForegroundColor Cyan
    }
}

# 5.5. Stage artifacts to plugin dir (external plugins only)
$StagedCount = 0
if ($PluginDir -like "$ApcPluginsDir\*") {
    Write-Host "Staging artifacts to plugin directory..." -ForegroundColor Yellow
    $StageDir = Join-Path $PluginDir "build"
    if (Test-Path $StageDir) { Remove-Item $StageDir -Recurse -Force }
    New-Item -ItemType Directory -Path $StageDir -Force | Out-Null

    # VST3
    $vst3Src = Get-ChildItem -Path $BuildDir -Recurse -Directory -Filter "$PluginName.vst3" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "*external\${PluginName}*artefacts\Release\VST3\*" } |
        Select-Object -First 1
    if ($vst3Src) {
        $vst3Dest = Join-Path $StageDir "VST3"
        New-Item -ItemType Directory -Path $vst3Dest -Force | Out-Null
        Copy-Item -Path $vst3Src.FullName -Destination $vst3Dest -Recurse -Force
        $StagedCount++
        Write-Host "STAGED VST3 → $vst3Dest" -ForegroundColor Green
    }

    # AU (not applicable on Windows, but kept for cross-platform consistency)
    # Standalone
    $saSrc = Get-ChildItem -Path $BuildDir -Recurse -Filter "$PluginName.exe" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "*external\${PluginName}*artefacts\Release\Standalone\*" } |
        Select-Object -First 1
    if ($saSrc) {
        $saDest = Join-Path $StageDir "Standalone"
        New-Item -ItemType Directory -Path $saDest -Force | Out-Null
        Copy-Item -Path $saSrc.FullName -Destination $saDest -Recurse -Force
        $StagedCount++
        Write-Host "STAGED Standalone → $saDest" -ForegroundColor Green
    }

    if ($StagedCount -eq 0) {
        Write-Warning "no artifacts staged (no matching bundles found in build cache)"
    }
}

# 6. Update build status (build_info block)
$BuildEnd = Get-Date
$BuildDuration = [int]([math]::Round(($BuildEnd - $BuildStart).TotalSeconds))

if (Test-Path $StatusJson) {
    try {
        $state = Get-Content $StatusJson -Raw | ConvertFrom-Json
    } catch {
        $state = $null
    }

    # Detect JUCE version + compiler
    $juceVersion = "unknown"
    $cacheFile = Join-Path $BuildDir "CMakeCache.txt"
    if (Test-Path $cacheFile) {
        $line = Select-String -Path $cacheFile -Pattern "JUCE_VERSION|juce_version" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($line) { $juceVersion = ($line.Line -replace '.*=\s*','').Trim() }
    }
    $compiler = "unknown"
    try {
        $clOut = (& cl 2>&1 | Select-Object -First 2) -join ' '
        if ($clOut) { $compiler = $clOut.Trim() }
    } catch {}

    # Build artifacts array (only for staged external plugins)
    $artifacts = @()
    if ($PluginDir -like "$ApcPluginsDir\*" -and (Test-Path $StageDir)) {
        foreach ($fmtDir in (Get-ChildItem -Path $StageDir -Directory -ErrorAction SilentlyContinue)) {
            $bundle = Get-ChildItem -Path $fmtDir.FullName -Recurse -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '\.(vst3|component|app|lv2)$' } |
                Select-Object -First 1
            if ($bundle) {
                $size = (Get-ChildItem -Path $bundle.FullName -Recurse -File -ErrorAction SilentlyContinue |
                         Measure-Object -Property Length -Sum).Sum
                if (-not $size) { $size = 0 }
                $rel = "build/$($fmtDir.Name)/$($bundle.Name)"
                $artifacts += [PSCustomObject]@{
                    format = $fmtDir.Name
                    path   = $rel
                    size_bytes = $size
                }
            }
        }
    }

    # Build type string
    $buildType = "VST3"
    if ($PluginDir -like "$ApcPluginsDir\*" -and (Test-Path $StageDir) -and $artifacts.Count -gt 0) {
        $buildType = ($artifacts | ForEach-Object { $_.format }) -join '+'
    }

    $buildStatus = "success"
    $timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")

    if ($state) {
        $buildInfo = [PSCustomObject]@{
            last_build_at = $timestamp
            last_build_status = $buildStatus
            last_build_duration_sec = $BuildDuration
            last_build_type = $buildType
            artifacts = $artifacts
            juce_version = $juceVersion
            compiler = $compiler
        }
        # Attach/replace build_info
        $state | Add-Member -NotePropertyName build_info -NotePropertyValue $buildInfo -Force
        $state.last_modified = $timestamp
        if (-not $state.validation) { $state.validation = [PSCustomObject]@{} }
        $state.validation | Add-Member -NotePropertyName build_completed -NotePropertyValue $true -Force

        $state | ConvertTo-Json -Depth 10 | Set-Content -Path $StatusJson -Encoding UTF8
        Write-Host "Build status updated in $StatusJson" -ForegroundColor Green
    } else {
        # Fallback: legacy 2-field update
        Update-PluginState -PluginPath $PluginDir -Updates @{
            "validation.build_completed" = $true
            "validation.build_timestamp" = $timestamp
        }
    }
} else {
    # Fallback: legacy 2-field update
    Update-PluginState -PluginPath $PluginDir -Updates @{
        "validation.build_completed" = $true
        "validation.build_timestamp" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        "validation.build_errors" = ($vst3Result.Errors + $standaloneResult.Errors).Count
    }
}

Write-Host "Build process complete!" -ForegroundColor Green
