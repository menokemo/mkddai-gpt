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

### 2026-06-23 — Shared/fixed memory session key
- **Bug**: Postgres Chat Memory session key was hardcoded to `mkddai-main-chat`. This means every user/chat shares the exact same memory, instead of each chat having its own.
- **Root cause**: A temporary fixed value was used during early testing and was never replaced with a dynamic one.
- **Fix**: Changed the Session Key field on the `00M_General_Manager_Chat_Memory` node to `={{ $json.body.chat_id }}`, reading the real `chat_id` sent by the OpenWebUI Pipe through the webhook body.
- **Status**: ⏳ Fixed in `workflows/ai-factory-v3.json` — re-applied on 2026-06-23 after a fresh live export confirmed this fix had not actually been applied in the n8n instance yet. Still pending live confirmation after re-import/test.

### 2026-06-23 — Webhook not connected to General Manager
- **Bug**: In the exported workflow, `01_Client_Intake` (the webhook trigger) had an empty `main` connection — it was not wired to `00_AI_General_Manager` at all. If this was the live version, no real request from Open WebUI would ever reach the General Manager.
- **Root cause**: Likely a manual rewiring in the n8n editor (e.g. while adding the Intent Analyzer) that accidentally dropped the original trigger connection, or testing was done by manually triggering nodes inside the editor rather than through the real webhook end-to-end, so the break went unnoticed.
- **Fix**: Reconnected `01_Client_Intake -> 00_AI_General_Manager` in `workflows/ai-factory-v3.json`.
- **Status**: ✅ Confirmed — both a screenshot of the live n8n editor and a fresh workflow export (2026-06-23) show `01_Client_Intake` connected to `00_AI_General_Manager` in production; the disconnection only existed in the original stale exported file, not the live workflow.

### 2026-06-23 — Intent Analyzer missing the original user message
- **Bug**: `01B_Intent_Analyzer`'s prompt only received `{{ $json.output }}` (the General Manager's reply). Its own system message instructs it to read both the user's message *and* the manager's reply, but the user's message was never actually passed in.
- **Root cause**: The node's `text` parameter referenced only the previous node's output field, not the original webhook input.
- **Fix**: Updated the prompt to include both: `{{ $('01_Client_Intake').item.json.body.message }}` (original user message) and `{{ $json.output }}` (General Manager's reply).
- **Status**: ⏳ Fixed in `workflows/ai-factory-v3.json` — re-applied on 2026-06-23 after a fresh live export confirmed this fix had not actually been applied in the n8n instance yet. Still pending live confirmation after re-import/test.

### 2026-06-23 — SearXNG JSON format disabled by default, blocking the Research tool
- **Bug**: SearXNG ships with `format: json` disabled by default. Without it, the SearXNG n8n tool node (and any HTTP call asking for `format=json`) fails or returns HTML instead of structured data, which is required for the General Manager's web-search tool to work.
- **Root cause**: The installer (`install_ai_factory_v3.sh`) let SearXNG auto-generate its own `settings.yml` on first boot using its built-in defaults, which never enable the `json` format.
- **Fix**: Installer now pre-creates `/opt/ai-factory/searxng/settings.yml` itself (with `search.formats: [html, json]` and a generated `secret_key`) *before* `docker compose up`, so JSON is enabled from the very first run — no manual edit needed anymore for new installs.
- **Status**: ✅ Fixed in `install_ai_factory_v3.sh`. Confirmed manually on the live server (manual `settings.yml` edit + container restart) that `format=json` works once enabled — verified with a live `curl` test returning structured results.

### 2026-06-23 — Manual edit of settings.yml fails with Permission denied
- **Bug**: Running `nano /opt/ai-factory/searxng/settings.yml` as a non-root user failed to save with a permission error.
- **Root cause**: The file is owned by `root` (created either by the root-run installer or by the SearXNG container itself), and the logged-in user (`mkddai`) had no write access.
- **Fix**: Use `sudo nano ...` to edit. Now that the installer pre-creates the file with the right content (see fix above), this manual edit usually isn't needed at all for new installs.
- **Status**: ✅ Resolved (workaround confirmed working on the live server; root cause avoided going forward by the installer fix).

### 2026-06-23 — General Manager told to *announce* needing search instead of actually searching
- **Bug**: The original system message instructed the General Manager to say "it would be better to search first" instead of actually using a search tool — a leftover instruction from before any search tool existed.
- **Root cause**: The prompt was never updated after the SearXNG Tool was attached to the agent; it still described the old behavior (deferring to research instead of acting).
- **Fix**: Updated the system message so the General Manager uses its web-search Tool immediately when needed and answers in the same reply, instead of asking permission or stalling.
- **Status**: ⏳ Fixed in `workflows/ai-factory-v3.json` and confirmed already live (per the latest export) — pending one more live test specifically confirming search results show up correctly in a real reply.

### 2026-06-23 — No instruction for matching the user's language/dialect
- **Bug**: The General Manager had no explicit rule for which language or Arabic dialect to reply in, risking inconsistent (e.g. Modern Standard Arabic instead of Egyptian) or mismatched-language replies.
- **Root cause**: Never specified in the original prompt.
- **Fix**: Added a dedicated "اللغة" section to the system message: reply in whatever language the user starts with, and use Egyptian Arabic dialect specifically when the user writes in Arabic.
- **Status**: ⏳ Fixed in `workflows/ai-factory-v3.json` and confirmed already live (per the latest export) — pending a live test to confirm dialect behavior in practice.

### 2026-06-23 — `__init__` typo in the live Pipe (`def init` instead of `def __init__`)
- **Bug**: The Pipe code running live on the server had `def init(self):` instead of `def __init__(self):`, meaning Python would never actually call it as a constructor — `self.webhook_url` (and now `self.webhook_secret`) would never get set, causing the Pipe to fail at runtime.
- **Root cause**: Likely lost the double underscores during a manual copy/paste at some point.
- **Fix**: Corrected to `def __init__(self):` while updating the Pipe to v1.0.4 (adding `webhook_secret` + the `X-AI-Factory-Secret` header).
- **Status**: ✅ Fixed and deployed live — confirmed by the user.

### 2026-06-23 — `.env` on the live server didn't have `AI_FACTORY_WEBHOOK_SECRET`
- **Bug**: Re-running the updated installer on an existing install didn't add the new `AI_FACTORY_WEBHOOK_SECRET` line, since the installer only writes `.env` if it doesn't already exist. The final step that echoes the secret then failed with `unbound variable`.
- **Root cause**: Idempotent `.env` creation logic doesn't add new variables to an existing file.
- **Fix**: Manually appended the line with `echo "AI_FACTORY_WEBHOOK_SECRET=$(openssl rand -hex 24)" | sudo tee -a /opt/ai-factory/.env`.
- **Status**: ✅ Done live — secret generated and confirmed present in `.env`.

### 2026-06-23 — `$env` blocked in node expressions ("access to env vars denied")
- **Bug**: Tried to read `AI_FACTORY_WEBHOOK_SECRET` via `{{ $env.AI_FACTORY_WEBHOOK_SECRET }}` inside a custom IF node. n8n returned `[access to env vars denied]`.
- **Root cause**: Recent n8n versions set `N8N_BLOCK_ENV_ACCESS_IN_NODE=true` by default, blocking `$env` access from node expressions for security. Unblocking it is possible but explicitly discouraged by n8n's own docs for sensitive values like secrets.
- **Fix**: Abandoned the custom IF node entirely. Used n8n's native Webhook node `Authentication: Header Auth` setting instead — built specifically for this use case, stores the secret as a credential (not in the workflow JSON), and rejects non-matching requests automatically with no extra nodes.
- **Status**: ✅ Fixed and confirmed live — a real chat through Open WebUI got a normal reply, confirming the header check passes correctly.

### 2026-06-23 — n8n's `$now` returns the wrong timezone (UTC-4 instead of the team's real timezone)
- **Bug**: `$now` in n8n expressions returned a time offset by `-04:00`, several hours off from the team's actual local time, causing the General Manager to report the wrong current time.
- **Root cause**: n8n had no explicit timezone configured, so it defaulted to the server/container's own timezone (likely the hosting provider's default region — the server is physically hosted in the Netherlands, but that didn't determine the timezone n8n was using either).
- **Fix**: Added `GENERIC_TIMEZONE: "Europe/Amsterdam"` and `TZ: "Europe/Amsterdam"` to the n8n service's environment in `install_ai_factory_v3.sh`'s `docker-compose.yml`.
- **Status**: ⏳ Fixed in the installer — pending live confirmation after re-applying and restarting the n8n container.

### 2026-06-23 — Conversation-history search Tool limited by fixed LIMIT/Sort
- **Bug**: The Postgres Tool built to let the General Manager answer "when did we discuss X" questions only retrieves the most recent 20 messages (`Sort: DESC`, `Limit: 20`). Once a conversation passes 20 messages, the first message (and any early "when did I say X" target) falls outside what the tool returns, so it can't be found even though the tool runs successfully.
- **Attempted fix**: Tried driving `Sort Direction` and `Limit` via `$fromAI(...)` so the model could choose ascending/descending and how many rows itself. Did not work — n8n's Sort Rule fields don't reliably support AI-driven values the way query parameters do.
- **Status**: ⏸️ Paused/deferred by team decision — not worth the complexity right now. Documented next fix if revisited: split into two separate Postgres Tools with fixed configs (one `ASC LIMIT 5` for "first message" questions, one `DESC LIMIT 20` for "recent message" questions), both attached to the General Manager, each with its own clear description so the model picks the right one based on the question's intent.

### 2026-06-23 — No error handling, failures left the webhook hanging silently
- **Bug**: Any node failure (OpenRouter timeout, bad response, etc.) anywhere in `ai-factory-v3` left no record and no visibility — just an opaque n8n error response to the caller.
- **Fix**: Built a separate workflow `00_Error_Handler` (Error Trigger -> Postgres Insert into `ai_agent_runs`), attached as `ai-factory-v3`'s Error Workflow in its settings.
- **Status**: ✅ Fixed and confirmed live — a failure was logged successfully into `ai_agent_runs`.
