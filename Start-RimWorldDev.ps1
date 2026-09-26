[CmdletBinding()]
param(
    [string]$GameRoot = "F:\SteamLibrary\steamapps\common\RimWorld",
    [switch]$SkipBuild,
    [switch]$NoQuickTest
)

$ErrorActionPreference = "Stop"
$EnvironmentRoot = Split-Path -Parent $PSScriptRoot
$Executable = Join-Path $GameRoot "RimWorldWin64.exe"
$DevDataRoot = Join-Path $EnvironmentRoot ".rimworld-dev-data"

if (-not (Test-Path -LiteralPath $Executable)) {
    throw "RimWorld executable is missing: $Executable"
}
if (-not (Test-Path -LiteralPath $DevDataRoot)) {
    throw "Isolated RimWorld data directory is missing: $DevDataRoot"
}

if (-not $SkipBuild) {
    & (Join-Path $PSScriptRoot "Build-RimWorldMod.ps1")
}
& (Join-Path $PSScriptRoot "Link-RimWorldDevMod.ps1") -GameRoot $GameRoot

$LaunchArguments = @(
    "-savedatafolder=`"$DevDataRoot`"",
    "-popupwindow"
)
if (-not $NoQuickTest) {
    $LaunchArguments += "-quicktest"
}

# RimWorld is the requested interactive application, so it is intentionally
# launched as a visible window.
Start-Process -FilePath $Executable -ArgumentList $LaunchArguments -WorkingDirectory $GameRoot
Write-Output "Started RimWorld with isolated data: $DevDataRoot"
