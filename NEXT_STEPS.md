# Next Steps

Ordered plan for the rest of the n8n workflow. Each step assumes the ones before it are done. See `TODO.md` for the flat checklist version of this same plan.

## Done so far

- Webhook -> General Manager (Chat Model + Memory + SearXNG Tool) -> Intent Analyzer -> Response. Confirmed live.
- General Manager's system message rewritten: actually calls the search tool, matches user's language (Egyptian dialect for Arabic).
- Dynamic memory session key (`chat_id`) and Intent Analyzer's original-message fix: re-applied in `workflows/ai-factory-v3.json`, pending live re-import + confirmation.
- Decision: web search lives as a Tool on the General Manager, not a separate Research Agent + Switch branch (see `DECISIONS_LOG.md`).

## Step 1: Webhook Security — DONE, confirmed live

Implemented using n8n's **native Webhook node authentication** — no IF node, no `$env`, no extra nodes at all:
- `01_Client_Intake`'s own `Authentication` parameter set to **Header Auth**.
- A Header Auth credential created with Name = `X-AI-Factory-Secret`, Value = the generated `AI_FACTORY_WEBHOOK_SECRET`.
- The OpenWebUI Pipe (v1.0.5) sends this header on every request.
- n8n itself rejects (401) any request missing or mismatching this header, before the workflow even runs.

This replaced the originally planned approach (a custom IF node reading `$env.AI_FACTORY_WEBHOOK_SECRET`), which hit a wall: recent n8n versions block `$env` access in node expressions by default (`N8N_BLOCK_ENV_ACCESS_IN_NODE=true`), and unblocking it is explicitly discouraged for sensitive values — n8n's own docs recommend using credentials instead, which is exactly what Header Auth already does natively. See `DECISIONS_LOG.md`.

Confirmed live: a chat through Open WebUI got a normal reply (meaning the header matched and n8n let the request through).

## Step 1b: Time Awareness for Every Agent (every turn, not just session start)

Goal: stop agents from hallucinating elapsed time (e.g. claiming "last week" when the previous message was minutes ago, or the reverse) by giving them a real timestamp instead of letting them guess from conversational patterns.

Schema change (already added to `install_ai_factory_v3.sh`, re-run `scripts/apply_schema.sh` on the live server to apply it):
```sql
ALTER TABLE n8n_chat_histories ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
```

Add a node right after `01_Client_Intake` (e.g. `01A_Time_Context`, a Postgres node) that runs on **every** incoming message, not just the first one in a session:
```sql
SELECT created_at FROM n8n_chat_histories
WHERE session_id = '{{ $json.body.chat_id }}'
ORDER BY id DESC LIMIT 1
```

Every agent's system message includes the same two facts (current real time + this last-message timestamp) so the model reasons from real numbers instead of guessing. See `AGENTS.md` -> Time Awareness Policy. The model decides what counts as a "long" or "short" gap itself — no hardcoded threshold.

## Step 2: Error Handling

Build a dedicated n8n **Error Workflow** and attach it to `ai-factory-v3` (Workflow Settings -> Error Workflow):
- Catches failures from any node (OpenRouter timeout, bad API response, etc.).
- Sends a fallback response back to the user instead of leaving the webhook hanging.
- Logs the failure into `ai_agent_runs` (status = `failed`) for visibility.

Do this before adding more agents, so every new branch is covered by it automatically.

## Step 3: Real Intent Router (Switch)

Add the actual `01C_Intent_Router` Switch node (not a placeholder) after `01B_Intent_Analyzer`:
- `CHAT` / `ASK_CLARIFICATION` -> straight to `99_Client_Response` (General Manager already answered).
- `NEW_PROJECT` -> Step 4.
- `CONTINUE_PROJECT` -> Step 5.

## Step 4: New Project Path

```text
01C_Intent_Router (NEW_PROJECT)
  -> Save Project (Postgres insert into ai_projects)
  -> PM Agent (AI Agent: own Model; no memory needed)
  -> Rename OpenWebUI chat (HTTP Request -> POST /api/v1/chats/{chat_id}, body: {"title": "{emoji} {official project title from PM Agent}"}) — needs an OpenWebUI API key as a credential
  -> Product Analyst Agent (AI Agent: own Model; SearXNG Tool shared if it needs market research)
  -> [if UI is needed] Step 4b: Design Variants Gate
  -> Architect Agent (AI Agent: own Model)
  -> Security Reviewer Agent (AI Agent: own Model) -- reviews the Architect's plan before anything is built
  -> Save Project Memory (Postgres insert/update into ai_project_memory)
  -> 99_Client_Response (summary back to the user)
```

### Step 4b: Design Variants Gate (only if the project needs UI)

Goal: let the client see and choose between real, clickable design options *before* spending tokens on full OpenHands execution — and make the system feel professional doing it.

```text
UI/UX Designer Agent
  -> derives sitemap from PM Agent's PRD + Product Analyst's functional requirements (never invents pages)
  -> picks the 3-4 most representative pages per platform (web/app)
  -> generates 2 Design Variants (A/B) per platform, each variant:
       - real HTML + Tailwind CSS (not images, not descriptions)
       - one shared design system (colors/fonts/spacing) per variant, reused across its pages to control token cost
       - real <a href> navigation between its own pages (clickable prototype feel)
       - cheaper coding model used for this step (e.g. DeepSeek/Qwen Coder via OpenRouter, not GPT-4o)
  -> Save each page as a row in ai_design_variants (see schema below)
  -> Build one branded Presentation Page listing all variants (cards with live iframe previews)
  -> 99_Client_Response sends the Presentation Page link to the client
  -> Client opens it, clicks through each variant's own pages like a real site/app, then clicks "Choose this design" (plain link -> small webhook, no JS needed)
  -> Webhook marks the chosen variant's pages chosen = true, rejected variant(s) chosen = false (never built)
  -> Only then does the flow continue to Architect Agent, using the chosen variant's HTML as the real starting point
```

New table needed (add to `install_ai_factory_v3.sh`'s schema):

```sql
CREATE TABLE IF NOT EXISTS ai_design_variants (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT REFERENCES ai_projects(id) ON DELETE CASCADE,
    platform TEXT NOT NULL,        -- 'web' | 'app'
    variant_label TEXT NOT NULL,   -- 'A' | 'B'
    page_slug TEXT NOT NULL,       -- 'home' | 'products' | 'product-detail' | ...
    html_content TEXT NOT NULL,
    chosen BOOLEAN,                -- NULL until the client decides
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

Small dedicated webhook nodes needed:
- `GET /preview/:project_id/:variant/:page_slug` -> returns the stored HTML so links/iframes actually render in the client's browser.
- `GET /choose/:project_id/:variant` -> marks that variant's pages chosen, the other(s) rejected, shows a simple confirmation page, and is what kicks off Step 4 continuing to Architect Agent.

## Step 5: Continue Project Path

```text
01C_Intent_Router (CONTINUE_PROJECT)
  -> Get Project (Postgres: look up ai_projects + ai_project_memory by chat_id)
  -> Switch (route to whichever stage the project's `status` says it's at)
  -> 99_Client_Response
```

## Step 6: Confirmation Gate Before Execution

After Step 4 produces a plan (and before anything is ever written to GitHub/OpenHands), add an explicit confirmation step:
- Respond to the user with the plan and ask "should I start building this?"
- Only proceed to Step 7 once the next user message confirms (handled by `01B_Intent_Analyzer`/Continue Project path recognizing a confirmation reply).

This prevents executing on a misunderstood request.

## Step 7: Execution Path

```text
Execution Brief Builder (AI Agent: own Model) -- includes the No-AI-Fingerprint instructions, see AGENTS.md
  -> GitHub node (native GitHub node: create/update repo, branch, commit)
  -> HTTP Request -> OpenHands API (execution brief)
  -> Save Agent Run (Postgres insert into ai_agent_runs)
```

## Step 8: Handle Long-Running Execution (Async)

OpenHands execution can take far longer than a webhook should stay open:
- Respond to the user immediately after Step 7 kicks off ("started building, will update you").
- Track progress in `ai_agent_runs` / `ai_projects.status`.
- When the user's next message is a check-in, the Continue Project path (Step 5) reports current status instead of making them wait on one long request.

## Step 8b: Interactive Task List per Project

Goal: give the client a real, live-updating todo list for their project — not just a static text summary.

Data model already exists: `ai_tasks` (id, project_id, title, description, owner_agent, status, priority). Architect/PM/Execution steps populate and update rows here as the project progresses. What's missing is how the client actually *sees and interacts with* it. Two paths, try in this order:

**Path A — Open WebUI's native Task Management feature (try first, free if it works)**
Open WebUI has a built-in feature where an agentic model maintains a live checklist directly inside the chat, via two built-in tools (`create_tasks`, `update_task`). If our setup (Open WebUI -> Pipe -> n8n, not a direct native model connection) can trigger this, the client would see a real interactive checklist right inside their conversation with zero extra infrastructure. **Unconfirmed** — needs a live test, since this feature is documented for native function-calling model connections, and we go through a custom Pipe. Test before relying on it.

**Path B — Dedicated webhook page (guaranteed fallback, same pattern as the Design Variants Gate)**
If Path A doesn't work through the Pipe:
- `GET /tasks/:project_id` webhook renders an HTML page listing that project's rows from `ai_tasks` as real checkboxes.
- Checking a box calls a small `GET/POST /tasks/:task_id/complete` webhook that updates `status` in Postgres immediately.
- The General Manager sends this page's link to the client whenever tasks are created/updated, same as the Presentation Page link pattern.

Build Path B regardless of Path A's outcome — it's the dependable version and reuses an already-proven pattern.

**Path C — Telegram with inline buttons (preferred, once Step 14 exists)**
Once the Telegram integration (Step 14 below) is built, the owner can ask "what's the status of project X" directly in Telegram, and the General Manager (using a "Get Project Tasks" tool reading `ai_tasks`) replies with the task list plus real **inline buttons** ("✅ Done") to mark tasks complete right there — no separate page needed, and faster on mobile than Path B. Path B stays as the web fallback for anyone not using Telegram.

## Step 14: Telegram Integration

Goal: since MKDD currently has a single owner/user (not yet multiple external clients), Telegram serves two purposes for *that owner*: push notifications, and a second, faster mobile entry point into باجوش.

**14a — Push notifications (solves the Async Execution problem from Step 8 directly)**
Add a Telegram node (no extra trigger needed) at key points in the pipeline to message the owner directly:
- When OpenHands execution finishes (Step 7/8) — "مشروعك جاهز!" instead of the owner needing to check back manually.
- When QA fails (Step 9).
- When a new project starts.
- When a project's cost crosses a threshold (ties into the Cost Dashboard, Step 13).

This needs a Telegram Bot (created via @BotFather) and its token stored as an n8n credential.

**14b — Telegram as a second entry point to the General Manager**
```text
Telegram Trigger (the owner's messages to the bot)
  -> normalize to the same shape 00_AI_General_Manager expects (message, chat_id)
  -> 00_AI_General_Manager (same agent, same Tools, same Memory)
  -> respond via a Telegram node instead of Respond to Webhook
```
Lets the owner talk to باجوش from the Telegram app directly, on top of (not instead of) Open WebUI.

**14c — "Get Project Tasks" Tool + inline buttons**
A Postgres Tool (same pattern as the conversation-history search Tool) reading `ai_tasks` for a given project, attached to `00_AI_General_Manager`. When replying through Telegram specifically, format the task list with inline buttons so the owner can mark tasks done without leaving the chat. This becomes Path C for Step 8b above.

## Step 9: QA / Revision Loop

```text
QA Agent (AI Agent: own Model) -- includes the No-AI-Fingerprint check, see AGENTS.md
  -> Switch (PASS / FAIL)
       PASS -> Step 10
       FAIL -> Revision Agent (AI Agent: own Model) -> back to Step 7's GitHub/OpenHands step with a correction brief
  -> Save QA Report (Postgres insert into ai_qa_reports)
```

## Step 10: Delivery

```text
Delivery Agent (AI Agent: own Model) -- final No-AI-Fingerprint pass, see AGENTS.md
  -> Update Project Memory (Postgres update ai_project_memory / ai_projects.status = done)
  -> 99_Client_Response (final friendly summary to the user)
```

## Step 11: Post-Delivery Archive & Cleanup (manual confirmation required)

Goal: once a project is fully delivered, free up VM disk space (OpenHands workspace files, heavy Postgres rows) while keeping everything recoverable through the project's own GitHub repo — and never touching the permanent project record itself.

**This step never runs automatically.** It only runs after an explicit confirmation from the team (e.g. "project X is delivered, archive and clean it up?" -> yes). Irreversible cleanup must never be a side-effect of normal delivery.

```text
1. Archive: write everything worth keeping into the project's own repo (docs/ folder):
   - the chosen Design Variant's HTML pages
   - a JSON export of ai_project_memory
   - QA reports (ai_qa_reports)
   - the final task list (ai_tasks)
2. Confirmation gate: ask explicitly, wait for yes.
3. Cleanup (only after yes):
   - delete the project's local OpenHands workspace files on the VM
   - delete the now-archived rows from ai_design_variants, ai_tasks, ai_project_memory, ai_qa_reports for this project_id
4. Permanent Retention Rule (see DECISIONS_LOG.md): the ai_projects row itself is NEVER deleted.
   Only its status changes (e.g. to 'delivered_archived'). Its id, project_slug, and repo_url
   stay in the database forever, so the project can always be found and its repo opened again,
   even years later, even though the heavy working data has been cleaned up.
```

## Repo-per-Project Rule

A GitHub repo is created **only once the client has approved a project's direction** (after the Confirmation Gate in Step 6/Design Variants Gate, right before Execution starts) — not at every conversation, and not for ideas still being discussed. Each project gets its own dedicated repo; projects are never bundled together into one shared repo.

## Domains (Nginx Proxy Manager)

Handled outside of n8n — the team already runs Nginx Proxy Manager on the server. Each user-facing service (n8n editor/webhooks, design preview pages, task-list pages) should get its own subdomain through it (e.g. `n8n.yourdomain.com`, `preview.yourdomain.com`) instead of being shared on bare IP:port links sent to clients. No build work needed here beyond assigning subdomains as each webhook is built.

## Step 12: Memory Agent (cross-cutting)

Once Steps 4-10 work manually (each step saving its own Postgres record), consider adding a dedicated Memory Agent that standardizes how summaries get written into `ai_project_memory`, instead of every phase doing its own ad-hoc Postgres write. Lower priority — only worth it once the manual version proves repetitive.

## Step 13: Cost Dashboard

Goal: a page showing every project, and within each project, the cost broken down by which agent (employee) ran and which model it used — so projects can be priced correctly and nothing gets run at a loss.

New table needed (add to `install_ai_factory_v3.sh`'s schema):
```sql
CREATE TABLE IF NOT EXISTS ai_token_usage (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT REFERENCES ai_projects(id) ON DELETE CASCADE,
    agent_name TEXT NOT NULL,      -- e.g. 'PM Agent', 'Architect Agent'
    model_name TEXT NOT NULL,      -- e.g. 'openai/gpt-4o', 'deepseek/deepseek-coder'
    prompt_tokens INT,
    completion_tokens INT,
    cost_usd NUMERIC(10,6),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

`GET /costs` webhook renders all projects with a per-agent/per-model cost breakdown and a total, reading from this table (same pattern as the Design Variants / Task List preview pages).

OpenRouter now returns token counts **and** cost in USD automatically in every chat completion response (`usage.cost`) — no second API call needed to fetch cost separately.

**Path A (try first):** Check whether the AI Agent node (the high-level node used for every employee) surfaces this `usage`/`cost` data in its own output, so a Postgres "Save Usage" node can read it directly with zero extra calls. Unconfirmed — needs a live test, since the high-level node may abstract this away.

**Path B (fallback if Path A doesn't expose it):** Add a plain HTTP Request node after the agent's underlying chat-model call to fetch cost via OpenRouter's `/generation` endpoint using the response's generation id, or rely on OpenRouter's own per-API-key Activity/Analytics dashboard (requires one API key per project for clean separation, which adds operational overhead).

## Always

Keep `BUGS_AND_FIXES.md`, `CHANGELOG.md`, and `PROJECT_SUMMARY.md` updated for every change made in any of the steps above.
