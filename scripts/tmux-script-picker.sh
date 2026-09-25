#!/usr/bin/env bash
# tmux-script-picker.sh — fzf picker to run a script from ~/scripts
set -euo pipefail

FZF=/home/linuxbrew/.linuxbrew/bin/fzf
SCRIPTS_DIR="${HOME}/scripts"

script=$(ls -1 "$SCRIPTS_DIR" | $FZF --prompt="run script> ") || exit 0

echo ">> ${SCRIPTS_DIR}/${script}"
"${SCRIPTS_DIR}/${script}"
status=$?

echo
echo "[exit ${status}] press any key to close..."
read -n 1 -s
