#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspace_root="$(cd "$script_dir/.." && pwd)"
project="$workspace_root/NekoRimWorld/Tests/BridgeSmoke/BridgeSmoke.csproj"
configuration="${1:-Release}"
framework="net8.0"

command -v dotnet >/dev/null || { echo "dotnet is not available on PATH" >&2; exit 1; }
[[ -f "$project" ]] || { echo "bridge smoke project not found: $project" >&2; exit 1; }

if command -v mono >/dev/null; then
  framework="net472"
fi

DOTNET_CLI_TELEMETRY_OPTOUT=1 dotnet restore "$project" --locked-mode --nologo
DOTNET_CLI_TELEMETRY_OPTOUT=1 dotnet run --project "$project" --framework "$framework" \
  --configuration "$configuration" --no-restore --nologo
