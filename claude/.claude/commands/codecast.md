---
description: Get codecast dashboard and share links for current session (user)
allowed-tools: ["Bash"]
---

Run this command to get codecast links for the current session:

```bash
cast links
```

The output shows:
- **Session**: Title or identifier of the found session
- **Dashboard**: URL to view the session on codecast.sh
- **Share**: URL to share with others

IMPORTANT: Verify the "Session:" line matches this conversation's topic. If it shows a different/old session, tell the user to try `cast links -s <session-id>` with the correct session ID from `ls ~/.claude/projects/*/`.

Note: If the session hasn't been synced yet, this command will automatically sync it first.
