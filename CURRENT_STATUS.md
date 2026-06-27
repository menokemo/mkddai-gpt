# Current Status

## ⚠️ Critical fix — 2026-06-27 (read this first)

Per-chat memory isolation was **not working since day one** — every conversation shared one combined memory under `session_id = "default"`, due to the Pipe reading `chat_id` from `body` instead of Open WebUI's reserved `__chat_id__` argument. **Fixed in Pipe v1.0.7**, confirmed live (different chats now get different chat_ids), and the 862 contaminated rows were deleted from the database. Any project/memory data from before this date should not be trusted as chat-isolated. Full detail in `BUGS_AND_FIXES.md`.

Also found and mitigated (not root-cause-fixable from our side) an upstream **n8n core bug**: the AI Agent node sometimes loops re-calling the model dozens of times even after producing a valid reply. Capped with `Max Iterations: 2` as a safety net on `00_AI_General_Manager`. See `BUGS_AND_FIXES.md`.

## Working (confirmed live)

- OpenWebUI Pipe is now v1.0.7 (fixes the `chat_id` bug above; earlier entries below referencing v1.0.3/1.0.4 are historical).
- `01B_Intent_Analyzer` classifies into `CHAT` / `ASK_CLARIFICATION` / `NEW_PROJECT` / `CONTINUE_PROJECT` (the `RESEARCH` label was removed — see `DECISIONS_LOG.md`, search is now a Tool call, not a routed intent).
- Webhook Security: `01_Client_Intake`'s native Header Auth (n8n's built-in Webhook authentication, no IF node) confirmed live — requests without the correct `X-AI-Factory-Secret` header are rejected by n8n automatically.
- Updated installer re-run live on the server: `ai_design_variants` and `ai_token_usage` tables now exist in the live database (confirmed via `apply_schema.sh` output).
- `AI_FACTORY_WEBHOOK_SECRET` generated and present in the live server's `.env`.
- Docker stack running: PostgreSQL, n8n, Open WebUI, OpenHands, SearXNG (JSON format enabled), Redis.
- `01_Client_Intake` (webhook) is connected to `00_AI_General_Manager` — confirmed live.
- `00_AI_General_Manager` has all three inputs wired: Chat Model (OpenRouter), Memory (Postgres), and Tool (native SearXNG node) — confirmed live.
- System message updated and live: General Manager (named **باجوش**, introduces itself by this name when asked) now actually calls the search Tool when needed (instead of just saying research is needed), and has explicit language rules (match user's language; Egyptian dialect for Arabic). Also includes the "don't act on something that hasn't actually happened" principle (see `DECISIONS_LOG.md`).
- Time Awareness fully confirmed live: `01A_Time_Context` node + `$now`, with timezone fixed to `Europe/Amsterdam` (was defaulting to UTC-4, causing wrong reported times). Confirmed: knows current time and the gap since the user's last message.
- Conversation-history search Tool added on `00_AI_General_Manager` (Postgres, reads `n8n_chat_histories` for the current `chat_id`) — works for recent messages, but is limited to the last 20 (fixed `LIMIT`/`DESC`), so it can't answer "when did I first say X" once a conversation passes 20 messages. **Paused/deferred** by team decision — see `BUGS_AND_FIXES.md` for the next-step fix (two separate fixed-config tools) if revisited.
- New Project Path agents (PM Agent, Product Analyst, Architect, Security Reviewer) all built and confirmed working end-to-end live for a full project request. Final summary-to-client step still in progress.

## Current Workflow Shape (live)

```text
01_Client_Intake (webhook)
  -> 00_AI_General_Manager  (Chat Model + Memory + Tool: SearXNG search)
  -> 01B_Intent_Analyzer
  -> 99_Client_Response
```

No Switch/Router and no separate Research Agent — web search is handled directly by the General Manager as a Tool call. This design choice is documented in `DECISIONS_LOG.md`.

## Pending — fixed in file, NOT yet confirmed live

A fresh export on 2026-06-23 showed these two fixes from earlier had not actually been applied in the live n8n instance (only in the committed file). They have been **re-applied** in `workflows/ai-factory-v3.json` — please re-import and confirm:

1. Memory session key still hardcoded to `mkddai-main-chat` in production — needs to change to `{{ $json.body.chat_id }}`.
2. `01B_Intent_Analyzer` still only receiving the General Manager's reply, not the original user message — needs the combined prompt.

See `BUGS_AND_FIXES.md` for full detail.

## Current Risk

- New Project and Continue Project paths are still not built (no agents attached yet for those intents — `01B_Intent_Analyzer` classifies them but nothing acts on the classification yet beyond passing through to the response).

## Latest Architectural Decision

The General Manager stays conversational but can call tools directly (web search) when it judges it needs to. Routing/classification for project workflows still happens in `01B_Intent_Analyzer` after it, but research is no longer a separate routed path.
