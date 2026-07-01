#!/bin/bash
# Registers session-to-PID/TTY mapping for codecast daemon process discovery
set -uo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)
[ -z "$SESSION_ID" ] && exit 0

# Walk up to find the claude process PID
CLAUDE_PID=""
CHECK_PID=$PPID
for _ in 1 2 3 4; do
  [ -z "$CHECK_PID" ] || [ "$CHECK_PID" = "1" ] && break
  CMD=$(ps -o comm= -p "$CHECK_PID" 2>/dev/null)
  if echo "$CMD" | grep -qiE 'claude|2\.1\.' 2>/dev/null; then
    CLAUDE_PID=$CHECK_PID
    break
  fi
  CHECK_PID=$(ps -o ppid= -p "$CHECK_PID" 2>/dev/null | tr -d ' ')
done

[ -z "$CLAUDE_PID" ] && exit 0

TTY=$(ps -o tty= -p "$CLAUDE_PID" 2>/dev/null | tr -d ' ')
[ -z "$TTY" ] || [ "$TTY" = "??" ] && exit 0

REGISTRY_DIR="$HOME/.codecast/session-registry"
mkdir -p "$REGISTRY_DIR"
echo "{\"pid\":$CLAUDE_PID,\"tty\":\"$TTY\",\"ts\":$(date +%s),\"term\":\"${TERM_PROGRAM:-unknown}\"}" > "$REGISTRY_DIR/$SESSION_ID.json"
exit 0
