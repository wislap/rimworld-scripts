[CmdletBinding()]
param(
    [string]$GameRoot = "F:\SteamLibrary\steamapps\common\RimWorld"
)

$ErrorActionPreference = "Stop"
$EnvironmentRoot = Split-Path -Parent $PSScriptRoot
$SourceRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $EnvironmentRoot "RimWorldMod\NekoRimWorld")
)
$ModsRoot = Join-Path $GameRoot "Mods"
$LinkPath = Join-Path $ModsRoot "NekoRimWorldDev"

if (-not (Test-Path -LiteralPath $SourceRoot)) {
    throw "Development mod source is missing: $SourceRoot"
}
if (-not (Test-Path -LiteralPath $ModsRoot)) {
    throw "RimWorld Mods directory is missing: $ModsRoot"
}

if (Test-Path -LiteralPath $LinkPath) {
    $Existing = Get-Item -Force -LiteralPath $LinkPath
    $ExistingTarget = @($Existing.Target) | Select-Object -First 1
    if ($Existing.LinkType -ne "Junction" -or -not $ExistingTarget) {
        throw "Refusing to replace existing non-junction path: $LinkPath"
    }
    $ResolvedTarget = [System.IO.Path]::GetFullPath([string]$ExistingTarget)
    if ($ResolvedTarget -ne $SourceRoot) {
        throw "Refusing to replace junction with another target: $LinkPath -> $ResolvedTarget"
    }
    Write-Output "Development junction already correct: $LinkPath -> $SourceRoot"
    exit 0
}

New-Item -ItemType Junction -Path $LinkPath -Target $SourceRoot | Out-Null
Write-Output "Created development junction: $LinkPath -> $SourceRoot"
