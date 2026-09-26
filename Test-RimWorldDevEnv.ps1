[CmdletBinding()]
param(
    [string]$GameRoot = "F:\SteamLibrary\steamapps\common\RimWorld",
    [switch]$SkipBuild,
    [switch]$SkipBridgeSmoke
)

$ErrorActionPreference = "Stop"
$EnvironmentRoot = Split-Path -Parent $PSScriptRoot
$ModRoot = Join-Path $EnvironmentRoot "RimWorldMod\NekoRimWorld"
$ProjectPath = Join-Path $ModRoot "Source\NekoRimWorld.csproj"
$AssemblyPath = Join-Path $ModRoot "1.6\Assemblies\NekoRimWorld.dll"
$DevConfig = Join-Path $EnvironmentRoot ".rimworld-dev-data\Config\ModsConfig.xml"
$GameVersionPath = Join-Path $GameRoot "Version.txt"
$LinkPath = Join-Path $GameRoot "Mods\NekoRimWorldDev"

foreach ($RequiredPath in @(
    $ProjectPath,
    (Join-Path $ModRoot "About\About.xml"),
    $DevConfig,
    $GameVersionPath
)) {
    if (-not (Test-Path -LiteralPath $RequiredPath)) {
        throw "Required development path is missing: $RequiredPath"
    }
}

[xml]$Manifest = Get-Content -Raw -LiteralPath (Join-Path $ModRoot "About\About.xml")
if ($Manifest.ModMetaData.packageId -ne "neko.rimworld.bridge") {
    throw "Unexpected RimWorld packageId"
}

[xml]$ModConfig = Get-Content -Raw -LiteralPath $DevConfig
$ActiveMods = @($ModConfig.ModsConfigData.activeMods.li | ForEach-Object { [string]$_ })
$ExpectedMods = @(
    "brrainz.harmony",
    "ludeon.rimworld",
    "ludeon.rimworld.royalty",
    "ludeon.rimworld.ideology",
    "ludeon.rimworld.biotech",
    "ludeon.rimworld.anomaly",
    "ludeon.rimworld.odyssey",
    "neko.rimworld.bridge"
)
if (($ActiveMods -join "`n") -ne ($ExpectedMods -join "`n")) {
    throw "Isolated ModsConfig.xml does not match the clean development list"
}

if (-not $SkipBuild) {
    & (Join-Path $PSScriptRoot "Build-RimWorldMod.ps1")
}
if (-not (Test-Path -LiteralPath $AssemblyPath)) {
    throw "Compiled assembly is missing: $AssemblyPath"
}

if (-not $SkipBridgeSmoke) {
    & (Join-Path $PSScriptRoot "Test-RimWorldBridge.ps1")
}

& (Join-Path $PSScriptRoot "Link-RimWorldDevMod.ps1") -GameRoot $GameRoot
$Linked = Get-Item -Force -LiteralPath $LinkPath
if ($Linked.LinkType -ne "Junction") {
    throw "Development mod path is not a junction: $LinkPath"
}

Write-Output "RimWorld version file: $((Get-Content -Raw -LiteralPath $GameVersionPath).Trim())"
Write-Output "Active development mods: $($ActiveMods.Count)"
Write-Output "Assembly: $AssemblyPath"
Write-Output "Junction: $LinkPath -> $(@($Linked.Target)[0])"
Write-Output "Development environment verification passed"
