# Project Summary

A living summary of **MKDD AI Factory v3**: what the project is, every idea/feature that was discussed, whether it was built or postponed, and why. Update this file whenever scope, features, or status change — so anyone new joining the project can read this and understand where things stand without re-reading the whole chat history.

## What this project is

A self-hosted AI software-company system. The user talks to an intelligent technical General Manager through Open WebUI. The General Manager discusses ideas, asks questions, researches when needed, and launches specialized AI employees to plan, build, review, and deliver software projects.

## Final stack (current direction)

```text
Open WebUI  -> n8n Webhook -> 00_AI_General_Manager -> Intent Analyzer / Router
  -> Specialized AI Employees -> PostgreSQL Memory -> GitHub -> OpenHands -> QA / Delivery
```

- **Open WebUI** — user-facing chat interface.
- **n8n** — main orchestration engine (routing, employees, memory, GitHub, OpenHands, QA).
- **OpenRouter** — model provider, used directly by n8n AI Agent nodes and by OpenHands.
- **PostgreSQL** — persistent memory: projects, tasks, QA, research, chat history.
- **GitHub** — source of truth for docs, decisions, code, and delivery.
- **OpenHands** — coding executor only (receives strict execution briefs).
- **SearXNG** — research/search service.
- **Redis** — support/cache service.

## Features & ideas — status tracker

### ✅ Done
| Feature | Notes |
|---|---|
| `00_AI_General_Manager` | User-facing conversational AI layer. Must stay conversational, not a parser. |
| Postgres Chat Memory | Working, stores conversation memory. |
| OpenWebUI Pipe internal-prompt filtering (v1.0.3) | Fixes memory pollution from title/tag/follow-up system prompts — see `BUGS_AND_FIXES.md`. |
| Automatic PostgreSQL table creation | Installer (`install_ai_factory_v3.sh`) creates all required tables on setup. |
| Core Docker stack | PostgreSQL, Redis, SearXNG, n8n, Open WebUI, OpenHands all running. |
| Dynamic memory session key | Changed from fixed `mkddai-main-chat` to `{{ $json.body.chat_id }}` so each chat gets isolated memory. Pending live confirmation — see `BUGS_AND_FIXES.md`. |
| Intent Analyzer (`01B_Intent_Analyzer`) | Classifies into `CHAT` / `ASK_CLARIFICATION` / `RESEARCH` / `NEW_PROJECT` / `CONTINUE_PROJECT`. Fixed to receive the real user message, not just the GM's reply. |
| Switch Router (`01C_Intent_Router`) | Drafted in `workflows/ai-factory-v3.json` but **superseded** — see Rejected table. Not part of the live design. |
| Web search Tool on General Manager | n8n native SearXNG tool node attached to `00_AI_General_Manager`'s `ai_tool` input. Model decides when to search. Installer now enables SearXNG JSON format automatically. |

### ⏳ Planned / not built yet
| Feature | Idea | Why / Reasoning | Status |
|---|---|---|---|
| Design Variants Gate | UI/UX Designer Agent generates 2 real HTML/Tailwind design variants per platform (3-4 real pages each, derived from PRD/functional requirements), client previews on a branded Presentation Page and picks one before any execution spend | Real code (not images) gives OpenHands an actual implementation target (~90%+ accuracy) instead of a guess from a picture; letting the client choose upfront avoids wasted execution tokens and looks professional | Not built — see `NEXT_STEPS.md` Step 4b and `AGENTS.md` (UI/UX Designer) |
| Interactive Task List per project | Client sees a real, live-updating todo list for their project, backed by the existing `ai_tasks` table. Two candidate paths: (A) Open WebUI's native Task Management feature inside the chat itself, if it works through our custom Pipe; (B) a dedicated webhook page with real checkboxes, same pattern as the Design Variants Gate preview pages | Makes progress visible and tangible to the client instead of just a text summary; reuses data we already store | Not built — Path A unconfirmed (needs a live test), Path B is the guaranteed fallback and should be built regardless. See `NEXT_STEPS.md` Step 8b |
| Time Awareness for every agent | Every agent gets the real current time + the real timestamp of the user's last message, on every turn (not just session start), so none of them hallucinate elapsed time (claiming "last week" when it was minutes ago, or the reverse) | Models have no internal clock and guess elapsed time from conversational patterns by default; giving them a real number stops the hallucination | Not built — schema change (`created_at` on `n8n_chat_histories`) already added to the installer; node + system message updates pending. See `NEXT_STEPS.md` Step 1b and `AGENTS.md` -> Time Awareness Policy |
| Telegram Integration | Three uses for the single current owner/user: (a) push notifications (execution done, QA failed, cost threshold) so the owner doesn't have to keep checking manually; (b) a second, faster mobile entry point into باجوش alongside Open WebUI; (c) a "Get Project Tasks" tool with Telegram inline buttons to check/update project task status without opening any page | Directly solves the Async Execution waiting problem (Step 8) and gives a faster mobile experience than Open WebUI for the owner specifically | Not built — see `NEXT_STEPS.md` Step 14 |
| General Manager → Team Handoff (Project Brief Gate) | Structured output (`reply`/`ready_for_team`/`project_brief`) on باجوش so he presents a summary and gets explicit confirmation before handing a complete brief (covering the whole discussion, including his own suggestions) to PM Agent — instead of PM Agent only ever seeing the user's single latest message | Discovered live: PM Agent was missing earlier context and باجوش's own opinions from the discussion; loading full chat history was rejected for cost/noise reasons | Not built — see `NEXT_STEPS.md` Step 3b |
| Post-Delivery Archive & Cleanup | After a project is fully delivered, archive design/memory/QA/tasks data into the project's own repo, then (only after explicit manual confirmation) delete the local OpenHands workspace + the now-archived Postgres rows, to keep the VM from filling up | VM disk space is finite; client projects keep accumulating data otherwise | Not built — see `NEXT_STEPS.md` Step 11. Permanent Retention Rule: the `ai_projects` row (`id`/`project_slug`/`repo_url`) is never deleted, even during this cleanup |
| Domains via Nginx Proxy Manager | Each client-facing service (n8n, design previews, task list) gets its own subdomain via the existing Nginx Proxy Manager instead of bare IP:port links | Looks professional and is more secure (HTTPS) when sharing links with real clients | Infra-only, no n8n work needed — assign a subdomain per webhook as each one is built |
| Cost Dashboard | A page listing every project with its cost broken down per agent (employee) and per model used, backed by a new `ai_token_usage` table. OpenRouter returns cost in USD automatically in every response now (no second API call needed) | Lets projects be priced correctly instead of guessing, and flags which agents/models are the expensive ones | Not built — Path A (read usage straight from the AI Agent node's output) unconfirmed, needs a live test; Path B (HTTP call to OpenRouter's `/generation` endpoint, or per-project API keys) is the fallback. See `NEXT_STEPS.md` Step 13 |
| Custom name/icon per project chat | "Icon" in OpenWebUI is not a separate field — it's just an emoji prefixed to the chat `title` (e.g. `🛍️ متجر الأحذية`). OpenWebUI has a REST API (`POST /api/v1/chats/{chat_id}` with an API key) to rename a chat from outside, including emoji. Plan: once **PM Agent** (now built) decides the official project title, an HTTP Request node calls this API to rename the chat to `{emoji} {official project title}` — zero extra n8n nodes beyond that one HTTP call, and the name is the real decided project name, not a guess. Considered (and rejected) an approximate version using a lightweight OpenRouter call inside the Pipe itself to guess a title/emoji from the conversation before PM Agent exists — rejected because the team wants the chat name to be the *real* project name, not an approximation. | Would make it easier to visually tell projects apart in the sidebar, and reflects the actual agreed project name | Not built yet — add the rename HTTP call right after PM Agent decides the title |
| New Project path | Save Project → PM Agent → Product Analyst → Architect → Security Reviewer | Core flow for handling new software project requests | In progress — PM Agent, Product Analyst, Architect, and Security Reviewer all built and confirmed live individually (each producing correct, distinct output). Still missing: the Save Project Postgres insert at the start, the chat-rename step, and the final summary-back-to-client step after Security Reviewer. Blocked on Step 3b (Project Brief Gate) being built first so PM Agent gets a proper brief instead of just the latest message |
| GitHub Manager | Node/agent that manages reading/writing project repos | Needed before OpenHands execution can happen on real repos | Not built |
| OpenHands Executor integration | Wire n8n execution briefs into OpenHands | Actual code-writing step of the pipeline | Not built |
| QA / Revision loop | QA Agent checks output, Revision Agent creates correction brief on failure | Quality gate before delivery | Not built |
| Delivery Manager | Final agent that writes the user-facing response after QA passes | Last step before responding to the user | Not built |
| Memory Agent | Saves memory into PostgreSQL and/or GitHub doc files automatically | Reduces manual doc updates | Not built |

### ❌ Rejected / removed
| Feature | Reasoning |
|---|---|
| LiteLLM as model gateway | Removed from the final stack — n8n and OpenHands now call OpenRouter directly, which is simpler and removes an unnecessary layer. |
| n8n Code / Function / Python / JS nodes | Decided against using custom code nodes inside n8n — logic and routing should be handled by AI Agent nodes instead, to keep the workflow auditable and consistent. |
| Separate Research Agent + Switch branch for web search | Drafted in `workflows/ai-factory-v3.json` (`01C_Intent_Router` -> `02A_SearXNG_Search` -> `02B_Research_Agent`), but replaced by attaching SearXNG directly as a Tool on `00_AI_General_Manager`. Fewer nodes, less to keep in sync, and lets the model decide when search is actually needed instead of a fixed pipeline step. |

## Full planned AI employee roster

(see `AGENTS.md` for full detail per agent)

Project Classifier → Requirement Clarifier → PM Agent → Product Analyst → Research Agent → UI/UX Designer (if needed) → Frontend Planner (if needed) → Backend Planner (if needed) → Database Planner (if needed) → Security Reviewer → Software Architect → Execution Brief Builder → OpenHands Executor → QA Agent → Revision Agent → Delivery Agent → Memory Agent.

Only employees relevant to the project's needs should run — not all of them blindly.

## How to resume work in a new chat

Tell the assistant:

```text
This is the MKDD AI Factory project. Read PROJECT_MASTER_CONTEXT.md, CURRENT_STATUS.md,
NEXT_STEPS.md, DECISIONS_LOG.md, BUGS_AND_FIXES.md, and PROJECT_SUMMARY.md,
then continue from the latest step.
```
