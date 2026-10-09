#!/usr/bin/env bash
# Run once on the Mac. Installs a launchd agent that keeps
# meshclaw-notify-listener.sh running (restarts it on exit and at login).
#
# Usage:   ~/dotfiles/scripts/meshclaw-notify-install.sh [dev-desktop-host]
# Logs:    ~/Library/Logs/meshclaw-notify.log
# Remove:  launchctl bootout gui/$(id -u)/com.alainlam.meshclaw-notify
#          rm ~/Library/LaunchAgents/com.alainlam.meshclaw-notify.plist

set -euo pipefail

LABEL="com.alainlam.meshclaw-notify"
HOST="${1:-dev-dsk-alainlam-2a-d7febfa4.us-west-2.amazon.com}"
SCRIPT="$(cd "$(dirname "$0")" && pwd)/meshclaw-notify-listener.sh"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/meshclaw-notify.log"

[[ "$(uname)" == "Darwin" ]] || { echo "Run this on your Mac." >&2; exit 1; }
chmod +x "$SCRIPT"

# Check SSH works non-interactively before installing.
if ! ssh -o BatchMode=yes -o ConnectTimeout=15 "$HOST" 'test -f ~/.meshclaw/notifications.jsonl'; then
  echo "Cannot SSH to $HOST non-interactively, or notifications.jsonl is missing." >&2
  echo "Run 'mwinit' and try again." >&2
  exit 1
fi

mkdir -p "$(dirname "$PLIST")" "$(dirname "$LOG")"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$SCRIPT</string>
    <string>$HOST</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>15</integer>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed $LABEL -> $HOST"
echo "Tail logs: tail -f $LOG"
