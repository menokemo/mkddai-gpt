# Current Status

## Working

- Docker stack is running.
- PostgreSQL is running.
- n8n is running.
- Open WebUI is running.
- OpenHands is running.
- SearXNG is running, with JSON output format enabled (confirmed via live `curl` test).
- Redis is running.
- `00_AI_General_Manager` is working, confirmed connected end-to-end from the real webhook (`01_Client_Intake -> 00_AI_General_Manager`) in the live n8n instance.
- Postgres Chat Memory is working.
- OpenWebUI Pipe v1.0.3 filters internal helper prompts.
- Memory pollution from OpenWebUI title/tags/followups was diagnosed and fixed.
- `01B_Intent_Analyzer` exists in the live workflow. Classifies into: `CHAT`, `ASK_CLARIFICATION`, `RESEARCH`, `NEW_PROJECT`, `CONTINUE_PROJECT`.
- **Web search is now attached directly as a Tool on `00_AI_General_Manager`** using n8n's native SearXNG tool node — see `DECISIONS_LOG.md`. The General Manager decides on its own when to search instead of going through a separate Research Agent branch.

## Current Workflow Shape (live, confirmed by screenshot)

```text
01_Client_Intake (webhook)
  -> 00_AI_General_Manager  (has: Chat Model, Memory, and Tool = SearXNG search)
  -> 01B_Intent_Analyzer
  -> 99_Client_Response
```

## Important note on `workflows/ai-factory-v3.json` in this repo

The committed JSON file still contains an earlier draft design (`01C_Intent_Router` Switch + separate `02B_Research_Agent` branch). That design was **superseded** by the simpler Tool-on-General-Manager approach described above. The file needs a fresh export from the live n8n instance to stay accurate — do this next time a workflow change is exported.

## Pending Confirmation

1. Memory session key dynamic `chat_id` — fixed in file, needs live confirmation it's applied in the live workflow too.
2. `01B_Intent_Analyzer` receiving the original user message — fixed in file, needs live confirmation.

See `BUGS_AND_FIXES.md` for full detail on each.

## Current Risk

- `workflows/ai-factory-v3.json` in the repo is out of sync with the live workflow (see note above) — re-export needed.
- New Project and Continue Project paths are still not built (no agents attached yet for those intents).

## Latest Architectural Decision

Do not turn General Manager into a parser for routing — but it *can* and does call tools directly (like web search) when it judges it needs to, without breaking its conversational role. Routing/classification for project workflows still happens in `01B_Intent_Analyzer` after it.
