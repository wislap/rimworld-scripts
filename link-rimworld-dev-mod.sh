#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspace_root="$(cd "$script_dir/.." && pwd)"
game_root="${RIMWORLD_GAME_ROOT:-/mnt/f_disk/SteamLibrary/steamapps/common/RimWorld}"
source_root="$workspace_root/NekoRimWorld"
link_path="$game_root/Mods/NekoRimWorldDev"

[[ -d "$source_root" ]] || { echo "development mod source is missing: $source_root" >&2; exit 1; }
[[ -d "$game_root/Mods" ]] || { echo "RimWorld Mods directory is missing: $game_root/Mods" >&2; exit 1; }

if [[ -e "$link_path" && ! -L "$link_path" ]]; then
  echo "refusing to replace existing non-symlink path: $link_path" >&2
  exit 1
fi

ln -sfn "$source_root" "$link_path"
echo "Linked $link_path -> $source_root"
