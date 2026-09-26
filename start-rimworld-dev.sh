#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspace_root="$(cd "$script_dir/.." && pwd)"
game_root="${RIMWORLD_GAME_ROOT:-/mnt/f_disk/SteamLibrary/steamapps/common/RimWorld}"
executable="$game_root/RimWorldLinux"
data_root="$workspace_root/.rimworld-dev-data"
skip_build=0
quicktest=1

for arg in "$@"; do
  case "$arg" in
    --skip-build) skip_build=1 ;;
    --no-quicktest) quicktest=0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

[[ -x "$executable" ]] || { echo "RimWorld Linux executable is missing: $executable" >&2; exit 1; }
[[ -d "$data_root" ]] || { echo "isolated RimWorld data directory is missing: $data_root" >&2; exit 1; }

if (( ! skip_build )); then
  "$script_dir/build-rimworld-mod.sh" Debug
fi
"$script_dir/link-rimworld-dev-mod.sh"

args=("-savedatafolder=$data_root" "-popupwindow")
if (( quicktest )); then
  args+=("-quicktest")
fi

cd "$game_root"
exec env LC_ALL=C "$executable" "${args[@]}"
