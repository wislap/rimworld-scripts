#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspace_root="$(cd "$script_dir/.." && pwd)"
project="$workspace_root/NekoRimWorld/Source/NekoRimWorld.csproj"
assembly="$workspace_root/NekoRimWorld/1.6/Assemblies/NekoRimWorld.dll"
configuration="${1:-Debug}"

if [[ "$configuration" != "Debug" && "$configuration" != "Release" ]]; then
  echo "usage: $0 [Debug|Release]" >&2
  exit 2
fi

command -v dotnet >/dev/null || { echo "dotnet is not available on PATH" >&2; exit 1; }
[[ -f "$project" ]] || { echo "RimWorld mod project not found: $project" >&2; exit 1; }

DOTNET_CLI_TELEMETRY_OPTOUT=1 dotnet restore "$project" --locked-mode --nologo
DOTNET_CLI_TELEMETRY_OPTOUT=1 dotnet build "$project" --configuration "$configuration" --no-restore --nologo
[[ -f "$assembly" ]] || { echo "build succeeded but assembly is missing: $assembly" >&2; exit 1; }

echo "Built $assembly"
