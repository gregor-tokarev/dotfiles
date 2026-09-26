---
name: minimal-comments
description: User prefers minimal code comments — keep only load-bearing ones
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 97f3808e-e55d-41e4-9d31-6d67f5b02d51
---

The user wants very few code comments — "keep only [the ones] that matter."

**Why:** Comments that restate what the code does, or narrate steps, are noise.

**How to apply:** Only write a comment that states a constraint or non-obvious *why* the code itself can't show (e.g. "Android re-reads http_proxy only on reconnect", "route Tr.Proxy so MITM'd traffic egresses upstream"). Drop doc comments that just paraphrase the function name and step-by-step narration.
