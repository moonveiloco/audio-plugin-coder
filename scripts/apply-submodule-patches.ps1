# APC Submodule Patch Applicator (Windows)
# Idempotently applies patches from patches\<SubModuleName>\*.patch onto the
# matching submodule working tree at _tools\<SubModuleName>.
#
# Generic: works for any submodule that has a patches\<name>\ directory.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\scripts\apply-submodule-patches.ps1              # apply all
#   powershell -ExecutionPolicy Bypass -File .\scripts\apply-submodule-patches.ps1 -Name JIVE   # apply one submodule's patches

param(
    [string]$Name = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = Split-Path -Parent $ScriptDir
$PatchesDir = Join-Path $RootPath "patches"

if (-not (Test-Path $PatchesDir)) {
    Write-Host "No patches/ directory - nothing to apply."
    exit 0
}

if ($Name -ne "") {
    $Targets = @($Name)
}
else {
    $Targets = @(Get-ChildItem -Path $PatchesDir -Directory | ForEach-Object { $_.Name })
}

if ($Targets.Count -eq 0) {
    Write-Host "No patch sets found in $PatchesDir - nothing to apply."
    exit 0
}

$Applied = 0
$Skipped = 0
$Missing = 0

foreach ($target in $Targets) {
    $Submodule = Join-Path $RootPath "_tools\$target"

    if (-not (Test-Path (Join-Path $Submodule ".git"))) {
        Write-Host "SKIP: _tools/$target not initialised (run: git submodule update --init _tools/$target)"
        $Missing++
        continue
    }

    $PatchList = @(Get-ChildItem -Path (Join-Path $PatchesDir $target) -Filter "*.patch" -ErrorAction SilentlyContinue)

    foreach ($patch in $PatchList) {
        $base = $patch.Name

        git -C $Submodule apply --reverse --check --quiet $patch.FullName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SKIP: $target/$base already applied"
            $Skipped++
            continue
        }

        git -C $Submodule apply --check --quiet $patch.FullName 2>$null
        if ($LASTEXITCODE -eq 0) {
            git -C $Submodule apply $patch.FullName
            Write-Host "APPLIED: $target/$base"
            $Applied++
        }
        else {
            Write-Error "ERROR: $target/$base does not apply - _tools/$target changed upstream. Re-generate the patch or update the pin. See agents/rules/*.md for the protocol."
            exit 1
        }
    }
}

Write-Host "Submodule patches: $Applied applied, $Skipped already applied, $Missing submodules missing."
