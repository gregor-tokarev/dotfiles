#!/bin/bash
# Reports Claude Code lifecycle events to codecast daemon via status files
set -uo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null)
[ -z "$SESSION_ID" ] && exit 0

EVENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('hook_event_name',''))" 2>/dev/null)
NOTIF_TYPE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('notification_type',''))" 2>/dev/null)
SOURCE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('source',''))" 2>/dev/null)
PERM_MODE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('permission_mode',''))" 2>/dev/null)

if [ "$EVENT" = "PreToolUse" ] || [ "$EVENT" = "PermissionRequest" ]; then
  echo "$INPUT" | CC_SID="$SESSION_ID" python3 -c "
import sys, json, os, tempfile, time
try:
    d = json.load(sys.stdin)
    if d.get('tool_name') == 'AskUserQuestion':
        qs = (d.get('tool_input') or {}).get('questions')
        if qs:
            dd = os.path.join(os.path.expanduser('~'), '.codecast', 'ask-input')
            os.makedirs(dd, exist_ok=True)
            fd, tmp = tempfile.mkstemp(dir=dd)
            with os.fdopen(fd, 'w') as f:
                json.dump({'questions': qs, 'ts': int(time.time())}, f)
            os.replace(tmp, os.path.join(dd, os.environ['CC_SID'] + '.json'))
except Exception:
    pass
" 2>/dev/null
fi

STATUS=""
EXTRA=""
case "$EVENT" in
  UserPromptSubmit) STATUS="thinking" ;;
  PreToolUse)
    TOOL=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
    if [ "$TOOL" = "AskUserQuestion" ]; then
      STATUS="permission_blocked"
      EXTRA=',"message":"AskUserQuestion"'
    else
      STATUS="working"
    fi
    ;;
  PreCompact) STATUS="compacting" ;;
  Stop) STATUS="idle" ;;
  PermissionRequest)
    TOOL=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
    if [ -n "$TOOL" ]; then
      STATUS="permission_blocked"
      EXTRA=$(echo "$INPUT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
ti=d.get('tool_input') or {}
prev=''
for k in ('command','file_path','pattern','path','url'):
    v=ti.get(k)
    if isinstance(v,str) and v:
        prev=v
        break
tool=d.get('tool_name','')
msg=tool if not prev else tool+': '+prev
print(','+json.dumps({'message':msg[:300]})[1:-1])
" 2>/dev/null)
    fi
    ;;
  Notification)
    case "$NOTIF_TYPE" in
      permission_prompt)
        STATUS="permission_blocked"
        EXTRA=$(echo "$INPUT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
t=d.get('transcript_path','')
print((','+json.dumps({'transcript_path':t})[1:-1]) if t else '')
" 2>/dev/null)
        ;;
      idle_prompt) STATUS="idle" ;;
    esac
    ;;
  SessionStart)
    [ "$SOURCE" = "compact" ] && STATUS="working"
    ;;
esac

[ -z "$STATUS" ] && exit 0

TS=$(date +%s)
HOOK_PORT_FILE="$HOME/.codecast/hook-port"
if [ -f "$HOOK_PORT_FILE" ]; then
  PORT=$(cat "$HOOK_PORT_FILE" 2>/dev/null)
  if [ -n "$PORT" ]; then
    URL="http://127.0.0.1:$PORT/hook/status?session_id=$SESSION_ID&status=$STATUS&ts=$TS"
    [ -n "$PERM_MODE" ] && URL="$URL&permission_mode=$PERM_MODE"

    if [ -n "$EXTRA" ]; then
      MSG=$(echo "$EXTRA" | python3 -c "import sys,json; d=json.loads('{'+sys.stdin.read().lstrip(',')+'}'); print(d.get('message',''))" 2>/dev/null)
      TP=$(echo "$EXTRA" | python3 -c "import sys,json; d=json.loads('{'+sys.stdin.read().lstrip(',')+'}'); print(d.get('transcript_path',''))" 2>/dev/null)
      [ -n "$MSG" ] && URL="$URL&message=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$MSG" 2>/dev/null)"
      [ -n "$TP" ] && URL="$URL&transcript_path=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$TP" 2>/dev/null)"
    fi

    curl -sG "$URL" --connect-timeout 1 --max-time 2 >/dev/null 2>&1 && exit 0
  fi
fi

STATUS_DIR="$HOME/.codecast/agent-status"
mkdir -p "$STATUS_DIR"
CC_STATUS="$STATUS" CC_PERM_MODE="$PERM_MODE" CC_EXTRA="$EXTRA" CC_TS="$TS" python3 -c "
import json, os
d = {'status': os.environ['CC_STATUS'], 'ts': int(os.environ['CC_TS'])}
pm = os.environ.get('CC_PERM_MODE', '')
if pm: d['permission_mode'] = pm
ex = os.environ.get('CC_EXTRA', '')
if ex:
    try:
        parsed = json.loads('{' + ex.lstrip(',') + '}')
        d.update(parsed)
    except Exception:
        pass
print(json.dumps(d))
" > "$STATUS_DIR/$SESSION_ID.json"
exit 0
