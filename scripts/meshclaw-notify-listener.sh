#!/usr/bin/env bash
# Runs on the Mac. Streams MeshClaw notifications from the dev desktop and
# bumps the sketchybar `meshclaw` badge for each new one.
#
# Usage: meshclaw-notify-listener.sh [dev-desktop-host]
# Normally started by launchd (see meshclaw-notify-install.sh).

set -u

HOST="${1:-${MESHCLAW_HOST:-dev-dsk-alainlam-2a-d7febfa4.us-west-2.amazon.com}}"
REMOTE_FILE="${MESHCLAW_REMOTE_FILE:-~/.meshclaw/notifications.jsonl}"
STATE_DIR="$HOME/.local/state/meshclaw"
COUNT_FILE="$STATE_DIR/unread"
RETRY_SECS=15

# launchd starts with a minimal PATH; sketchybar lives in Homebrew.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

mkdir -p "$STATE_DIR"
[[ -f "$COUNT_FILE" ]] || echo 0 > "$COUNT_FILE"

log() { printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$*"; }

bump() {
  local n
  n=$(cat "$COUNT_FILE" 2>/dev/null)
  [[ "$n" =~ ^[0-9]+$ ]] || n=0
  echo $((n + 1)) > "$COUNT_FILE"
  sketchybar --trigger meshclaw_notify >/dev/null 2>&1 || true
}

while true; do
  log "connecting to $HOST"
  # -n0: only new lines, so a reconnect doesn't replay old notifications.
  # BatchMode: fail fast (and retry) instead of hanging on an auth prompt
  # when the Midway SSH cert has expired -- re-run `mwinit` to recover.
  ssh -o BatchMode=yes \
      -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
      -o ConnectTimeout=15 \
      "$HOST" "tail -n0 -F $REMOTE_FILE" |
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    log "notification: ${line:0:120}"
    bump
  done
  log "stream ended (exit ${PIPESTATUS[0]}); retrying in ${RETRY_SECS}s"
  sleep "$RETRY_SECS"
done
