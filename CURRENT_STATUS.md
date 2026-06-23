# Current Status

## Working (confirmed live via fresh export, 2026-06-23)

- Webhook Security: `01_Client_Intake`'s native Header Auth (n8n's built-in Webhook authentication, no IF node) confirmed live — requests without the correct `X-AI-Factory-Secret` header are rejected by n8n automatically.
- Updated installer re-run live on the server: `ai_design_variants` and `ai_token_usage` tables now exist in the live database (confirmed via `apply_schema.sh` output).
- `AI_FACTORY_WEBHOOK_SECRET` generated and present in the live server's `.env`.
- OpenWebUI Pipe updated live to v1.0.4: fixed a `def init` -> `def __init__` typo (the Pipe wasn't actually initializing before this), added `webhook_secret`, and sends it as the `X-AI-Factory-Secret` header on every request.
- Docker stack running: PostgreSQL, n8n, Open WebUI, OpenHands, SearXNG (JSON format enabled), Redis.
- `01_Client_Intake` (webhook) is connected to `00_AI_General_Manager` — confirmed live.
- `00_AI_General_Manager` has all three inputs wired: Chat Model (OpenRouter), Memory (Postgres), and Tool (native SearXNG node) — confirmed live.
- System message updated and live: General Manager (named **باجوش**, introduces itself by this name when asked) now actually calls the search Tool when needed (instead of just saying research is needed), and has explicit language rules (match user's language; Egyptian dialect for Arabic).
- `01B_Intent_Analyzer` exists, classifies into `CHAT` / `ASK_CLARIFICATION` / `RESEARCH` / `NEW_PROJECT` / `CONTINUE_PROJECT`.
- OpenWebUI Pipe v1.0.3 filters internal helper prompts; memory pollution issue fixed.

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
