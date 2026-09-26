#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspace_root="$(cd "$script_dir/.." && pwd)"
log_dir="$workspace_root/.dev-logs"
neko_log="$log_dir/neko.log"
plugin_api="http://127.0.0.1:48916"
game_pid=""
needs_session=1

for arg in "$@"; do
  if [[ "$arg" == "--no-quicktest" ]]; then
    needs_session=0
  fi
done

mkdir -p "$log_dir"

command -v curl >/dev/null || { echo "curl is not available on PATH" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is not available on PATH" >&2; exit 1; }

"$script_dir/start-neko.sh" >"$neko_log" 2>&1 &
neko_pid=$!

cleanup() {
  if [[ -n "$game_pid" ]] && kill -0 "$game_pid" 2>/dev/null; then
    kill -TERM "$game_pid" 2>/dev/null || true
  fi
  if kill -0 "$neko_pid" 2>/dev/null; then
    kill -TERM "$neko_pid" 2>/dev/null || true
    wait "$neko_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

for _ in {1..90}; do
  if curl -fsS "$plugin_api/health" >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "$neko_pid" 2>/dev/null; then
    echo "N.E.K.O exited before becoming ready; see $neko_log" >&2
    exit 1
  fi
  sleep 1
done

curl -fsS "$plugin_api/health" >/dev/null || {
  echo "N.E.K.O plugin server did not become ready; see $neko_log" >&2
  exit 1
}
curl -fsS -X POST "$plugin_api/plugins/refresh" >/dev/null
curl -fsS -X POST "$plugin_api/plugin/neko_rimworld/start" >/dev/null

echo "N.E.K.O is ready; log: $neko_log"
echo "Starting RimWorld with the isolated development profile..."
"$script_dir/start-rimworld-dev.sh" "$@" &
game_pid=$!

bridge_ready=0
session_ready=0
for _ in {1..90}; do
  payload=$(curl -fsS "$plugin_api/plugin/neko_rimworld/hosted-ui/context" 2>/dev/null || true)
  if [[ "$(printf '%s' "$payload" | jq -r '.state.connection != null' 2>/dev/null)" == "true" ]]; then
    bridge_ready=1
  fi
  if [[ "$(printf '%s' "$payload" | jq -r '.state.session != null and (.state.session.stale == false)' 2>/dev/null)" == "true" ]]; then
    session_ready=1
  fi
  if (( bridge_ready )) && (( ! needs_session || session_ready )); then
    break
  fi
  if ! kill -0 "$game_pid" 2>/dev/null; then
    echo "RimWorld exited before the bridge became ready" >&2
    wait "$game_pid"
  fi
  sleep 1
done

(( bridge_ready )) || { echo "RimWorld did not authenticate with the plugin" >&2; exit 1; }
if (( needs_session )); then
  (( session_ready )) || { echo "RimWorld did not open a quick-test game session" >&2; exit 1; }
  query_status=$(curl -fsS -X POST -H 'Content-Type: application/json' -d '{"args":{}}' \
    "$plugin_api/plugin/neko_rimworld/hosted-ui/action/probe_game_overview" \
    | jq -r '.result.status // "error"')
  [[ "$query_status" == "ok" ]] || { echo "live colony overview probe failed" >&2; exit 1; }
  echo "Bridge authenticated, game session opened, and live overview query passed."
else
  echo "Bridge authenticated at the RimWorld main menu."
fi

wait "$game_pid"
