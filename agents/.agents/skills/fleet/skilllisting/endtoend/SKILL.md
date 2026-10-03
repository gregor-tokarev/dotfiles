---
name: endtoend
description: Only apply when the user asks you to make a feature end to end. Words end to end should be explisitly mentioned in prompt
---

I will not read the output of this work. I want you to carry the changes from the prompt to the main branch. You can ask questions, though, if you really don't know how to unblock yourself.

Implement the requested prompt and test it yourself like a real user would:
- Web apps: drive them in a browser with agent-browser.
- Desktop apps: run them and use them through computer-use, on a virtual display if there is no real one.
- CLIs: run the commands the way a user would.

Then babysit the PR. After all checks pass, ask yourself: "How confident am I that these changes can land in production?"
If you have concerns, illuminate them.

When you think the PR is ready to be merged, merge it yourself.
