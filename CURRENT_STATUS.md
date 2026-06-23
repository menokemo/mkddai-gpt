# Current Status

## Working

- Docker stack is running.
- PostgreSQL is running.
- n8n is running.
- Open WebUI is running.
- OpenHands is running.
- SearXNG is running.
- Redis is running.
- `00_AI_General_Manager` is working.
- Postgres Chat Memory is working.
- OpenWebUI Pipe v1.0.3 filters internal helper prompts.
- Memory pollution from OpenWebUI title/tags/followups was diagnosed and fixed.
- `01B_Intent_Analyzer` exists (this is the node previously referred to as `02_Intent_Analyzer` in earlier planning docs — same role, different name in the real workflow). Classifies into: `CHAT`, `ASK_CLARIFICATION`, `RESEARCH`, `NEW_PROJECT`, `CONTINUE_PROJECT`.
- `01C_Intent_Router` (Switch node) added after the Intent Analyzer — routes by classification label.

## Current Workflow Shape

```text
01_Client_Intake (webhook)
  -> 00_AI_General_Manager
  -> 01B_Intent_Analyzer
  -> 01C_Intent_Router (Switch: CHAT / ASK_CLARIFICATION / RESEARCH / NEW_PROJECT / CONTINUE_PROJECT)
  -> 99_Client_Response  (all branches currently point here as a placeholder)
```

The actual exported workflow is versioned at `workflows/ai-factory-v3.json` in this repo.

## Pending Confirmation (just fixed, not yet verified live)

These were fixed in `workflows/ai-factory-v3.json` on 2026-06-23 but need to be re-imported into the live n8n instance and tested end-to-end via the real webhook before being marked fully Fixed:

1. Webhook `01_Client_Intake` was disconnected from `00_AI_General_Manager` — reconnected.
2. Memory session key changed from fixed `mkddai-main-chat` to dynamic `{{ $json.body.chat_id }}`.
3. `01B_Intent_Analyzer` now receives the original user message, not just the General Manager's reply.

See `BUGS_AND_FIXES.md` for full detail on each.

## Current Risk

- The 5 branches of `01C_Intent_Router` all currently route to the same placeholder response (`99_Client_Response`). The real specialized paths (Research via SearXNG, New Project via PM Agent/Product Analyst/Architect, etc.) are not built yet.

## Latest Architectural Decision

Do not turn General Manager into a parser. Keep it conversational. Put classification/routing in hidden nodes after it (`01B_Intent_Analyzer` + `01C_Intent_Router`).
