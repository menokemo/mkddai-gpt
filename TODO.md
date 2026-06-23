# TODO

Flat checklist version of `NEXT_STEPS.md`, in the order to actually do them. Check items off as they're done and confirmed live (not just fixed in the file — see `BUGS_AND_FIXES.md` for the difference).

## 0 — Pending live confirmation (already fixed in file)

- [ ] Re-import `workflows/ai-factory-v3.json` into the live n8n instance.
- [ ] Confirm dynamic memory session key (`chat_id`) is live and isolates memory per chat.
- [ ] Confirm `01B_Intent_Analyzer` receives the original user message correctly.

## 1 — Webhook Security

- [ ] Add shared-secret header check right after `01_Client_Intake`.
- [ ] Update the OpenWebUI Pipe to send the secret header.
- [ ] Confirm requests without the correct header are rejected.

## 2 — Error Handling

- [ ] Build a dedicated n8n Error Workflow.
- [ ] Attach it as the Error Workflow for `ai-factory-v3` in Workflow Settings.
- [ ] Make it respond to the user with a fallback message instead of leaving the webhook hanging.
- [ ] Make it log failures into `ai_agent_runs`.

## 3 — Real Intent Router

- [ ] Add the real `01C_Intent_Router` Switch node (replace the old placeholder design).
- [ ] Wire `CHAT` / `ASK_CLARIFICATION` straight to `99_Client_Response`.

## 4 — New Project Path

- [ ] Save Project (Postgres -> `ai_projects`).
- [ ] PM Agent.
- [ ] Product Analyst Agent (with SearXNG Tool if needed).
- [ ] **Design Variants Gate (only if UI is needed):**
  - [ ] Add `ai_design_variants` table to the installer schema.
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

## 9 — QA / Revision Loop

- [ ] QA Agent — include No-AI-Fingerprint check (see `AGENTS.md`).
- [ ] Switch on `QA_STATUS` (pass/fail).
- [ ] Revision Agent on fail -> back to Step 7 with a correction brief.
- [ ] Save QA Report (Postgres -> `ai_qa_reports`).

## 10 — Delivery

- [ ] Delivery Agent — final No-AI-Fingerprint pass (see `AGENTS.md`).
- [ ] Update `ai_project_memory` / `ai_projects.status = done`.
- [ ] Final response to user.

## 11 — Memory Agent (later, lower priority)

- [ ] Only after Steps 4-10 work manually: consider a dedicated Memory Agent to standardize Postgres memory writes instead of each phase doing it ad-hoc.

## Always (every step above)

- [ ] Update `BUGS_AND_FIXES.md` for any bug found/fixed.
- [ ] Update `CHANGELOG.md` for any change made.
- [ ] Update `PROJECT_SUMMARY.md` for any feature done/planned/rejected.
