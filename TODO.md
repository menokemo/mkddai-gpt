# TODO

Flat checklist version of `NEXT_STEPS.md`, in the order to actually do them. Check items off as they're done and confirmed live (not just fixed in the file — see `BUGS_AND_FIXES.md` for the difference).

## 0 — Pending live confirmation (already fixed in file)

- [ ] Re-import `workflows/ai-factory-v3.json` into the live n8n instance.
- [ ] Confirm dynamic memory session key (`chat_id`) is live and isolates memory per chat.
- [ ] Confirm `01B_Intent_Analyzer` receives the original user message correctly.

## 1 — Webhook Security ✅ DONE, confirmed live

- [x] `01_Client_Intake`'s Authentication set to Header Auth (Name: `X-AI-Factory-Secret`, Value: the generated secret) — native n8n feature, no IF node needed.
- [x] OpenWebUI Pipe sends the secret header — done and confirmed live (v1.0.5).
- [x] Confirmed requests with the correct header go through normally (n8n rejects ones without it automatically).

## 1b — Time Awareness for Every Agent ✅ DONE, confirmed live

- [x] `created_at` added to `n8n_chat_histories` and applied on the live server.
- [x] `01A_Time_Context` Postgres node built, runs on every message, feeds `00_AI_General_Manager`.
- [x] System message updated with `$now` + last-message time; timezone fixed to `Europe/Amsterdam`. Confirmed: correct current time and correct gap-since-last-message in live testing.
- [x] Bonus: conversation-history search Tool added (works for recent messages; deep "first message" search paused, see `BUGS_AND_FIXES.md`).

## 2 — Error Handling ✅ DONE, confirmed live

- [x] Build a dedicated n8n Error Workflow (`00_Error_Handler`: Error Trigger -> Postgres Insert).
- [x] Attach it as the Error Workflow for `ai-factory-v3` in Workflow Settings.
- [ ] ~~Respond to the user with a fallback message~~ — not possible from a separate Error Workflow (execution already ended); deferred, see `NEXT_STEPS.md` Step 2.
- [x] Log failures into `ai_agent_runs` — confirmed live.

## 3 — Real Intent Router

- [ ] Add the real `01C_Intent_Router` Switch node (replace the old placeholder design).
- [ ] Wire `CHAT` / `ASK_CLARIFICATION` straight to `99_Client_Response`.

## 4 — New Project Path

- [ ] Save Project (Postgres -> `ai_projects`).
- [ ] PM Agent.
- [ ] Rename OpenWebUI chat to `{emoji} {official project title}` via `POST /api/v1/chats/{chat_id}` (needs OpenWebUI API key credential).
- [ ] Product Analyst Agent (with SearXNG Tool if needed).
- [ ] **Design Variants Gate (only if UI is needed):**
- [x] Add `ai_design_variants` table to the installer schema — done.
  - [ ] UI/UX Designer Agent derives sitemap from PM/Product Analyst output (no invented pages).
  - [ ] Pick 3-4 representative pages per platform (web/app).
  - [ ] Generate 2 Design Variants (A/B) per platform as real HTML + Tailwind, one design system reused per variant, real internal navigation between that variant's pages.
  - [ ] Use a cheaper coding model (DeepSeek/Qwen Coder via OpenRouter) for this step specifically.
  - [ ] Save each page as a row in `ai_design_variants`.
  - [ ] Add `GET /preview/:project_id/:variant/:page_slug` webhook to render stored HTML.
  - [ ] Build branded Presentation Page listing all variants with live previews.
  - [ ] Add `GET /choose/:project_id/:variant` webhook to mark chosen/rejected and show confirmation.
  - [ ] Send Presentation Page link to client via `99_Client_Response`.
- [ ] Architect Agent (uses the chosen variant's HTML as the real starting point).
- [ ] Security Reviewer Agent (reviews the Architect's plan).
- [ ] Save Project Memory (Postgres -> `ai_project_memory`).
- [ ] Response back to user with the plan summary.

## 5 — Continue Project Path

- [ ] Get Project (Postgres lookup by `chat_id`).
- [ ] Switch to resume the right stage based on saved `status`.

## 6 — Confirmation Gate

- [ ] After the plan is presented (Step 4), explicitly ask the user to confirm before building.
- [ ] Only proceed to Step 7 on confirmation.

## 7 — Execution Path

- [ ] Execution Brief Builder Agent — include No-AI-Fingerprint instructions (see `AGENTS.md`).
- [ ] GitHub node (create/update repo, branch, commit).
- [ ] HTTP Request -> OpenHands API.
- [ ] Save Agent Run (Postgres -> `ai_agent_runs`).

## 8 — Async / Long-Running Execution

- [ ] Respond immediately to the user once execution starts (don't block the webhook).
- [ ] Track progress in `ai_projects.status` / `ai_agent_runs`.
- [ ] Continue Project path reports current status on check-in instead of making the user wait.

## 8b — Interactive Task List per Project

- [ ] **Path A (try first):** Test whether Open WebUI's native Task Management (`create_tasks`/`update_task`) works through our custom Pipe -> n8n setup, not just direct native model connections.
- [ ] **Path B (guaranteed fallback, build regardless):**
  - [ ] `GET /tasks/:project_id` webhook — renders `ai_tasks` rows as a real checkbox list.
  - [ ] `GET/POST /tasks/:task_id/complete` webhook — updates `status` in Postgres on check.
  - [ ] General Manager sends this link whenever tasks are created/updated.
- [ ] **Path C (preferred once Step 14 exists):** Telegram inline buttons via the "Get Project Tasks" tool — faster on mobile, no separate page.

## 14 — Telegram Integration

- [ ] Create Telegram Bot via @BotFather, store token as n8n credential.
- [ ] **14a — Notifications:** Telegram node at key pipeline points (execution finished, QA failed, new project started, cost threshold crossed).
- [ ] **14b — Second entry point:** Telegram Trigger -> normalize to `message`/`chat_id` shape -> `00_AI_General_Manager` -> respond via Telegram node.
- [ ] **14c — "Get Project Tasks" Tool:** Postgres Tool reading `ai_tasks`, attached to the General Manager; format replies with inline buttons when responding via Telegram.

## 9 — QA / Revision Loop

- [ ] QA Agent — include No-AI-Fingerprint check (see `AGENTS.md`).
- [ ] Switch on `QA_STATUS` (pass/fail).
- [ ] Revision Agent on fail -> back to Step 7 with a correction brief.
- [ ] Save QA Report (Postgres -> `ai_qa_reports`).

## 10 — Delivery

- [ ] Delivery Agent — final No-AI-Fingerprint pass (see `AGENTS.md`).
- [ ] Update `ai_project_memory` / `ai_projects.status = done`.
- [ ] Final response to user.

## 11 — Post-Delivery Archive & Cleanup (manual confirmation required, never automatic)

- [ ] Archive node: write chosen Design Variant HTML, `ai_project_memory` export, QA reports, and final task list into the project's repo (`docs/`).
- [ ] Explicit confirmation step before any deletion happens.
- [ ] Cleanup node (only after confirmation): delete local OpenHands workspace files + the now-archived Postgres rows (`ai_design_variants`, `ai_tasks`, `ai_project_memory`, `ai_qa_reports`) for that `project_id`.
- [ ] **Never delete the `ai_projects` row itself** — only update its `status`. `id`, `project_slug`, and `repo_url` must remain permanently retrievable.

## 12 — Memory Agent (later, lower priority)

- [ ] Only after Steps 4-10 work manually: consider a dedicated Memory Agent to standardize Postgres memory writes instead of each phase doing it ad-hoc.

## 13 — Cost Dashboard

- [x] Add `ai_token_usage` table to the installer schema — done.
- [ ] **Path A (try first):** Test whether the AI Agent node surfaces OpenRouter's `usage`/`cost` data in its own output.
- [ ] **Path B (fallback):** HTTP Request node to OpenRouter's `/generation` endpoint, or per-project API keys + OpenRouter's own Activity dashboard.
- [ ] `GET /costs` webhook — all projects, cost broken down per agent/model, with totals.

## Always (every step above)

- [ ] Update `BUGS_AND_FIXES.md` for any bug found/fixed.
- [ ] Update `CHANGELOG.md` for any change made.
- [ ] Update `PROJECT_SUMMARY.md` for any feature done/planned/rejected.
