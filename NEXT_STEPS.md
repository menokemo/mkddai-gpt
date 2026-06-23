# Next Steps

Ordered plan for the rest of the n8n workflow. Each step assumes the ones before it are done. See `TODO.md` for the flat checklist version of this same plan.

## Done so far

- Webhook -> General Manager (Chat Model + Memory + SearXNG Tool) -> Intent Analyzer -> Response. Confirmed live.
- General Manager's system message rewritten: actually calls the search tool, matches user's language (Egyptian dialect for Arabic).
- Dynamic memory session key (`chat_id`) and Intent Analyzer's original-message fix: re-applied in `workflows/ai-factory-v3.json`, pending live re-import + confirmation.
- Decision: web search lives as a Tool on the General Manager, not a separate Research Agent + Switch branch (see `DECISIONS_LOG.md`).

## Step 1: Webhook Security

Add a simple shared-secret check right after `01_Client_Intake`:
- The OpenWebUI Pipe sends a custom header (e.g. `X-AI-Factory-Secret`).
- An `IF` node checks the header against the expected value (stored in n8n credentials/env, not hardcoded).
- If it doesn't match, route to a node that responds with an error and stops, instead of continuing to the General Manager.

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

## Step 11: Memory Agent (cross-cutting)

Once Steps 4-10 work manually (each step saving its own Postgres record), consider adding a dedicated Memory Agent that standardizes how summaries get written into `ai_project_memory`, instead of every phase doing its own ad-hoc Postgres write. Lower priority — only worth it once the manual version proves repetitive.

## Always

Keep `BUGS_AND_FIXES.md`, `CHANGELOG.md`, and `PROJECT_SUMMARY.md` updated for every change made in any of the steps above.
