#!/bin/bash
# Periodic task/plan reminder - emits a short nudge every N user messages
set -uo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)
[ -z "$SESSION_ID" ] && exit 0

PULSE_FILE="$HOME/.codecast/task-pulse/$SESSION_ID.json"
[ -f "$PULSE_FILE" ] || exit 0

COUNTER_DIR="$HOME/.codecast/task-pulse/counters"
mkdir -p "$COUNTER_DIR"
COUNTER_FILE="$COUNTER_DIR/$SESSION_ID"
COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE")
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# Emit every 8 turns
[ $((COUNT % 8)) -ne 0 ] && exit 0

TASK=$(python3 -c "import sys,json; d=json.load(open('$PULSE_FILE')); parts=[]; t=d.get('task',''); p=d.get('plan','');
[t and parts.append('task '+t), p and parts.append('plan '+p)]; print(', '.join(parts))" 2>/dev/null)
[ -z "$TASK" ] && exit 0

echo "<task-reminder>You are working on $TASK. Check progress against acceptance criteria.</task-reminder>"
