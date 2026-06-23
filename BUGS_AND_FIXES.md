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
- **Status**: ⏳ Fixed in `workflows/ai-factory-v3.json` — pending confirmation after re-import/test in the live n8n instance.

### 2026-06-23 — Webhook not connected to General Manager
- **Bug**: In the exported workflow, `01_Client_Intake` (the webhook trigger) had an empty `main` connection — it was not wired to `00_AI_General_Manager` at all. If this was the live version, no real request from Open WebUI would ever reach the General Manager.
- **Root cause**: Likely a manual rewiring in the n8n editor (e.g. while adding the Intent Analyzer) that accidentally dropped the original trigger connection, or testing was done by manually triggering nodes inside the editor rather than through the real webhook end-to-end, so the break went unnoticed.
- **Fix**: Reconnected `01_Client_Intake -> 00_AI_General_Manager` in `workflows/ai-factory-v3.json`.
- **Status**: ✅ Confirmed — screenshot of the live n8n editor (2026-06-23) shows `01_Client_Intake` is in fact connected to `00_AI_General_Manager` in production; the disconnection only existed in the stale exported file, not the live workflow. File fix kept anyway for correctness.

### 2026-06-23 — Intent Analyzer missing the original user message
- **Bug**: `01B_Intent_Analyzer`'s prompt only received `{{ $json.output }}` (the General Manager's reply). Its own system message instructs it to read both the user's message *and* the manager's reply, but the user's message was never actually passed in.
- **Root cause**: The node's `text` parameter referenced only the previous node's output field, not the original webhook input.
- **Fix**: Updated the prompt to include both: `{{ $('01_Client_Intake').item.json.body.message }}` (original user message) and `{{ $json.output }}` (General Manager's reply).
- **Status**: ⏳ Fixed in file — pending confirmation after re-import/test.

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
