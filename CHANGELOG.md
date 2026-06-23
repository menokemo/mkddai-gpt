# Changelog

## 2026-06-23 (latest) — System message rewrite + workflow sync

- Rewrote `00_AI_General_Manager`'s system message:
  - Now instructs it to actually use the SearXNG search Tool immediately when needed, instead of just announcing that research would be needed (leftover instruction from before the Tool existed).
  - Added a dedicated language section: reply in whatever language the user starts with; use Egyptian Arabic dialect specifically for Arabic.
- Synced `workflows/ai-factory-v3.json` with a fresh live export, which confirmed:
  - SearXNG Tool is live and attached to `00_AI_General_Manager`.
  - Webhook connection and updated system message are live.
  - The dynamic `chat_id` session key and the Intent Analyzer's original-message fix were **not** actually applied live yet — re-applied in this commit.

## 2026-06-23 (later still) — Installer fix + Research tool via native SearXNG node

- Fixed `install_ai_factory_v3.sh`: now pre-creates `searxng/settings.yml` with `json` format enabled before first boot, so the Research tool works out of the box on fresh installs (no manual edit needed).
- Decision: General Manager's web-search capability is implemented as a **Tool** attached directly to `00_AI_General_Manager` (using n8n's native **SearXNG** tool node, not a generic HTTP Request Tool and not the separate Research Agent + Switch branch that was drafted earlier). This lets the model decide itself when and how to search, instead of a fixed pipeline step.
- Confirmed live: webhook `01_Client_Intake -> 00_AI_General_Manager` connection exists and works in production (the disconnection found earlier only affected a stale exported file, not the live workflow).

## 2026-06-23 (later) — n8n workflow fixes

- Exported workflow `ai-factory-v3.json` reviewed and committed to `workflows/` for the first time (GitHub now versions the actual n8n workflow, not just docs).
- Fixed: webhook `01_Client_Intake` was not connected to `00_AI_General_Manager` — reconnected.
- Fixed: Postgres Chat Memory session key changed from fixed `mkddai-main-chat` to dynamic `{{ $json.body.chat_id }}`.
- Fixed: `01B_Intent_Analyzer` now receives both the original user message and the General Manager's reply (previously only received the reply).
- Added: `01C_Intent_Router` (Switch node) after the Intent Analyzer, routing on labels `CHAT`, `ASK_CLARIFICATION`, `RESEARCH`, `NEW_PROJECT`, `CONTINUE_PROJECT`. All branches currently point to `99_Client_Response` as a placeholder until the specialized agents for each path are built.
- All fixes pending confirmation after re-import and live testing — see `BUGS_AND_FIXES.md`.

## 2026-06-23

### Installer updated

- Final bootstrap script now creates all PostgreSQL tables automatically.
- Added `scripts/apply_schema.sh`.
- Added OpenWebUI Pipe v1.0.3.
- Removed LiteLLM from final installer.
- Added `ai_research_reports`.
- Added `n8n_chat_histories` creation fallback.

### Memory issue diagnosed

OpenWebUI was sending internal title/tag/follow-up prompts into n8n memory.

Fix:
- Pipe v1.0.3 filters internal prompts.
- Memory is now cleaner and the General Manager can recall user-provided context better.
