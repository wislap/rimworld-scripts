[CmdletBinding()]
param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug"
)

$ErrorActionPreference = "Stop"
$EnvironmentRoot = Split-Path -Parent $PSScriptRoot
$ProjectPath = Join-Path $EnvironmentRoot "RimWorldMod\NekoRimWorld\Source\NekoRimWorld.csproj"
$AssemblyPath = Join-Path $EnvironmentRoot "RimWorldMod\NekoRimWorld\1.6\Assemblies\NekoRimWorld.dll"

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "dotnet is not available on PATH"
}
if (-not (Test-Path -LiteralPath $ProjectPath)) {
    throw "RimWorld mod project not found: $ProjectPath"
}

& dotnet restore $ProjectPath --locked-mode --nologo
if ($LASTEXITCODE -ne 0) {
    throw "dotnet restore failed with exit code $LASTEXITCODE"
}

& dotnet build $ProjectPath --configuration $Configuration --no-restore --nologo
if ($LASTEXITCODE -ne 0) {
    throw "dotnet build failed with exit code $LASTEXITCODE"
}
if (-not (Test-Path -LiteralPath $AssemblyPath)) {
    throw "Build succeeded but assembly is missing: $AssemblyPath"
}

Write-Output "Built $AssemblyPath"
