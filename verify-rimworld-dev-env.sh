#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspace_root="$(cd "$script_dir/.." && pwd)"
game_root="${RIMWORLD_GAME_ROOT:-/mnt/f_disk/SteamLibrary/steamapps/common/RimWorld}"
mod_root="$workspace_root/RimWorldMod/NekoRimWorld"
mods_config="$workspace_root/.rimworld-dev-data/Config/ModsConfig.xml"
link_path="$game_root/Mods/NekoRimWorldDev"
harmony_root="${RIMWORLD_HARMONY_ROOT:-/mnt/f_disk/SteamLibrary/steamapps/workshop/content/294100/2009463077}"

for required in \
  "$game_root/RimWorldLinux" \
  "$game_root/Version.txt" \
  "$mod_root/About/About.xml" \
  "$mod_root/Source/NekoRimWorld.csproj" \
  "$mods_config" \
  "$harmony_root/About/About.xml"; do
  [[ -e "$required" ]] || { echo "required path is missing: $required" >&2; exit 1; }
done

grep -q '<packageId>neko.rimworld.bridge</packageId>' "$mod_root/About/About.xml"
for package_id in brrainz.harmony ludeon.rimworld neko.rimworld.bridge; do
  grep -q "<li>$package_id</li>" "$mods_config" || {
    echo "isolated ModsConfig.xml is missing $package_id" >&2
    exit 1
  }
done

"$script_dir/build-rimworld-mod.sh" Debug
"$script_dir/test-rimworld-bridge.sh" Release
"$script_dir/link-rimworld-dev-mod.sh"

[[ -L "$link_path" ]] || { echo "development mod link was not created" >&2; exit 1; }
[[ "$(readlink -f "$link_path")" == "$(readlink -f "$mod_root")" ]] || {
  echo "development mod link points to the wrong target" >&2
  exit 1
}

echo "RimWorld version: $(tr -d '\r\n' < "$game_root/Version.txt")"
echo "Build, smoke-test, and link verification passed"
