[CmdletBinding()]
param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$EnvironmentRoot = Split-Path -Parent $PSScriptRoot
$SmokeProject = Join-Path $EnvironmentRoot "RimWorldMod\NekoRimWorld\Tests\BridgeSmoke\BridgeSmoke.csproj"

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "dotnet is not available on PATH"
}
if (-not (Test-Path -LiteralPath $SmokeProject)) {
    throw "Bridge smoke project not found: $SmokeProject"
}

& dotnet restore $SmokeProject --locked-mode --nologo
if ($LASTEXITCODE -ne 0) {
    throw "Bridge smoke restore failed with exit code $LASTEXITCODE"
}

& dotnet run --project $SmokeProject --configuration $Configuration --no-restore --nologo
if ($LASTEXITCODE -ne 0) {
    throw "Bridge smoke tests failed with exit code $LASTEXITCODE"
}
