# Changelog

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
