# Next Steps

## Step 0 (done — was Step 1): Fix Session Key, Connection, and Intent Analyzer Input

Fixed on 2026-06-23 in `workflows/ai-factory-v3.json`:
- Session key on `00M_General_Manager_Chat_Memory` changed to `{{ $json.body.chat_id }}`.
- Reconnected `01_Client_Intake -> 00_AI_General_Manager`.
- `01B_Intent_Analyzer` now receives the original user message + the General Manager's reply.

Action needed: re-import this workflow into the live n8n instance and confirm via a real webhook call (not just inside the editor) that:
- the General Manager responds end-to-end through the webhook,
- each chat_id gets isolated memory,
- the Intent Analyzer classifies correctly.

Once confirmed, mark these as ✅ Fixed in `BUGS_AND_FIXES.md`.

## Step 1 (done — was "Build Intent Analyzer"): `01B_Intent_Analyzer`

Already built (named `01B_Intent_Analyzer`, not `02_Intent_Analyzer` as originally planned — same role). Labels in use:

```text
CHAT
ASK_CLARIFICATION
RESEARCH
NEW_PROJECT
CONTINUE_PROJECT
```

## Step 2 (done — skeleton only): `01C_Intent_Router` Switch

Added after the Intent Analyzer. All 5 branches currently route to `99_Client_Response` as a placeholder — no specialized agent is attached to any branch yet.

## Step 3: Research Path

If `RESEARCH`:

```text
01C_Intent_Router (RESEARCH) -> Research Agent (uses SearXNG) -> General Manager Response -> 99_Client_Response
```

## Step 4: New Project Path

If `NEW_PROJECT`:

```text
01C_Intent_Router (NEW_PROJECT) -> Save Project (ai_projects table) -> PM Agent -> Product Analyst -> Architect -> 99_Client_Response
```

## Step 5: Continue Project Path

If `CONTINUE_PROJECT`: load existing project context from `ai_projects`/`ai_project_memory` and resume the relevant agent.

## Step 6: Execution Path

Later:

```text
GitHub Manager -> OpenHands Executor -> QA -> Delivery
```

## Step 7: Keep Docs Updated

Run:

```bash
./sync_docs.sh
```

after replacing or editing project documentation locally. Always update `BUGS_AND_FIXES.md`, `CHANGELOG.md`, and `PROJECT_SUMMARY.md` for every change.
