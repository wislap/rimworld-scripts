#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../N.E.K.O" && pwd)"

command -v uv >/dev/null || { echo "uv is not available on PATH" >&2; exit 1; }
cd "$repo_root"
exec uv run --locked --python 3.11 python launcher.py "$@"
