#!/bin/sh
# Block until something finishes, for at most ~9 minutes (one tool call), then print one status line.
#   wait.sh pid <pid>                 until the process exits
#   wait.sh file <path> <regex>       until a line matching <regex> appears in <path>
#   wait.sh checks <pr-number|url>    until the PR's CI checks finish (run inside the repo)
# Exit 0 = finished, 3 = still running after the time limit (call it again).
limit=540
start=$(date +%s)
left() { echo $(( limit - ($(date +%s) - start) )); }

case "$1" in
  pid)
    while kill -0 "$2" 2>/dev/null; do
      [ "$(left)" -le 0 ] && { echo "still running: pid $2"; exit 3; }
      sleep 10
    done
    echo "finished: pid $2"
    ;;
  file)
    while ! grep -Eq -- "$3" "$2" 2>/dev/null; do
      [ "$(left)" -le 0 ] && { echo "still waiting: no /$3/ in $2"; exit 3; }
      sleep 10
    done
    echo "finished: $(grep -E -- "$3" "$2" | tail -n 1)"
    ;;
  checks)
    timeout "$limit" gh pr checks "$2" --watch --interval 60 >/dev/null 2>&1
    rc=$?
    if [ "$rc" -eq 124 ]; then
      echo "still running: checks on $2"
      exit 3
    fi
    gh pr checks "$2" 2>&1 | awk -F'\t' '{print $1": "$2}' | paste -sd ' ' -
    ;;
  *)
    sed -n '2,7p' "$0"
    exit 2
    ;;
esac
