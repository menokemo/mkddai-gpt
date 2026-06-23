# Bugs & Fixes Log

This file tracks every bug found during development of MKDD AI Factory, its root cause, and the fix applied.

**Rule:** Before trying a new fix for the same bug, remove/revert any failed attempt first. Never stack a new fix on top of one that didn't work — keep the code clean. Only mark a bug as Fixed after confirming it 100%.

## Entry format

```
### [Date] — [Short bug title]
- Bug: what went wrong
- Root cause: why it happened
- Fix: what was done to solve it
- Status: ✅ Fixed / ⏳ In progress / ❌ Open
```

---

## Log

### 2026-06-23 — OpenWebUI internal prompts polluting n8n memory
- **Bug**: Open WebUI sends internal helper prompts (title generation, tag generation, follow-up suggestions) to the n8n webhook along with the real user message. These were being saved into Postgres Chat Memory, corrupting the General Manager's context and making it forget real user info.
- **Root cause**: The OpenWebUI Pipe/Function had no filtering before forwarding messages to n8n, so every internal system prompt was treated as a real user message.
- **Fix**: Updated OpenWebUI Pipe to v1.0.3. It now filters out any message starting with known internal prompt patterns:
  - `### Task:`
  - `Generate a concise`
  - `Generate 1-3 broad tags`
  - `Suggest 3-5 relevant follow-up`
- **Status**: ✅ Fixed and confirmed — General Manager now remembers user-provided context correctly after the fix.

### Open — Shared/fixed memory session key
- **Bug**: Postgres Chat Memory session key is hardcoded to `mkddai-main-chat`. This means every user/chat shares the exact same memory, instead of each chat having its own.
- **Root cause**: A temporary fixed value was used during early testing and was never replaced with a dynamic one.
- **Planned fix**: Change the Session Key field on the `Postgres Chat Memory` node (connected to `00_AI_General_Manager`) from `mkddai-main-chat` to `{{ $json.chat_id }}`, and confirm the OpenWebUI Pipe actually sends `chat_id` in its payload.
- **Status**: ❌ Open — top priority item, see `NEXT_STEPS.md` Step 1.
