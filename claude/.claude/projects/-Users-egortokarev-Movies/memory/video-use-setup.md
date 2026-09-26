---
name: video-use-setup
description: "video-use is installed at ~/Developer/video-use; its helpers must run with the repo's .venv python, not system python."
metadata: 
  node_type: memory
  type: project
  originSessionId: e2758f7f-144c-41e5-8125-1a34ce0847ac
---

video-use (github.com/browser-use/video-use) is installed at `~/Developer/video-use` and
registered as a Claude Code skill via symlink at `~/.claude/skills/video-use`.

Run helpers with the repo venv, NOT bare `python`:
`~/Developer/video-use/.venv/bin/python ~/Developer/video-use/helpers/<name>.py ...`
(equivalently `uv run --directory ~/Developer/video-use helpers/<name>.py`)

**Why:** SKILL.md documents helpers as `python helpers/x.py`, but system python is Homebrew
3.14 and is externally managed with none of the deps. Worse, `pip install -e .` on 3.14 fails:
pyproject declares `librosa`, which needs `numba`, which has no 3.14 wheels. The venv is
pinned to Python 3.12 so the full dependency set resolves. (librosa/matplotlib are declared
but never actually imported — timeline_view.py parses WAV manually to avoid librosa as a hard dep.)

**How to apply:** If a helper dies with ModuleNotFoundError, you used the wrong interpreter —
switch to the venv path above. Don't "fix" it by pip-installing into system python.

Known quirk: `timeline_view.py <video> <start> <end>` fails with a CalledProcessError if `end`
equals the clip's exact duration — it seeks one frame past the last decodable frame. Pass an
end a bit inside the clip (e.g. duration - 0.1).

Related: [[elevenlabs-key-location]]
