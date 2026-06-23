# Changelog

## 2026-06-23 (latest) — Conversation-history search Tool + Time Awareness confirmed live

- Added a Postgres-backed Tool to `00_AI_General_Manager` (same pattern as SearXNG): queries `n8n_chat_histories` for the current `chat_id`, sorted newest-first, `LIMIT 20`. Lets it answer "when did we discuss X" questions on demand.
- Cost analysis: zero extra cost on normal turns (model only calls it when the user references conversation history), bounded cost when used (`LIMIT 20`). See `DECISIONS_LOG.md`.
- Time Awareness fully confirmed live after the timezone fix — General Manager now reports the correct current time.

## 2026-06-23 (latest) — n8n timezone fixed to Europe/Amsterdam

- Added `GENERIC_TIMEZONE` and `TZ` env vars (set to `Europe/Amsterdam`, matching the team's chosen timezone) to the n8n service in `install_ai_factory_v3.sh`'s `docker-compose.yml`. Without this, `$now` was returning UTC-4, several hours off, causing the General Manager to report the wrong current time despite the Time Awareness feature working correctly otherwise.
- General Manager named **باجوش** confirmed live, introduces itself correctly.
- Time Awareness confirmed partially working live: `01A_Time_Context` node and `$now` injection both work; only the timezone offset was wrong.

## 2026-06-23 (latest) — Webhook Security done via native Header Auth (Step 1 complete)

- Pivoted away from the planned custom IF node + `$env` approach after hitting n8n's `N8N_BLOCK_ENV_ACCESS_IN_NODE` restriction (env access blocked in node expressions by default).
- Used n8n's built-in Webhook node `Authentication: Header Auth` instead — `01_Client_Intake` now rejects any request missing/mismatching the `X-AI-Factory-Secret` header automatically, with zero extra nodes and the secret stored as a credential rather than in the workflow JSON.
- Confirmed live: a real chat through Open WebUI got a normal reply.
- Note: the `AI_FACTORY_WEBHOOK_SECRET` env var passed to the n8n container (added in an earlier commit) is no longer needed for this approach but is harmless to leave in place.
- Step 1 is now fully done — see `TODO.md` / `NEXT_STEPS.md`.

## 2026-06-23 (latest) — Live deployment confirmed: schema + webhook secret + Pipe v1.0.4

- Re-ran the updated installer on the live server: `ai_design_variants` and `ai_token_usage` tables confirmed created.
- Generated `AI_FACTORY_WEBHOOK_SECRET` and added it to the live `.env` (the installer's idempotent `.env` check doesn't add new vars to an existing file, so this needed a manual one-line append).
- Fixed a `def init` -> `def __init__` typo found in the live Pipe (it was never actually being instantiated), bumped to v1.0.4, added `webhook_secret` + `X-AI-Factory-Secret` header. Confirmed deployed by the user.
- Bumped the Pipe template version in `install_ai_factory_v3.sh` to match (1.0.4).
- Still pending: the n8n-side IF node that actually checks this header — nothing rejects unauthenticated requests yet, see `CURRENT_STATUS.md` -> Current Risk.

## 2026-06-23 (latest) — Installer fully updated for everything except the n8n workflow itself

- `.env` now generates `AI_FACTORY_WEBHOOK_SECRET`, printed at the end of installation and saved in `/opt/ai-factory/.env`.
- `db-init/01-ai-factory-schema.sql` (built by the installer): added `ai_design_variants` (Design Variants Gate) and `ai_token_usage` (Cost Dashboard) tables + indexes.
- `docs/openwebui_ai_factory_pipe.py`: now sends `X-AI-Factory-Secret` header on every webhook call using a `webhook_secret` field (placeholder `YOUR_WEBHOOK_SECRET`, to be replaced with the real generated value).
- `README-FIRST.md`: updated with instructions to copy the webhook secret into the Pipe, and a note that the actual webhook-security check (the IF node comparing this header) is built inside n8n itself, not by the installer.
- Note: `ai_tasks` (Interactive Task List) already existed from the original schema — no change needed there. Time Awareness's `created_at` column was already added in an earlier commit.
- Everything n8n-workflow-side (Error Handling, real Intent Router, New/Continue Project paths, Confirmation Gate, Execution, Async handling, QA/Revision, Delivery, Archive & Cleanup, the webhook-security IF node itself) is intentionally left for building together node by node in n8n — not part of this script.

## 2026-06-23 (latest) — Time Awareness policy + schema change

- Added `created_at` column (+ index) to `n8n_chat_histories` in `install_ai_factory_v3.sh`, so real per-message timestamps are available. Re-run `scripts/apply_schema.sh` on the live server to apply this to the existing database.
- Documented `01A_Time_Context` node plan (runs on every message, not just session start) and the global Time Awareness Policy in `AGENTS.md`: every agent gets current real time + the user's last-message time on every turn, to stop hallucinated elapsed-time claims.
- Logged the decision in `DECISIONS_LOG.md`; added to `NEXT_STEPS.md` (Step 1b) and `TODO.md`.

## 2026-06-23 (latest) — Repo cleanup

- Removed 11 stale/duplicate files that contradicted or repeated the current canonical docs: `PROJECT_MASTER_CONTEXT.md`, `DECISIONS.md`, `ARCHITECTURE.md`, `N8N_WORKFLOW_PLAN.md`, `DATABASE_PLAN.md`, `INSTALLER_PLAN.md`, `OPENWEBUI_PIPE.md`, `OPENWEBUI_SETUP.md`, `BOOTSTRAP_NOTES.md`, `README_SYNC.md`, `sync_docs.sh`.
- Rewrote `README.md` as a clear index of all remaining files and their purpose.
- Confirmed `workflows/ai-factory-v3.json` already reflects the latest design (dynamic session key, fixed Intent Analyzer input, SearXNG Tool, updated system message) — nothing stale there.

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
